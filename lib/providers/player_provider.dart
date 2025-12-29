import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yplayer/services/audio_player_service.dart';
import 'dart:io';
import '../services/ytdl_service.dart';

// PERBAIKAN: Pindahkan enum ke luar class agar bisa diakses dari mana saja
enum RepeatMode { off, one, all }

class PlayerProvider extends ChangeNotifier {
  // Audio Player (Utama)
  final AudioPlayer _audioPlayer = AudioPlayer();

  //audio handler
  // PERBAIKAN 1: Ubah nama variabel menjadi 'audioHandler' agar cocok dengan constructor
  final AudioPlayerHandler audioHandler;

  // Video Player (Sekunder)
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final MiniplayerController miniController = MiniplayerController();
  final MiniplayerController relatedController = MiniplayerController();

  // State
  bool _isPlayerVisible = false;
  bool _isPlayingVideo = false;
  bool _isLocalPlayback = false; // State Streaming vs Local
  
  String? _currentVideoId;
  String? _currentTitle;
  String? _currentChannel;
  Duration? _duration;
  List<Map<String, dynamic>> _relatedSongs = [];
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffled = false;
  List<Map<String, dynamic>> _originalQueue = [];
  int _currentQueueIndex = 0;

  // ==================== STATE UNTUK FAVORIT DAN LAGU TERAKHIR DIPUTAR ====================
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _recentlyPlayed = [];
  // ==================== AKHIR STATE ====================

  // State untuk loading
  bool _isLoadingNewSong = false;

  // ==================== PERUBAHAN: CACHE AUDIO ====================
  // Map untuk menyimpan URL yang sudah di-cache
  final Map<String, String> _audioUrlCache = {};
  // ==================== AKHIR CACHE AUDIO ====================

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  bool get isPlayerVisible => _isPlayerVisible;
  bool get isPlayingVideo => _isPlayingVideo;
  bool get isLocalPlayback => _isLocalPlayback;
  String? get currentVideoId => _currentVideoId;
  String? get currentTitle => _currentTitle;
  String? get currentChannel => _currentChannel;
  Duration? get duration => _duration;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;
  List<Map<String, dynamic>> get relatedSongs => _relatedSongs;
  bool get isLoadingNewSong => _isLoadingNewSong;

  // ==================== GETTER UNTUK FAVORIT DAN LAGU TERAKHIR DIPUTAR ====================
  List<Map<String, dynamic>> get favorites => _favorites;
  List<Map<String, dynamic>> get recentlyPlayed => _recentlyPlayed;
  // ==================== AKHIR GETTER ====================

