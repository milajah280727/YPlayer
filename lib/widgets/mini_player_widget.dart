// lib/widgets/mini_player_widget.dart

import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import '../providers/player_provider.dart';

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

  Widget _buildMiniPlayer(BuildContext context, PlayerProvider player) {
    return Container(
      color: const Color.fromARGB(255, 43, 41, 41),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: player.duration != null && player.duration!.inSeconds > 0
                ? player.position.inSeconds / player.duration!.inSeconds
                : 0.0,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      'https://i.ytimg.com/vi/${player.currentVideoId}/mqdefault.jpg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_video,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
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
                  if (!player.isPlayingVideo)
                    IconButton(
                      icon: const Icon(
                        Icons.video_library_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => player.switchToVideo(),
                      tooltip: 'Tampilkan Video',
                    ),
                  IconButton(
                    icon: Icon(
                      player.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: player.togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: player.skipToNext,
                  ),
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
              child: player.isPlayingVideo && player.chewieController != null
                  ? AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Chewie(controller: player.chewieController!),
                    )
                  : _buildAudioPlayerView(context, player),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    onPressed: () => player.miniController.animateToHeight(
                      state: PanelState.MIN,
                    ),
                  ),
                  const Text(
                    'Sedang Diputar',
                    style: TextStyle(color: Colors.grey),
                  ),
                  _buildMoreOptionsMenu(context, player),
                ],
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://i.ytimg.com/vi/${player.currentVideoId}/hqdefault.jpg',
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      player.currentTitle ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                    _buildPlaybackControls(player),
                    const SizedBox(height: 16),
                    _buildQueueStatus(player),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildRelatedSongsBar(player),
        ),
      ],
    );
  }

  Widget _buildMoreOptionsMenu(BuildContext context, PlayerProvider player) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (String value) {
        switch (value) {
          case 'add_to_favorites':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur favorit belum tersedia')),
            );
            break;
          case 'view_details':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur detail belum tersedia')),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'add_to_favorites',
          child: Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.pink),
              SizedBox(width: 8),
              Text('Tambah ke Favorit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'view_details',
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Lihat Detail'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBarWithTimestamp(BuildContext context, PlayerProvider player) {
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
            value: player.position.inSeconds.toDouble().clamp(
              0.0,
              player.duration?.inSeconds.toDouble() ?? 0.0,
            ),
            onChanged: (value) {
              player.audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(player.position),
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
  }

  Widget _buildPlaybackControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: player.isShuffled ? Colors.pink : Colors.grey,
          ),
          iconSize: 24,
          onPressed: player.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          iconSize: 40,
          onPressed: player.skipToPrevious,
        ),
        IconButton(
          icon: Icon(
            player.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: Colors.white,
          ),
          iconSize: 64,
          onPressed: player.togglePlayPause,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          iconSize: 40,
          onPressed: player.skipToNext,
        ),
        IconButton(
          icon: _buildRepeatIcon(player.repeatMode),
          iconSize: 24,
          onPressed: player.toggleRepeat,
        ),
      ],
    );
  }

  Widget _buildQueueStatus(PlayerProvider player) {
    final queueLength = player.relatedSongs.length;
    final repeatStatusText = player.repeatMode == RepeatMode.all
        ? 'Ulangi semua trek'
        : (player.repeatMode == RepeatMode.one ? 'Ulangi satu trek' : '');

    return Text(
      'Sedang dimainkan 1 / $queueLength [$repeatStatusText]',
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }

  Widget _buildRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return const Icon(Icons.repeat, color: Colors.grey);
      case RepeatMode.all:
        return const Icon(Icons.repeat, color: Colors.pink);
      case RepeatMode.one:
        return const Icon(Icons.repeat_one, color: Colors.pink);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildRelatedSongsBar(PlayerProvider player) {
    return Miniplayer(
      controller: player.relatedController,
      minHeight: 60,
      maxHeight: 500,
      builder: (height, percentage) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 43, 41, 41),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: percentage > 0.5
              ? _buildRelatedSongsList(player)
              : _buildRelatedSongsHeader(),
        );
      },
    );
  }

  Widget _buildRelatedSongsHeader() {
    return const ListTile(
      leading: Icon(Icons.queue_music, color: Colors.white),
      title: Text(
        'Lagu Terkait',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      trailing: Icon(Icons.keyboard_arrow_up, color: Colors.white),
    );
  }

  Widget _buildRelatedSongsList(PlayerProvider player) {
    if (player.relatedSongs.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada lagu terkait',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.queue_music, color: Colors.white),
          title: const Text(
            'Lagu Terkait',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: () =>
                player.relatedController.animateToHeight(state: PanelState.MIN),
          ),
        ),
        const Divider(height: 1, color: Colors.grey),
        Expanded(
          child: ListView.builder(
            itemCount: player.relatedSongs.length,
            itemBuilder: (context, index) {
              final song = player.relatedSongs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    song['thumbnail'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_video,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  song['title'],
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song['channel'],
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  player.playMusic(
                    videoId: song['id'],
                    title: song['title'],
                    channel: song['channel'],
                  );
                  player.relatedController.animateToHeight(
                    state: PanelState.MIN,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}