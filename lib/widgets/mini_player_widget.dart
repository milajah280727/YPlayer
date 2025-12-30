import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/player_provider.dart';
import 'dart:io';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        if (!playerProvider.isPlayerVisible) {
          return const SizedBox.shrink();
        }

        return Miniplayer(
          controller: playerProvider.miniController,
          minHeight: 80,
          maxHeight: MediaQuery.of(context).size.height,
          builder: (height, percentage) {
            if (percentage < 0.2) {
              return _buildMiniPlayer(context, playerProvider);
            }
            return _buildFullPlayer(context, playerProvider);
          },
        );
      },
    );
  }

  // PERBAIKAN: Widget Konfirmasi Download
  void _showDownloadConfirmationDialog({
    required BuildContext context,
    required PlayerProvider player,
    required String type, // 'Audio' atau 'Video'
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        
        title: Text(
          'Konfirmasi Download',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Apakah Anda yakin ingin mengunduh "${player.currentTitle ?? ''} ($type)"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm(); // Eksekusi fungsi download
            },
            child: const Text('Unduh', style: TextStyle(color: Color.fromARGB(255, 31, 255, 11))),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, PlayerProvider player) {
    return Container(
      color: const Color.fromARGB(255, 43, 41, 41),
      child: Column(
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: player.positionNotifier,
            builder: (context, position, child) {
              return LinearProgressIndicator(
                value: player.duration != null && player.duration!.inSeconds > 0
                    ? position.inSeconds / player.duration!.inSeconds
                    : 0.0,
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 70,
                      height: 50,
                      child: _buildVisualContent(player),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.currentTitle ?? 'Loading...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          player.currentChannel ?? '...',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  
                  // === GANTI TOMBOL DI BAGIAN KANAN MINI PLAYER ===
                  
                  // Tombol 1: Download Audio (Menggantikan "Switch to Video")
                  

                  // Tombol 2: Play/Pause
                  IconButton(
                    icon: Icon(
                      player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: player.isLoadingNewSong ? Colors.grey : Colors.white,
                      size: 28,
                    ),
                    onPressed: player.isLoadingNewSong ? null : player.togglePlayPause,
                  ),
                  
                  // =========================================================
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPlayer(BuildContext context, PlayerProvider player) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildAudioPlayerView(context, player),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerView(BuildContext context, PlayerProvider player) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    onPressed: () => player.miniController.animateToHeight(state: PanelState.MIN),
                  ),
                  const Text('Sedang Diputar', style: TextStyle(color: Colors.grey)),
                  // MENU OPSI DIHAPUS SESUAI PERMINTA
                  // _buildMoreOptionsMenu(context, player),
                ],
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: player.isPlayingVideo ? 400 : 250,
                        height: 250, 
                        child: _buildVisualContent(player),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      player.currentTitle ?? 'Loading...',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      player.currentChannel ?? '...',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressBarWithTimestamp(context, player),
                    const SizedBox(height: 16),
                    _buildPlaybackControls(context, player),
                    const SizedBox(height: 16),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualContent(PlayerProvider player) {
    if (player.isPlayingVideo &&
        player.videoController != null &&
        player.videoController!.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12), 
        child: Container(
          color: const Color.fromARGB(255, 236, 236, 236), 
          child: FittedBox(
            fit: BoxFit.contain, 
            child: SizedBox(
              width: player.videoController!.value.size.width,
              height: player.videoController!.value.size.height,
              child: VideoPlayer(player.videoController!),
            ),
          ),
        ),
      );
    }

    if (player.isLoadingNewSong) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4.0),
          ),
        ),
      );
    }

    return Image.network(
      'https://i.ytimg.com/vi/${player.currentVideoId}/hqdefault.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[800],
        child: const Icon(Icons.music_video, color: Colors.white70),
      ),
    );
  }

  Widget _buildProgressBarWithTimestamp(BuildContext context, PlayerProvider player) {
    return ValueListenableBuilder<Duration>(
      valueListenable: player.positionNotifier,
      builder: (context, position, child) {
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4.0,
                activeTrackColor: Colors.red,
                thumbColor: Colors.white,
              ),
              child: Slider(
                min: 0.0,
                max: player.duration?.inSeconds.toDouble() ?? 0.0,
                value: position.inSeconds.toDouble().clamp(
                  0.0,
                  player.duration?.inSeconds.toDouble() ?? 0.0,
                ),
                onChanged: (value) {
                  player.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(player.duration ?? Duration.zero),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

    Widget _buildPlaybackControls(BuildContext context, PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // SLOT 1: Switch Mode (Audio/Video)
        // HANYA MUNCUL JIKA MODE ONLINE
        if (!player.isLocalPlayback)
          if (player.isPlayingVideo)
            IconButton(
              icon: const Icon(Icons.headphones, color: Colors.white),
              iconSize: 24,
              onPressed: () => player.switchToAudio(),
            )
          else
            IconButton(
              icon: const Icon(Icons.video_library, color: Colors.white),
              iconSize: 24,
              onPressed: () => player.switchToVideo(),
            ),

        // SLOT 2: Download Music
        // HANYA MUNCUL JIKA MODE ONLINE
        if (!player.isLocalPlayback)
          IconButton(
            icon: const Icon(Icons.audiotrack, color: Colors.white),
            iconSize: 40,
            onPressed: () => _showDownloadConfirmationDialog(
                  context: context,
                  player: player,
                  type: 'Audio',
                  onConfirm: () => player.downloadCurrentAudio(context),
                ),
            tooltip: 'Download Music',
          ),

        // SLOT 3: Play/Pause
        // SELALU MUNCUL (BAIK ONLINE MAUPUN OFFLINE)
        IconButton(
          icon: Icon(
            player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: player.isLoadingNewSong ? Colors.grey : Colors.white,
          ),
          iconSize: 64,
          onPressed: player.isLoadingNewSong ? null : player.togglePlayPause,
        ),

        // SLOT 4: Download Video
        // HANYA MUNCUL JIKA MODE ONLINE
        if (!player.isLocalPlayback)
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            iconSize: 40,
            onPressed: () => _showDownloadConfirmationDialog(
                  context: context,
                  player: player,
                  type: 'Video',
                  onConfirm: () => player.downloadCurrentVideo(context),
                ),
            tooltip: 'Download Video',
          ),

        // SLOT 5: Add to Favorites
        // HANYA MUNCUL JIKA MODE ONLINE
        if (!player.isLocalPlayback)
          IconButton(
            icon: Icon(
              player.isFavorite(player.currentVideoId ?? '') ? Icons.favorite : Icons.favorite_border,
              color: player.isFavorite(player.currentVideoId ?? '') ? Colors.pink : Colors.grey,
            ),
            iconSize: 24,
            onPressed: () {
              if (player.currentVideoId != null) {
                final currentSong = {
                  'id': player.currentVideoId!,
                  'title': player.currentTitle ?? 'Unknown Title',
                  'channel': player.currentChannel ?? 'Unknown Channel',
                  'thumbnail': 'https://i.ytimg.com/vi/${player.currentVideoId}/hqdefault.jpg',
                };
                if (player.isFavorite(player.currentVideoId!)) {
                  player.removeFromFavorites(player.currentVideoId!);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dihapus dari Favorit')));
                } else {
                  player.addToFavorites(currentSong);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke Favorit'), backgroundColor: Colors.green));
                }
              }
            },
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}