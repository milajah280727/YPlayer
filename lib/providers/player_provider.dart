// lib/providers/player_provider.dart

import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import '../services/ytdl_service.dart';

class PlayerProvider extends ChangeNotifier {
  // Audio Player (Utama)
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Video Player (Sekunder)
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final MiniplayerController miniController = MiniplayerController();
  final MiniplayerController relatedController = MiniplayerController();

  // State
  bool _isPlayerVisible = false;
  bool _isPlayingVideo = false;
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

  // ==================== PERUBAHAN 1: TAMBAHKAN STATE LOADING ====================
  bool _isLoadingNewSong = false;
  // ==================== AKHIR PERUBAHAN 1 ====================

  // Map untuk menyimpan stream audio yang sudah di-preload
  final Map<String, String> _preloadedAudioStreams = {};

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  bool get isPlayerVisible => _isPlayerVisible;
  bool get isPlayingVideo => _isPlayingVideo;
  String? get currentVideoId => _currentVideoId;
  String? get currentTitle => _currentTitle;
  String? get currentChannel => _currentChannel;
  Duration? get duration => _duration;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;
  List<Map<String, dynamic>> get relatedSongs => _relatedSongs;
  
  // ==================== PERUBAHAN 2: TAMBAHKAN GETTER ====================
  bool get isLoadingNewSong => _isLoadingNewSong;
  // ==================== AKHIR PERUBAHAN 2 ====================

  PlayerProvider({required audioHandler}) {
    _initAudioPlayer();
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
      
      // ==================== PERUBAHAN 3: LISTENER UNTUK MENANGKAP KETIKA AUDIO BENAR-BENAR BERPUTAR ====================
      // Jika sedang loading dan audio sudah mulai diputar, hentikan status loading
      if (_isLoadingNewSong && state.playing) {
        debugPrint(">>> Audio telah berputar. Menghentikan status loading.");
        _isLoadingNewSong = false;
        notifyListeners();
      }
      // ==================== AKHIR PERUBAHAN 3 ====================
    });
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

    _currentQueueIndex = (_currentQueueIndex + 1) % _relatedSongs.length;
    final nextSong = _relatedSongs[_currentQueueIndex];

    playMusic(
      videoId: nextSong['id'],
      title: nextSong['title'],
      channel: nextSong['channel'],
    );
    _preloadNextSongs();
  }

  void _playPreviousInQueue() {
    if (_relatedSongs.isEmpty) return;

    _currentQueueIndex = (_currentQueueIndex - 1 + _relatedSongs.length) % _relatedSongs.length;
    final prevSong = _relatedSongs[_currentQueueIndex];

    playMusic(
      videoId: prevSong['id'],
      title: prevSong['title'],
      channel: prevSong['channel'],
    );
  }

  // ==================== PERUBAHAN 4: MODIFIKASI FUNGSI playMusic ====================
  Future<void> playMusic({
    required String videoId,
    required String title,
    required String channel,
  }) async {
    if (_currentVideoId == videoId && _isPlayerVisible && !_isPlayingVideo) {
      miniController.animateToHeight(state: PanelState.MAX);
      return;
    }

    // Set status loading menjadi true
    _isLoadingNewSong = true;
    notifyListeners(); // Langsung update UI ke loading

    debugPrint(">>> PERMINTAAN LAGU BARU: Melakukan reset total pemutar.");
    await _audioPlayer.stop();
    _preloadedAudioStreams.clear();
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
      final audioUrl = await YTDLService.getAudioStream(videoId);
      final videoInfoMap = await YTDLService.getInfoAsMap(videoId);
      
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play(); // Listener akan menangkap perubahan status 'playing'

      _duration = videoInfoMap['duration'];

      await _fetchRelatedSongsAndSetQueue(videoId);
      await _saveToRecent();
    } catch (e) {
      debugPrint('Error loading music: $e');
      // Jika terjadi error, hentikan status loading
      _isLoadingNewSong = false;
      notifyListeners();
      hidePlayer();
    }
  }
  // ==================== AKHIR PERUBAHAN 4 ====================

  Future<void> _fetchRelatedSongsAndSetQueue(String currentVideoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];

      List<Map<String, dynamic>> results;
      if (history.isEmpty) {
        results = await YTDLService.search('trending music in indonesia');
      } else {
        final lastThreeSearches = history.take(3).toList();
        final recommendationQuery = lastThreeSearches.map((query) => '"$query"').join(' OR ');
        results = await YTDLService.search(recommendationQuery);
      }

      _relatedSongs = results.take(10).toList();

      for (int i = 0; i < _relatedSongs.length; i++) {
        if (_relatedSongs[i]['id'] == currentVideoId) {
          _currentQueueIndex = i;
          break;
        }
      }

      notifyListeners();
      _preloadNextSongs();
    } catch (e) {
      debugPrint('Error fetching related songs: $e');
      _relatedSongs = [];
      notifyListeners();
    }
  }

  void _preloadNextSongs() {
    if (_relatedSongs.isEmpty) return;

    final nextIndex1 = (_currentQueueIndex + 1) % _relatedSongs.length;
    final nextIndex2 = (_currentQueueIndex + 2) % _relatedSongs.length;

    final nextVideoId1 = _relatedSongs[nextIndex1]['id'];
    final nextVideoId2 = _relatedSongs[nextIndex2]['id'];

    if (!_preloadedAudioStreams.containsKey(nextVideoId1)) {
      YTDLService.getAudioStream(nextVideoId1).then((url) {
        _preloadedAudioStreams[nextVideoId1] = url;
      });
    }

    if (!_preloadedAudioStreams.containsKey(nextVideoId2)) {
      YTDLService.getAudioStream(nextVideoId2).then((url) {
        _preloadedAudioStreams[nextVideoId2] = url;
      });
    }
  }

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
      _currentQueueIndex = _relatedSongs.indexWhere((song) => song['id'] == _currentVideoId);
      if (_currentQueueIndex == -1) _currentQueueIndex = 0;
    } else {
      _relatedSongs = List.from(_originalQueue);
      _currentQueueIndex = _originalQueue.indexWhere((song) => song['id'] == _currentVideoId);
      if (_currentQueueIndex == -1) _currentQueueIndex = 0;
    }
    notifyListeners();
    _preloadNextSongs();
  }

  Future<void> switchToVideo() async {
    if (_isPlayingVideo || _currentVideoId == null) return;
    debugPrint("Switching to video. Pausing audio player.");
    await _audioPlayer.pause();

    try {
      final videoUrl = await YTDLService.getVideoStream(_currentVideoId!);
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
        showControls: true,
      );
      _isPlayingVideo = true;
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
      _videoController!.value.isPlaying ? _videoController?.pause() : _videoController?.play();
    } else {
      if (_isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play();
      }
    }
    notifyListeners();
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

  Future<void> _saveToRecent() async {
    if (_currentVideoId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final item = [
      _currentVideoId,
      _currentTitle,
      _currentChannel,
      _duration?.toString().split('.').first ?? 'Live',
      'https://i.ytimg.com/vi/$_currentVideoId/hqdefault.jpg',
    ].join('|||');
    List<String> recent = prefs.getStringList('recent_played') ?? [];
    recent.removeWhere((e) => e.startsWith(_currentVideoId ?? ''));
    recent.add(item);
    if (recent.length > 50) recent.removeAt(0);
    await prefs.setStringList('recent_played', recent);
  }

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

// Tambahkan enum RepeatMode jika belum ada
enum RepeatMode { off, one, all }