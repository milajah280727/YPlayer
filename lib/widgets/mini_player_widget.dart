import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/player_provider.dart';
import 'dart:io'; // <--- Tambahkan ini

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
                    // Ukuran Mini Player 50x50
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
                  // Tombol Switch ke Video
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
                  // Tombol Play/Pause
                  IconButton(
                    icon: Icon(
                      player.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: player.isLoadingNewSong ? Colors.grey : Colors.white,
                      size: 28,
                    ),
                    onPressed: player.isLoadingNewSong
                        ? null
                        : player.togglePlayPause,
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
                      child: SizedBox(
                        // PERUBAHAN: Jika Video lebar 400, jika Audio kotak 250
                        width: player.isPlayingVideo ? 400 : 250,
                        height: 250, 
                        child: _buildVisualContent(player),
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

  // --- WIDGET VISUAL KONTEN ---
  Widget _buildVisualContent(PlayerProvider player) {
    // Kondisi 1: Mode Video Aktif dan Siap
    if (player.isPlayingVideo &&
        player.videoController != null &&
        player.videoController!.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12), // Border Radius
        child: Container(
          color: const Color.fromARGB(255, 236, 236, 236), // Background hitam
          child: FittedBox(
            fit: BoxFit.contain, // Contain agar tidak dicrop, ukuran asli
            child: SizedBox(
              width: player.videoController!.value.size.width,
              height: player.videoController!.value.size.height,
              child: VideoPlayer(player.videoController!),
            ),
          ),
        ),
      );
    }

    // Kondisi 2: Loading
    if (player.isLoadingNewSong) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 4.0,
            ),
          ),
        ),
      );
    }

    // Kondisi 3: Audio (Thumbnail)
    return Image.network(
      'https://i.ytimg.com/vi/${player.currentVideoId}/hqdefault.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[800],
        child: const Icon(
          Icons.music_video,
          color: Colors.white70,
        ),
      ),
    );
  }

    Widget _buildMoreOptionsMenu(BuildContext context, PlayerProvider player) {
    final currentSongId = player.currentVideoId ?? '';
    final isCurrentFavorite = player.isFavorite(currentSongId);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (String value) {
        switch (value) {
          case 'add_to_favorites':
            if (currentSongId.isNotEmpty) {
              final currentSong = {
                'id': currentSongId,
                'title': player.currentTitle ?? 'Unknown Title',
                'channel': player.currentChannel ?? 'Unknown Channel',
                'thumbnail': 'https://i.ytimg.com/vi/$currentSongId/hqdefault.jpg',
              };
              player.addToFavorites(currentSong);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ditambahkan ke Favorit'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            break;
          // --- BARU: Logika Switch Mode ---
          case 'switch_stream_mode':
            if (player.isPlayingVideo) {
              // Jika sedang Video -> Pindah ke Audio
              player.switchToAudio();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mode Audio Aktif'),
                  backgroundColor: Colors.blueGrey,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              // Jika sedang Audio -> Pindah ke Video
              player.switchToVideo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mode Video Aktif'),
                  backgroundColor: Colors.pink,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            break;
          // ---------------------------------
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'add_to_favorites',
          child: Row(
            children: [
              Icon(isCurrentFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.pink),
              const SizedBox(width: 8),
              Text(isCurrentFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit'),
            ],
          ),
        ),
        // --- MENU BARU ---
        PopupMenuItem<String>(
          value: 'switch_stream_mode',
          child: Row(
            children: [
              // Ikon Dinamis: Jika video aktif, tampilkan icon audio (headphone).
              // Jika audio aktif, tampilkan icon video (video_library).
              Icon(
                player.isPlayingVideo ? Icons.headphones : Icons.video_library,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              // Teks Dinamis: "Tampilkan Video" atau "Tampilkan Audio"
              Text(player.isPlayingVideo ? 'Tampilkan Audio' : 'Tampilkan Video'),
            ],
          ),
        ),
        // -----------------
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
              // PANGGIL FUNGSI SEEK AGAR SLIDER BISA DIGUNAKAN
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
            color: player.isLoadingNewSong ? Colors.grey : Colors.white,
          ),
          iconSize: 64,
          onPressed: player.isLoadingNewSong
              ? null
              : player.togglePlayPause,
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
    // JIKA MODE STREAMING, Sembunyikan bar sepenuhnya
    if (!player.isLocalPlayback) {
      return const SizedBox.shrink();
    }

    // JIKA MODE LOCAL, tampilkan bar seperti biasa
    return Miniplayer(
      controller: player.relatedController,
      minHeight: 60,
      maxHeight: 500,
      builder: (height, percentage) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 43, 41, 41),
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
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Fixed typo
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
              final songId = song['id'];
              
              // --- LOGIKA: CEK APAKAH LAGU INI SEDANG DIPUTAR ---
              final bool isActive = (songId == player.currentVideoId);

              // --- LOGIKA: CEK STATUS DOWNLOAD ---
              // Kita cek sinkronus file di direktori. Hati-hati, ini bisa berat jika list panjang,
              // tapi untuk 10-20 item masih aman.
              bool isDownloaded = false;
              try {
                // Sesuaikan dengan path penyimpanan Anda
                final dir = Directory('/storage/emulated/0/Download/Yplayer');
                if (dir.existsSync()) {
                  // Sanitasi nama file sesuai logika DownloadService
                  final sanTitle = song['title'].toString().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
                  final mp3Path = '${dir.path}/$sanTitle.mp3';
                  final mp4Path = '${dir.path}/$sanTitle.mp4';
                  isDownloaded = File(mp3Path).existsSync() || File(mp4Path).existsSync();
                }
              } catch (e) {
                // Abaikan error file sistem
              }
              // ------------------------------------------

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                leading: Stack(
                  children: [
                    // Thumbnail / Icon
                    ClipRRect(
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
                    // --- TANDA AKTIF (LINGKARAN PINK/PLAY ICON) ---
                    if (isActive)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomRight: Radius.circular(8))
                          ),
                          padding: const EdgeInsets.all(2.0),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  song['title'],
                  style: TextStyle(
                    color: isActive ? Colors.pink : Colors.white, // Judul berubah jadi pink jika aktif
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        song['channel'],
                        style: TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // --- TANDA DOWNLOAD (ICON CLOUD) ---
                    if (isDownloaded)
                      const Icon(
                        Icons.cloud_done, 
                        color: Colors.green, 
                        size: 16,
                      ),
                  ],
                ),
                onTap: () {
                  // Panggil fungsi playSongFromQueue baru
                  player.playSongFromQueue(index);
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