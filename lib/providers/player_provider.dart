// lib/providers/player_provider.dart

import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../services/ytdl_service.dart';
import '../services/audio_player_service.dart';
import 'dart:io'; // Import untuk File

class PlayerProvider extends ChangeNotifier {
  // Audio Player (Utama)
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayerHandler? _audioHandler;

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
  bool _isAudioServiceReady = false;
  List<Map<String, dynamic>> _relatedSongs = [];

  final ValueNotifier<double> playerPercentageNotifier = ValueNotifier(0.0);

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  AudioPlayerHandler? get audioHandler => _audioHandler;
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  bool get isPlayerVisible => _isPlayerVisible;
  bool get isPlayingVideo => _isPlayingVideo;
  String? get currentVideoId => _currentVideoId;
  String? get currentTitle => _currentTitle;
  String? get currentChannel => _currentChannel;
  Duration? get duration => _duration;
  bool get isAudioServiceReady => _isAudioServiceReady;
  List<Map<String, dynamic>> get relatedSongs => _relatedSongs;

  // Getters untuk kontrol baru
  RepeatMode get repeatMode => _audioHandler?.repeatMode ?? RepeatMode.off;
  bool get isShuffled => _audioHandler?.isShuffled ?? false;

  PlayerProvider() {
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    if (_isAudioServiceReady && _audioHandler != null) {
      debugPrint("AudioService is already ready.");
      return;
    }
    debugPrint("Initializing AudioService...");
    try {
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
          androidNotificationChannelName: 'YMusic',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      _isAudioServiceReady = true;
      debugPrint("AudioService initialized successfully.");
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing AudioService: $e");
      _isAudioServiceReady = false;
      _audioHandler = null;
      notifyListeners();
    }
  }

  Future<void> playMusic({
    required String videoId,
    required String title,
    required String channel,
  }) async {
    if (_currentVideoId == videoId && _isPlayerVisible && !_isPlayingVideo) {
      miniController.animateToHeight(state: PanelState.MAX);
      return;
    }

    debugPrint("playMusic called. isAudioServiceReady: $_isAudioServiceReady");
    if (!_isAudioServiceReady || _audioHandler == null) {
      debugPrint('Cannot play music, AudioService is not ready.');
      return;
    }

    _disposeVideoControllers();
    _isPlayingVideo = false;
    _isPlayerVisible = true;
    
    _currentVideoId = videoId;
    _currentTitle = title;
    _currentChannel = channel;
    notifyListeners();

    try {
      final audioUrl = await YTDLService.getAudioStream(videoId);
      final videoInfoMap = await YTDLService.getInfoAsMap(videoId);
      
      final mediaItem = MediaItem(
        id: audioUrl,
        title: videoInfoMap['title'],
        artist: videoInfoMap['channel'],
        artUri: Uri.parse(videoInfoMap['thumbnailUrl']),
        duration: videoInfoMap['duration'],
      );

      await _audioHandler!.playMediaItem(mediaItem);
      _duration = videoInfoMap['duration'];
      
      await _fetchRelatedSongsAndSetQueue();

      await _saveToRecent();
    } catch (e) {
      debugPrint('Error loading music: $e');
      hidePlayer();
    }
  }

  // --- FUNGSI BARU UNTUK MEMUTAR FILE LOKAL ---
  Future<void> playLocalFile({
    required String filePath,
    required String fileName,
  }) async {
    debugPrint("Playing local file: $filePath");
    
    _disposeVideoControllers();
    _isPlayingVideo = false;
    _isPlayerVisible = true;
    
    // Cek apakah file video atau audio
    if (filePath.endsWith('.mp4')) {
      // Logika untuk video
      try {
        _videoController = VideoPlayerController.file(File(filePath));
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
        _currentTitle = fileName.replaceAll('_', ' ').replaceAll('.mp4', '');
        _currentChannel = "File Lokal";
        notifyListeners();
      } catch (e) {
        debugPrint('Error playing local video: $e');
      }
    } else {
      // Logika untuk audio
      if (!_isAudioServiceReady || _audioHandler == null) {
        debugPrint('Cannot play local music, AudioService is not ready.');
        return;
      }
      try {
        final mediaItem = MediaItem(
          id: filePath, // Gunakan path file lokal sebagai ID
          title: fileName.replaceAll('_', ' ').replaceAll('.mp3', ''),
          artist: "File Lokal",
        );

        _audioHandler!.setQueue([]); // Kosongkan antrian lama
        await _audioHandler!.playMediaItem(mediaItem);
        
        _currentTitle = mediaItem.title;
        _currentChannel = mediaItem.artist;
        notifyListeners();
      } catch (e) {
        debugPrint('Error playing local music: $e');
      }
    }
  }

