// lib/screens/player/full_player_page.dart

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:audio_service/audio_service.dart'; // Tambahkan import ini

class FullPlayerPage extends StatelessWidget {
  const FullPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        if (!playerProvider.isPlayerVisible) {
          return const Scaffold(
            body: Center(child: Text("Tidak ada media yang diputar")),
          );
        }

        return Scaffold(
          backgroundColor: Colors.pink.shade50,
          appBar: AppBar(
            backgroundColor: Colors.pink.shade50,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Sedang Diputar'),
            actions: [
              IconButton(
                icon: Icon(playerProvider.isPlayingVideo ? Icons.music_note : Icons.videocam),
                onPressed: () {
                  if (playerProvider.isPlayingVideo) {
                    playerProvider.switchToAudio();
                  } else {
                    playerProvider.switchToVideo();
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tampilkan Video Player atau Gambar Thumbnail
                if (playerProvider.isPlayingVideo && playerProvider.chewieController != null)
                  AspectRatio(
                    aspectRatio: playerProvider.videoController!.value.aspectRatio,
                    child: Chewie(
                      controller: playerProvider.chewieController!,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://i.ytimg.com/vi/${playerProvider.currentVideoId}/hqdefault.jpg',
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 40),
                // Judul dan Artis
                Text(
                  playerProvider.currentTitle ?? 'Tidak ada judul',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  playerProvider.currentChannel ?? 'Tidak ada channel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                // Slider Progress - PERBAIKAN STREAM
                StreamBuilder<PlaybackState>(
                  stream: playerProvider.audioHandler?.playbackState,
                  builder: (context, snapshot) {
                    final position = snapshot.data?.position ?? Duration.zero;
                    return StreamBuilder<MediaItem?>(
                      stream: playerProvider.audioHandler?.mediaItem,
                      builder: (context, snapshot) {
                        final duration = snapshot.data?.duration ?? Duration.zero;
                        return Slider(
                          activeColor: Colors.pink,
                          inactiveColor: Colors.pink.shade100,
                          min: 0.0,
                          max: duration.inSeconds.toDouble(),
                          value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                          onChanged: (value) {
                            playerProvider.audioHandler?.seek(Duration(seconds: value.toInt()));
                          },
                        );
                      },
                    );
                  },
                ),
                // Durasi - PERBAIKAN STREAM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: StreamBuilder<PlaybackState>(
                    stream: playerProvider.audioHandler?.playbackState,
                    builder: (context, snapshot) {
                      final position = snapshot.data?.position ?? Duration.zero;
                      return StreamBuilder<MediaItem?>(
                        stream: playerProvider.audioHandler?.mediaItem,
                        builder: (context, snapshot) {
                          final duration = snapshot.data?.duration ?? Duration.zero;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position)),
                              Text(_formatDuration(duration)),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                // Tombol Kontrol - PERBAIKAN STREAM
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 40),
                      onPressed: () {
                        playerProvider.skipToPrevious();
                      },
                    ),
                    IconButton(
                      icon: StreamBuilder<PlaybackState>(
                        stream: playerProvider.audioHandler?.playbackState,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;
                          return Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.pink,
                            size: 70,
                          );
                        },
                      ),
                      onPressed: () {
                        playerProvider.togglePlayPause();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 40),
                      onPressed: () {
                        playerProvider.skipToNext();
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi helper untuk format durasi
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}