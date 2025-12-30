import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yplayer/services/audio_player_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/services/ytdl_service.dart';
// Pastikan import ini sesuai dengan struktur folder Anda
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';

import 'dart:io';

// PERUBAHAN 1: RepeatMode hanya Off dan On
enum RepeatMode { off, on }

class PlayerProvider extends ChangeNotifier {
  // Audio Player (Utama)
  final AudioPlayer _audioPlayer = AudioPlayer();

  //audio handler
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
  
  // PERUBAHAN KRUSIAL: ValueNotifier untuk posisi agar tidak rebuild berat
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  
  RepeatMode _repeatMode = RepeatMode.off; // Default off
  bool _isShuffled = false; // State shuffle tetap ada untuk logika internal
  List<Map<String, dynamic>> _originalQueue = [];
  int _currentQueueIndex = 0;

  // ==================== STATE UNTUK FAVORIT DAN LAGU TERAKHIR DIPUTAR ====================
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _recentlyPlayed = [];
  // =====================================================================

  bool _isLoadingNewSong = false;
  final Map<String, String> _audioUrlCache = {};

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
  List<Map<String, dynamic>> get favorites => _favorites;
  List<Map<String, dynamic>> get recentlyPlayed => _recentlyPlayed;

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
      // PERBAIKAN: Update notifier, JANGAN notifyListeners()
      positionNotifier.value = position;
    });

    _audioPlayer.durationStream.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      // PERUBAHAN: Logika Repeat Audio (On/Off)
      if (state.processingState == ProcessingState.completed) {
        if (_repeatMode == RepeatMode.on) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        }
      }

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
        // PERBAIKAN: Update notifier tanpa rebuild UI penuh
        positionNotifier.value = _position;
        
        // Update durasi
        if (_duration == null || (_duration!.inSeconds < _position.inSeconds)) {
          _duration = _videoController!.value.duration;
          notifyListeners();
        }

        // Update status play/pause
        if (isControllerPlaying != _isPlaying) {
          _isPlaying = isControllerPlaying;
          notifyListeners();
        }

        // PERUBAHAN: Logika Repeat Video (On/Off)
        // Jika video selesai (posisi mencapai durasi) dan repeat ON, loop
        if (!isControllerPlaying && _isPlaying && _position >= _videoController!.value.duration) {
           if (_repeatMode == RepeatMode.on) {
             _videoController!.seekTo(Duration.zero);
             _videoController!.play();
           } else {
             // Jika repeat OFF, berhenti
             _isPlaying = false;
             notifyListeners();
           }
        }
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
    _position = position; 
    positionNotifier.value = position;
    notifyListeners();
  }

  // PERUBAHAN: Toggle Repeat (Hanya On/Off)
  void toggleRepeat() {
    _repeatMode = (_repeatMode == RepeatMode.off) ? RepeatMode.on : RepeatMode.off;
    
    // Sinkronisasi dengan handler
    audioHandler.toggleRepeat();
    
    notifyListeners();
  }

  void _playNextInQueue() {
    if (_relatedSongs.isEmpty) return;
    playSongFromQueue((_currentQueueIndex + 1) % _relatedSongs.length);
  }

  void _playPreviousInQueue() {
    if (_relatedSongs.isEmpty) return;
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

  // PERUBAHAN: Helper untuk dispose video hanya jika ID berbeda
  void _checkAndDisposeVideoControllers(String newVideoId) {
    // Jika ID video sekarang berbeda dengan yang akan diputar, dispose
    if (_currentVideoId != newVideoId) {
      _chewieController?.dispose();
      _videoController?.dispose();
      _chewieController = null;
      _videoController = null;
    }
  }

  // ==================== FUNGSI playMusic (STREAMING) ====================
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
    _isLocalPlayback = false; 
    _relatedSongs = [];
    notifyListeners();

    debugPrint(">>> PERMINTAAN LAGU BARU (STREAMING): $title");
    
    await _audioPlayer.stop();
    _position = Duration.zero;
    positionNotifier.value = Duration.zero;
    _duration = null;
    _isPlaying = false;

    // PERUBAHAN: Hanya dispose jika ID berbeda (Cache Check)
    _checkAndDisposeVideoControllers(videoId);
    
    _isPlayingVideo = false;
    _isPlayerVisible = true;

    _currentVideoId = videoId;
    _currentTitle = title;
    _currentChannel = channel;
    notifyListeners();

    try {
      debugPrint(">>> Fetching new stream for: $title");

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
      final dir = Directory('/storage/emulated/0/Download/Yplayer');

      if (!await dir.exists()) {
        debugPrint("Download directory not found.");
        _relatedSongs = [];
        notifyListeners();
        return;
      }

      final List<FileSystemEntity> entities = await dir.list().toList();
      final List<Map<String, dynamic>> localFiles = [];

      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path;
          if (path.endsWith('.mp3') || path.endsWith('.mp4')) {
            if (path != currentFilePath) {
              final fileName = path.split('/').last;
              final title = fileName.replaceAll(RegExp(r'\.(mp3|mp4)'), '');
              
              localFiles.add({
                'id': fileName,
                'title': title,
                'channel': 'Local File',
                'thumbnail': 'https://i.ytimg.com/vi/DOjeW4CUGeA/hqdefault.jpg',
                'path': path,
                'duration': Duration.zero,
              });
            }
          }
        }
      }

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

    _currentQueueIndex = index;
    final song = _relatedSongs[index];

    _isLoadingNewSong = true;
    notifyListeners();

    await _audioPlayer.stop();
    _position = Duration.zero;
    positionNotifier.value = Duration.zero;
    _duration = null;
    _isPlaying = false;

    // PERUBAHAN: Cek ID baru, dispose jika berbeda
    _checkAndDisposeVideoControllers(song['id']);

    if (_isPlayingVideo) {
      _isPlayingVideo = false;
      _videoController = null;
      _chewieController = null;
    }

    _isPlayerVisible = true;
    _currentVideoId = song['id'];
    _currentTitle = song['title'];
    _currentChannel = song['channel'];
    notifyListeners();

    try {
      debugPrint(">>> Playing from Queue Index $index: ${song['title']}");

      if (song.containsKey('path')) {
        debugPrint(">>> Playing Local File from Queue");
        _isLocalPlayback = true;
        await _audioPlayer.setFilePath(song['path']);
        await _audioPlayer.play();
        await _fetchLocalRelatedSongs(song['path']);
      } else {
        debugPrint(">>> Playing Streaming from Queue");
        _isLocalPlayback = false;
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
      }

      _isLoadingNewSong = false;
      notifyListeners();

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
  
  // Shuffle method tetap ada logicnya (meskipun tombol di UI diganti)
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

  // PERUBAHAN: Switch Video dengan Sinkronisasi Waktu dan Cache (SUDAH DIPERBAIKI)
  Future<void> switchToVideo() async {
    if (_isPlayingVideo || _currentVideoId == null) return;
    
    debugPrint("Switching to video. Syncing position...");
    final currentAudioPos = _audioPlayer.position;
    
    await _audioPlayer.pause();
    _isPlaying = false; 
    notifyListeners();

    try {
      bool needsInit = false;
      // Hanya cek null atau belum diinisialisasi.
      if (_videoController == null || !_videoController!.value.isInitialized) {
        needsInit = true;
      }

      if (needsInit) {
        final videoUrl = await YTDLService.getVideoStream(
          _currentVideoId!,
          '1080',
        );

        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoController!.initialize();
        
        _chewieController?.dispose();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false, 
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.pink,
            handleColor: Colors.pinkAccent,
          ),
          allowMuting: false,
          allowFullScreen: true,
          showControls: true, 
        );
      }

      _initVideoListener();

      // Sinkronisasi: Seek video ke posisi audio
      await _videoController!.seekTo(currentAudioPos);
      
      _isPlayingVideo = true;
      _isPlaying = true; // Pastikan status ON
      positionNotifier.value = currentAudioPos; 
      await _videoController!.play();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching to video: $e');
      _isPlayingVideo = false;
      notifyListeners();
      _audioPlayer.play();
    }
  }

  // PERUBAHAN: Switch Audio dengan Sinkronisasi Waktu
  Future<void> switchToAudio() async {
    if (!_isPlayingVideo) return;
    
    debugPrint("Switching back to audio. Syncing position...");
    final currentVideoPos = _videoController!.value.position;
    
    _isPlayingVideo = false;
    // JANGAN dispose video controller (Caching)
    await _videoController?.pause(); 
    
    notifyListeners();

    try {
      // Sinkronisasi: Seek audio ke posisi video
      await _audioPlayer.seek(currentVideoPos);
      
      _isPlaying = true; // <--- FIX: Update manual agar UI langsung berubah
      positionNotifier.value = currentVideoPos;
      
      await _audioPlayer.play();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching to audio: $e');
    }
  }

  // PERBAIKAN BUG PAUSE/PLAY
  void togglePlayPause() {
    if (_isPlayingVideo) {
      if (_videoController != null) {
        if (_videoController!.value.isPlaying) {
          _videoController?.pause();
          _isPlaying = false; // Update manual
        } else {
          _videoController?.play();
          _isPlaying = true; // Update manual
        }
        notifyListeners();
      }
    } else {
      // --- BUG FIX DI SINI ---
      if (_isPlaying) {
        _audioPlayer.pause();
        _isPlaying = false; // <--- TETAPKAN INI: Update manual state ke false
      } else {
        _audioPlayer.play();
        _isPlaying = true; // <--- TETAPKAN INI: Update manual state ke true
      }
      // Listener audio player akan sinkron, tapi update manual ini mencegah lag UI
      notifyListeners();
      // -------------------------
    }
  }

  void hidePlayer() {
    debugPrint("Hiding player.");
    _isPlayerVisible = false;
    _isPlayingVideo = false;
    _audioPlayer.pause();
    _videoController?.pause();
    // JANGAN dispose di sini
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

  // ==================== METODE DOWNLOAD AUDIO ====================
  Future<void> downloadCurrentAudio(BuildContext context) async {
    if (_currentVideoId == null) return;
    
    final hasPermission = await DownloadService.requestStoragePermission();
    if (!hasPermission) {
      showDialog(context: context, builder: (context) => const PermissionDialog());
      return;
    }

    final title = _currentTitle ?? 'Unknown Title';
    final sanitizedTitle = DownloadService.sanitizeFileName(title);

    DownloadProgressSnackBar.show(
      context,
      title: title,
      downloadFunction: (onProgress) => DownloadService.downloadAudio(
        _currentVideoId!,
        title,
        _currentChannel ?? 'Unknown Channel',
        'https://i.ytimg.com/vi/$_currentVideoId/hqdefault.jpg',
        onProgress,
      ),
      onComplete: (filePath) {
        if (filePath != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio berhasil diunduh: ${title}.mp3'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onError: (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengunduh audio: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  // ==================== METODE DOWNLOAD VIDEO ====================
  Future<void> downloadCurrentVideo(BuildContext context) async {
    if (_currentVideoId == null) return;

    final hasPermission = await DownloadService.requestStoragePermission();
    if (!hasPermission) {
      showDialog(context: context, builder: (context) => const PermissionDialog());
      return;
    }

    try {
      final resolutions = await YTDLService.getVideoResolutions(_currentVideoId!);

      if (resolutions.isEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada format video yang tersedia'), backgroundColor: Colors.red),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (dialogContext) => VideoQualityDialog(
          formats: resolutions,
          onQualitySelected: (formatId) {
            Navigator.pop(dialogContext);

            DownloadProgressSnackBar.show(
              context,
              title: 'Mengunduh Video: ${_currentTitle ?? ''}',
              downloadFunction: (onProgress) => DownloadService.downloadVideo(
                _currentVideoId!,
                _currentTitle ?? 'Unknown',
                _currentChannel ?? 'Unknown',
                'https://i.ytimg.com/vi/$_currentVideoId/hqdefault.jpg',
                formatId,
                onProgress,
              ),
              onComplete: (filePath) {
                if (filePath != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video berhasil diunduh: ${_currentTitle ?? ''}.mp4'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              onError: (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengunduh video: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat format video'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== METODE MEDIA LOKAL ====================
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
    positionNotifier.value = Duration.zero;
    _duration = null;
    _isPlaying = false;

    _checkAndDisposeVideoControllers(videoId);
    _isPlayingVideo = false;
    _isPlayerVisible = true;

    _currentVideoId = videoId;
    _currentTitle = title;
    _currentChannel = channel;
    notifyListeners();

    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();

      _isLoadingNewSong = false;
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
    positionNotifier.value = Duration.zero;
    _duration = null;
    _isPlaying = false;

    _checkAndDisposeVideoControllers(videoId);
    _isPlayingVideo = false;
    _isPlayerVisible = true;

    _currentVideoId = videoId;
    _currentTitle = title;
    _currentChannel = channel;
    notifyListeners();
    
    try {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();

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
          _duration ??= _videoController!.value.duration;
          _position = _videoController!.value.position;
          positionNotifier.value = _position; // Update tanpa rebuild
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
    positionNotifier.dispose();
    super.dispose();
  }
}