  PlayerProvider({required this.audioHandler}) {
    _initAudioPlayer();
    _loadFavorites();
    _loadRecentlyPlayed();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.playing != _isPlaying) {
        _isPlaying = state.playing;
        notifyListeners();
      }
    });

    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }

      // Jika sedang loading dan audio sudah mulai diputar, hentikan status loading
      if (_isLoadingNewSong && state.playing) {
        debugPrint(">>> Audio telah berputar. Menghentikan status loading.");
        _isLoadingNewSong = false;
        notifyListeners();
      }
    });
  }

  void _initVideoListener() {
    _videoController?.addListener(() {
      if (_isPlayingVideo && _videoController != null) {
        final isControllerPlaying = _videoController!.value.isPlaying;
        
        // Update posisi
        _position = _videoController!.value.position;
        
        // Update durasi
        if (_duration == null || (_duration!.inSeconds < _position.inSeconds)) {
          _duration = _videoController!.value.duration;
        }

        // TAMBAHKAN INI: Update status play/pause agar UI ikut berubah
        if (isControllerPlaying != _isPlaying) {
          _isPlaying = isControllerPlaying;
        }
        
        notifyListeners();
      }
    });
  }

  // Fungsi Seek untuk Slider
  void seek(Duration position) {
    if (_isPlayingVideo) {
      _videoController?.seekTo(position);
    } else {
      _audioPlayer.seek(position);
    }
    _position = position; // Update UI langsung
    notifyListeners();
  }

  void _handleSongCompletion() {
    debugPrint("Song completed");
    switch (_repeatMode) {
      case RepeatMode.off:
        break;
      case RepeatMode.one:
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.play();
        break;
      case RepeatMode.all:
        _playNextInQueue();
        break;
    }
  }

  void _playNextInQueue() {
    if (_relatedSongs.isEmpty) return;
    // Panggil playSongFromQueue, karena dia sudah menangani Logic Streaming vs Local
    playSongFromQueue((_currentQueueIndex + 1) % _relatedSongs.length);
  }

  void _playPreviousInQueue() {
    if (_relatedSongs.isEmpty) return;
    // Panggil playSongFromQueue
    playSongFromQueue((_currentQueueIndex - 1 + _relatedSongs.length) % _relatedSongs.length);
  }

  // ==================== METODE UNTUK MANAJEMEN FAVORIT ====================
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList('favorites') ?? [];
      _favorites = favoritesJson.map((songJson) {
        final parts = songJson.split('|||');
        return {
          'id': parts[0],
          'title': parts[1],
          'channel': parts[2],
          'thumbnail': parts[3],
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = _favorites
          .map(
            (song) =>
                "${song['id']}|||${song['title']}|||${song['channel']}|||${song['thumbnail']}",
          )
          .toList();
      await prefs.setStringList('favorites', favoritesJson);
    } catch (e) {
      debugPrint("Error saving favorites: $e");
    }
  }

  void addToFavorites(Map<String, dynamic> song) {
    if (_favorites.any((favSong) => favSong['id'] == song['id'])) {
      debugPrint("Song is already in favorites.");
      return;
    }
    _favorites.insert(0, song);
    _saveFavorites();
    notifyListeners();
  }

  void removeFromFavorites(String videoId) {
    _favorites.removeWhere((song) => song['id'] == videoId);
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String videoId) {
    return _favorites.any((favSong) => favSong['id'] == videoId);
  }
  // ==================== AKHIR METODE FAVORIT ====================

  // ==================== METODE UNTUK MANAJEMEN LAGU TERAKHIR DIPUTAR ====================
  Future<void> _loadRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getStringList('recently_played') ?? [];
      _recentlyPlayed = recentJson.map((songJson) {
        final parts = songJson.split('|||');
        return {
          'id': parts[0],
          'title': parts[1],
          'channel': parts[2],
          'thumbnail': parts[3],
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading recently played: $e");
    }
  }

  Future<void> _saveRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = _recentlyPlayed
          .map(
            (song) =>
                "${song['id']}|||${song['title']}|||${song['channel']}|||${song['thumbnail']}",
          )
          .toList();
      await prefs.setStringList('recently_played', recentJson);
    } catch (e) {
      debugPrint("Error saving recently played: $e");
    }
  }

  void addToRecentlyPlayed(Map<String, dynamic> song) {
    _recentlyPlayed.removeWhere((s) => s['id'] == song['id']);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.take(20).toList();
    }
    _saveRecentlyPlayed();
    notifyListeners();
  }
  // ==================== AKHIR METODE LAGU TERAKHIR DIPUTAR ====================

  // ==================== PERUBAHAN: FUNGSI playMusic (STREAMING) ====================
  Future<void> playMusic({
    required String videoId,
    required String title,
    required String channel,
  }) async {
    if (_currentVideoId == videoId && _isPlayerVisible && !_isPlayingVideo) {
      miniController.animateToHeight(state: PanelState.MAX);
      return;
    }

    _isLoadingNewSong = true;
    _isLocalPlayback = false; // Tandai Streaming
    _relatedSongs = []; // Kosongkan related songs
    notifyListeners();

    debugPrint(">>> PERMINTAAN LAGU BARU (STREAMING): Melakukan reset total pemutar.");
    await _audioPlayer.stop();
    _position = Duration.zero;
    _duration = null;
    _isPlaying = false;

    _disposeVideoControllers();
    _isPlayingVideo = false;
    _isPlayerVisible = true;

    _currentVideoId = videoId;
    _currentTitle = title;
    _currentChannel = channel;
    notifyListeners();

    try {
      debugPrint(">>> Fetching new stream for: $title");

      // Cek cache terlebih dahulu
      String audioUrl;
      if (_audioUrlCache.containsKey(videoId)) {
        audioUrl = _audioUrlCache[videoId]!;
      } else {
        audioUrl = await YTDLService.getAudioStream(videoId);
        _audioUrlCache[videoId] = audioUrl;
      }

      final videoInfoMap = await YTDLService.getInfoAsMap(videoId);

      final cachingAudioSource = LockCachingAudioSource(Uri.parse(audioUrl));
      await _audioPlayer.setAudioSource(cachingAudioSource);
      await _audioPlayer.play();

      _duration = videoInfoMap['duration'];

      final currentSong = {
        'id': videoId,
        'title': title,
        'channel': channel,
        'thumbnail': 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      };
      addToRecentlyPlayed(currentSong);
    } catch (e) {
      debugPrint('Error loading music: $e');
      _isLoadingNewSong = false;
      notifyListeners();
      hidePlayer();
    }
  }
  // ==================== AKHIR FUNGSI playMusic ====================

  // ==================== METODE UNTUK SCAN FILE LOKAL (RELATED SONGS OFFLINE) ====================
  Future<void> _fetchLocalRelatedSongs(String currentFilePath) async {
    try {
      debugPrint(">>> Scanning local files for related songs...");

      // Tentukan folder download Anda
      final dir = Directory('/storage/emulated/0/Download/Yplayer');

      if (!await dir.exists()) {
        debugPrint("Download directory not found.");
        _relatedSongs = [];
        notifyListeners();
        return;
      }

      // PERBAIKAN ERROR STREAM -> LIST
      final List<FileSystemEntity> entities = await dir.list().toList();
      
      final List<Map<String, dynamic>> localFiles = [];

      // Filter hanya mp3 dan mp4
      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path;
          if (path.endsWith('.mp3') || path.endsWith('.mp4')) {
            // Jangan masukkan lagu yang sedang diputar
            if (path != currentFilePath) {
              final fileName = path.split('/').last;
              // Bersihkan nama dari ekstensi untuk judul
              final title = fileName.replaceAll(RegExp(r'\.(mp3|mp4)'), '');
              
              localFiles.add({
                'id': fileName, // Gunakan nama file sebagai ID unik sementara
                'title': title,
                'channel': 'Local File',
                'thumbnail': 'https://i.ytimg.com/vi/DOjeW4CUGeA/hqdefault.jpg', // Thumbnail default
                'path': path, // Simpan path fisik
                'duration': Duration.zero, // Durasi belum diketahui tanpa membaca file header
              });
            }
          }
        }
      }

      // Batasi jumlah list agar tidak berat (misal 20 lagu)
      _relatedSongs = localFiles.take(20).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error scanning local files: $e');
      _relatedSongs = [];
      notifyListeners();
    }
  }
  // ==================== AKHIR SCAN FILE LOKAL ====================

  // ==================== METODE UNTUK MAIN DARI QUEUE (PLAYLIST) ====================
  Future<void> playSongFromQueue(int index) async {
    if (index < 0 || index >= _relatedSongs.length) return;

    // Update index antrian
    _currentQueueIndex = index;
    final song = _relatedSongs[index];

    _isLoadingNewSong = true;
    notifyListeners();

    // Reset pemutar (jangan dispose video jika ganti cepat, tapi cukup stop)
    await _audioPlayer.stop();
    _position = Duration.zero;
    _duration = null;
    _isPlaying = false;

    // Jika sedang video, pindah ke audio otomatis
    if (_isPlayingVideo) {
      _isPlayingVideo = false;
      _disposeVideoControllers();
    }

    _isPlayerVisible = true;
    _currentVideoId = song['id'];
    _currentTitle = song['title'];
    _currentChannel = song['channel'];
    notifyListeners();

    try {
      debugPrint(">>> Playing from Queue Index $index: ${song['title']}");

      // --- LOGIKA: CARI STREAMING VS LOCAL ---
      if (song.containsKey('path')) {
        // --- LOGIKA PLAY LOKAL ---
        debugPrint(">>> Playing Local File from Queue");
        _isLocalPlayback = true;
        
        await _audioPlayer.setFilePath(song['path']);
        await _audioPlayer.play();

        // Refresh related songs
        await _fetchLocalRelatedSongs(song['path']);
      } else {
        // --- LOGIKA PLAY STREAMING ---
        debugPrint(">>> Playing Streaming from Queue");
        _isLocalPlayback = false;
        
        // Cek Cache Audio
        String audioUrl;
        if (_audioUrlCache.containsKey(song['id'])) {
          audioUrl = _audioUrlCache[song['id']]!;
        } else {
          audioUrl = await YTDLService.getAudioStream(song['id']);
          _audioUrlCache[song['id']] = audioUrl;
        }

        final cachingAudioSource = LockCachingAudioSource(Uri.parse(audioUrl));
        await _audioPlayer.setAudioSource(cachingAudioSource);
        await _audioPlayer.play();

        // Tidak perlu fetch related songs saat streaming, list tetap
      }
      // ------------------------------------------

      _isLoadingNewSong = false;
      notifyListeners();

      // Simpan ke Recently Played
      final currentSong = {
        'id': song['id'],
        'title': song['title'],
        'channel': song['channel'],
        'thumbnail': song['thumbnail'],
      };
      addToRecentlyPlayed(currentSong);
    } catch (e) {
      debugPrint('Error playing song from queue: $e');
      _isLoadingNewSong = false;
      notifyListeners();
      hidePlayer();
    }
  }
  // ==================== AKHIR METODE PLAYLIST ====================

  void skipToNext() => _playNextInQueue();
  void skipToPrevious() => _playPreviousInQueue();

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _originalQueue = List.from(_relatedSongs);
      _relatedSongs.shuffle();
      _currentQueueIndex = _relatedSongs.indexWhere(
        (song) => song['id'] == _currentVideoId,
      );
      if (_currentQueueIndex == -1) _currentQueueIndex = 0;
    } else {
      _relatedSongs = List.from(_originalQueue);
      _currentQueueIndex = _originalQueue.indexWhere(
        (song) => song['id'] == _currentVideoId,
      );
      if (_currentQueueIndex == -1) _currentQueueIndex = 0;
    }
    notifyListeners();
  }

  Future<void> switchToVideo() async {
    if (_isPlayingVideo || _currentVideoId == null) return;
    debugPrint("Switching to video. Pausing audio player.");
    await _audioPlayer.pause();

    try {
      final videoUrl = await YTDLService.getVideoStream(
        _currentVideoId!,
        '1080',
      );

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.pink,
          handleColor: Colors.pinkAccent,
        ),
        allowMuting: false,
        allowFullScreen: false,
        showControls: false,
      );

      _initVideoListener();

      _isPlayingVideo = true;
      _isPlaying = true; // Pastikan status play ON
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching to video: $e');
      _isPlayingVideo = false;
      notifyListeners();
      _audioPlayer.play();
    }
  }

  Future<void> switchToAudio() async {
    if (!_isPlayingVideo) return;
    debugPrint("Switching back to audio.");
    _isPlayingVideo = false;
    _disposeVideoControllers();
    await _audioPlayer.play();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlayingVideo) {
      if (_videoController != null) {
        if (_videoController!.value.isPlaying) {
          // Sedang berputar -> Pause
          _videoController?.pause();
          _isPlaying = false; // Update manual agar UI langsung berubah
        } else {
          // Sedang pause -> Play
          _videoController?.play();
          _isPlaying = true; // Update manual agar UI langsung berubah
        }
        notifyListeners(); // Wajib dipanggil agar rebuild widget segera
      }
    } else {
      // Logika untuk Audio (tetap sama)
      if (_isPlaying) {
        _audioPlayer.pause();
        // Jangan set false di sini, biarkan listener yang menghandle agar sinkron
      } else {
        _audioPlayer.play();
        // Jangan set true di sini
      }
      // Untuk audio biasanya tidak perlu notifyListeners manual karena listener cukup cepat
    }
  }

  void hidePlayer() {
    debugPrint("Hiding player.");
    _isPlayerVisible = false;
    _isPlayingVideo = false;
    _audioPlayer.pause();
    _disposeVideoControllers();
    notifyListeners();
  }

  void stop() {
    debugPrint("Stopping player.");
    hidePlayer();
    _audioPlayer.stop();
  }

  void _disposeVideoControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  // ==================== METODE UNTUK MEMUTAR MEDIA LOKAL ====================
  /// Memutar file audio dari penyimpanan lokal.
  Future<void> playLocalAudio({
    required String path,
    required String title,
    required String channel,
    required String videoId,
  }) async {
    if (_isPlayingVideo) {
      await switchToAudio();
    }

    _isLoadingNewSong = true;
    _isLocalPlayback = true;
    notifyListeners();

    debugPrint(">>> MEMUTAR AUDIO LOKAL: $title");

    await _audioPlayer.stop();
    _position = Duration.zero;
    _duration = null;
    _isPlaying = false;

    _isPlayerVisible = true;
    _currentVideoId = videoId;
    _currentTitle = title;
    _currentChannel = channel;
    notifyListeners();

    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();

      _isLoadingNewSong = false;
      
      // PANGGIL SCAN FILE UNTUK MENGISI RELATED SONGS
      await _fetchLocalRelatedSongs(path);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local audio: $e');
      _isLoadingNewSong = false;
      notifyListeners();
      hidePlayer();
    }
  }

  /// Memutar file video dari penyimpanan lokal.
  Future<void> playLocalVideo({
    required String path,
    required String title,
    required String channel,
    required String videoId,
  }) async {
    _isLoadingNewSong = true;
    _isLocalPlayback = true;
    notifyListeners();

    debugPrint(">>> MEMUTAR VIDEO LOKAL: $title");

    await _audioPlayer.stop();
    _position = Duration.zero;
    _duration = null;
    _isPlaying = false;

    _disposeVideoControllers();
    _isPlayingVideo = false;
    _isPlayerVisible = true;

    _currentVideoId = videoId;
    _currentTitle = title;
    _currentChannel = channel;
    notifyListeners();

    try {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();

      // PERBAIKAN WARNING: Ganti if null dengan ??=
      _duration ??= _videoController!.value.duration;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.pink,
          handleColor: Colors.pinkAccent,
        ),
        allowMuting: false,
        allowFullScreen: true,
        showControls: false,
      );

      _videoController!.addListener(() {
        if (_isPlayingVideo) {
          // PERBAIKAN WARNING: Ganti if null dengan ??=
          _duration ??= _videoController!.value.duration;
          _position = _videoController!.value.position;
          notifyListeners();
        }
      });

      _isPlayingVideo = true;
      _isLoadingNewSong = false;
      
      await _fetchLocalRelatedSongs(path);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local video: $e');
      _isLoadingNewSong = false;
      notifyListeners();
      hidePlayer();
    }
  }
  // ==================== AKHIR METODE MEDIA LOKAL ====================

  @override
  void dispose() {
    debugPrint("Disposing PlayerProvider.");
    stop();
    _audioPlayer.dispose();
    _disposeVideoControllers();
    miniController.dispose();
    relatedController.dispose();
    super.dispose();
  }
}