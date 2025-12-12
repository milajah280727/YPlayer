// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';

class FavoritPageOnline extends StatefulWidget {
  const FavoritPageOnline({super.key});

  @override
  State<FavoritPageOnline> createState() => _FavoritPageOnlineState();
}

class _FavoritPageOnlineState extends State<FavoritPageOnline>
    with AutomaticKeepAliveClientMixin {
  
  Future<void> _downloadAudio(String videoId, String title) async {
    final hasPermission = await DownloadService.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const PermissionDialog(),
        );
      }
      return;
    }

    final sanitizedTitle = DownloadService.sanitizeFileName(title);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DownloadProgressDialog(
          title: 'Mengunduh Audio: $title',
          downloadFunction: (onProgress) => DownloadService.downloadAudio(
            videoId,
            sanitizedTitle,
            onProgress,
          ),
        ),
      ).then((filePath) {
        if (filePath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio berhasil diunduh: $sanitizedTitle.mp3'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunduh audio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> _downloadVideo(String videoId, String title) async {
    final hasPermission = await DownloadService.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const PermissionDialog(),
        );
      }
      return;
    }

    try {
      final formats = await YTDLService.getVideoResolutions(videoId);

      if (formats.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada format video yang tersedia'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => VideoQualityDialog(
            formats: formats,
            onQualitySelected: (formatId) {
              final sanitizedTitle = DownloadService.sanitizeFileName(title);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => DownloadProgressDialog(
                  title: 'Mengunduh Video: $title',
                  downloadFunction: (onProgress) => DownloadService.downloadVideo(
                    videoId,
                    sanitizedTitle,
                    // PERBAIKAN AKHIR: Gunakan 'formatId' langsung karena sudah bertipe String
                    formatId,
                    onProgress,
                  ),
                ),
              ).then((filePath) {
                if (filePath != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video berhasil diunduh: $sanitizedTitle.mp4'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal mengunduh video'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunduh video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDownloadOptions(String videoId, String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.audiotrack),
            title: const Text('Unduh Audio'),
            onTap: () {
              Navigator.pop(context);
              _downloadAudio(videoId, title);
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Unduh Video'),
            onTap: () {
              Navigator.pop(context);
              _downloadVideo(videoId, title);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final favoriteSongs = playerProvider.favorites;

        return Scaffold(
          body: favoriteSongs.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada lagu favorit',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final song = favoriteSongs[index];
                    return ListTile(
                      onTap: () {
                        playerProvider.playMusic(
                          videoId: song['id'],
                          title: song['title'],
                          channel: song['channel'],
                        );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          song['thumbnail'],
                          width: 90,
                          height: 70,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song['channel'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'play':
                              playerProvider.playMusic(
                                videoId: song['id'],
                                title: song['title'],
                                channel: song['channel'],
                              );
                              break;
                            case 'download':
                              _showDownloadOptions(song['id'], song['title']);
                              break;
                            case 'remove_favorite':
                              playerProvider.removeFromFavorites(song['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dihapus dari favorit'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'play',
                            child: Row(
                              children: [
                                Icon(Icons.play_circle),
                                SizedBox(width: 8),
                                Text('Putar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Unduh'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'remove_favorite',
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border, color: Colors.pink),
                                SizedBox(width: 8),
                                Text('Hapus dari Favorit'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}