// lib/services/audio_player_service.dart

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

// Pindahkan enum ke luar class agar bisa diakses dari mana saja
enum RepeatMode { off, one, all }

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  // State untuk kontrol tambahan
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffled = false;
  List<MediaItem> _originalQueue = []; // Simpan antrian asli untuk fungsi shuffle

  // Getters
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;

  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    // Listener untuk autoplay yang memeriksa mode repeat
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && _repeatMode != RepeatMode.off) {
        skipToNext();
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    queue.add([]);
    _originalQueue = [];
    super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (queue.value.isNotEmpty) {
      final currentIndex = queue.value.indexOf(mediaItem.value!);
      final nextIndex = (currentIndex + 1) % queue.value.length;
      await playMediaItem(queue.value[nextIndex]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (queue.value.isNotEmpty) {
      final currentIndex = queue.value.indexOf(mediaItem.value!);
      final prevIndex = (currentIndex - 1 + queue.value.length) % queue.value.length;
      await playMediaItem(queue.value[prevIndex]);
    }
  }

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
    // Perbarui notifikasi
    playbackState.add(playbackState.value.copyWith(
      repeatMode: const {
        RepeatMode.off: AudioServiceRepeatMode.none,
        RepeatMode.one: AudioServiceRepeatMode.one,
        RepeatMode.all: AudioServiceRepeatMode.all,
      }[_repeatMode]!,
    ));
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _originalQueue = List.from(queue.value); // Simpan antrian asli sebelum diacak
      final newQueue = List<MediaItem>.from(queue.value)..shuffle();
      queue.add(newQueue);
    } else {
      // Kembalikan ke antrian asli
      queue.add(_originalQueue);
    }
    // Perbarui notifikasi
    playbackState.add(playbackState.value.copyWith(
      shuffleMode: _isShuffled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    ));
  }

  // Fungsi untuk mengatur antrian dari luar
  void setQueue(List<MediaItem> newQueue) {
    _originalQueue = List.from(newQueue); // Simpan antrian asli
    queue.add(newQueue);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    try {
      debugPrint("Playing media item: ${mediaItem.title}");
      await _player.setUrl(mediaItem.id);
      this.mediaItem.add(mediaItem);
      await _player.play();
    } catch (e) {
      debugPrint("Error playing media item: $e");
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      repeatMode: const {
        RepeatMode.off: AudioServiceRepeatMode.none,
        RepeatMode.one: AudioServiceRepeatMode.one,
        RepeatMode.all: AudioServiceRepeatMode.all,
      }[_repeatMode]!,
      shuffleMode: _isShuffled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }
}