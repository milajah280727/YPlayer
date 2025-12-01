// lib/widgets/mini_player_widget.dart

import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart'; // Import yang benar
import 'package:yplayer/screens/player/full_player_page.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        // Jika player tidak terlihat, jangan tampilkan apa-apa
        // PERBAIKAN: Gunakan operator '?' untuk akses yang mungkin null
        if (!playerProvider.isPlayerVisible) {
          return const SizedBox.shrink();
        }

        return Miniplayer(
          controller: playerProvider.miniController,
          minHeight: 70,
          maxHeight: MediaQuery.of(context).size.height,
          builder: (height, percentage) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FullPlayerPage(),
                  ),
                );
              },
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Progress Bar
                    ValueListenableBuilder(
                      valueListenable: playerProvider.playerPercentageNotifier,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: playerProvider.playerPercentageNotifier.value,
                          backgroundColor: Colors.pink.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                        );
                      },
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          // Thumbnail
                          Image.network(
                            'https://i.ytimg.com/vi/${playerProvider.currentVideoId}/hqdefault.jpg',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.music_note, color: Colors.grey);
                            },
                          ),
                          const SizedBox(width: 10),
                          // Info Lagu
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playerProvider.currentTitle ?? 'Tidak ada judul',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  playerProvider.currentChannel ?? 'Tidak ada channel',
                                  style: TextStyle(color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Tombol Play/Pause
                          IconButton(
                            icon: Icon(
                              playerProvider.isPlayingVideo
                                  ? (playerProvider.videoController?.value.isPlaying ?? false)
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled
                                  : (playerProvider.audioHandler?.playbackState.value.playing ?? false)
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                              color: Colors.pink,
                              size: 40,
                            ),
                            onPressed: () {
                              playerProvider.togglePlayPause();
                            },
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          onDismissed: () {
            playerProvider.hidePlayer();
          },
        );
      },
    );
  }
}