  Future<void> _fetchRelatedSongsAndSetQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];

      List<Map<String, dynamic>> results;
      if (history.isEmpty) {
        debugPrint("No search history, using default query.");
        results = await YTDLService.search('trending music in indonesia');
      } else {
        final lastThreeSearches = history.take(3).toList();
        final recommendationQuery = lastThreeSearches.map((query) => '"$query"').join(' OR ');
        debugPrint("Fetching recommendations based on: $recommendationQuery");
        results = await YTDLService.search(recommendationQuery);
      }
      
      _relatedSongs = results.take(10).toList();
      
      final mediaItems = _relatedSongs.map((song) {
        return MediaItem(
          id: song['id'],
          title: song['title'],
          artist: song['channel'],
          artUri: Uri.parse(song['thumbnail']),
          duration: Duration(seconds: 0),
        );
      }).toList();
      
      _audioHandler?.setQueue(mediaItems);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching related songs: $e');
      _relatedSongs = [];
      notifyListeners();
    }
  }

  void skipToNext() => _audioHandler?.skipToNext();
  void skipToPrevious() => _audioHandler?.skipToPrevious();
  void toggleRepeat() {
    _audioHandler?.toggleRepeat();
    notifyListeners();
  }
  void toggleShuffle() {
    _audioHandler?.toggleShuffle();
    notifyListeners();
  }

  Future<void> switchToVideo() async {
    if (_isPlayingVideo || _currentVideoId == null) return;
    debugPrint("Switching to video. Stopping audio service.");
    await _audioHandler?.stop();
    _audioHandler = null;
    _isAudioServiceReady = false;
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
      debugPrint("Switched to video successfully.");
    } catch (e) {
      debugPrint('Error switching to video: $e');
      _isPlayingVideo = false;
      notifyListeners();
      _initAudioService();
    }
  }

  Future<void> switchToAudio() async {
    if (!_isPlayingVideo) return;
    debugPrint("Switching back to audio.");
    _isPlayingVideo = false;
    _disposeVideoControllers();
    await _initAudioService();
    if (_isAudioServiceReady && _audioHandler != null) {
      if (_currentVideoId != null) {
        playMusic(
          videoId: _currentVideoId!,
          title: _currentTitle ?? '',
          channel: _currentChannel ?? '',
        );
      }
    }
    notifyListeners();
    debugPrint("Switched back to audio.");
  }

  void togglePlayPause() {
    if (_isPlayingVideo) {
      _videoController!.value.isPlaying ? _videoController?.pause() : _videoController?.play();
    } else {
      final playbackState = _audioHandler?.playbackState.value;
      if (playbackState?.playing ?? false) {
        _audioHandler?.pause();
      } else {
        _audioHandler?.play();
      }
    }
    notifyListeners();
  }

  void hidePlayer() {
    debugPrint("Hiding player.");
    _isPlayerVisible = false;
    _isPlayingVideo = false;
    _audioHandler?.pause();
    _disposeVideoControllers();
    notifyListeners();
  }

  void stop() {
    debugPrint("Stopping player.");
    hidePlayer();
    _audioHandler?.stop();
  }

  void _disposeVideoControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  Future<void> _saveToRecent() async {
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
    playerPercentageNotifier.dispose();
    super.dispose();
  }
}