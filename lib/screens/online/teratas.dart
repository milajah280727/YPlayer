// ignore_for_file: use_build_context_synchronously, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';

class TeratasPageOnline extends StatefulWidget {
  const TeratasPageOnline({super.key});

  @override
  State<TeratasPageOnline> createState() => _TeratasPageOnlineState();
}

class _TeratasPageOnlineState extends State<TeratasPageOnline>
    with AutomaticKeepAliveClientMixin {
  
  // ==================== METODE DOWNLOAD AUDIO (SAMA SEPERTI BERANDA) ====================
  Future<void> _downloadAudio(
    String videoId,
    String title,
    String channel,
    String thumbnailUrl,
  ) async {
    final hasPermission = await DownloadService.requestStoragePermission();
    if (!hasPermission) {
      showDialog(
        context: context,
        builder: (context) => const PermissionDialog(),
      );
      return;
    }

    final sanitizedTitle = DownloadService.sanitizeFileName(title);

    // Ganti showDialog dengan ini:
    DownloadProgressSnackBar.show(
      context,
      title: 'Mengunduh Audio: $title',
      downloadFunction: (onProgress) => DownloadService.downloadAudio(
        videoId,
        title,
        channel,
        thumbnailUrl,
        onProgress,
      ),
      onComplete: (filePath) {
        if (filePath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio berhasil diunduh: ${sanitizedTitle}.mp3'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
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
  // ======================================================================

  // ==================== METODE DOWNLOAD VIDEO (SAMA SEPERTI BERANDA) ====================
  Future<void> _downloadVideo(
    String videoId,
    String title,
    String channel,
    String thumbnailUrl,
  ) async {
    final hasPermission = await DownloadService.requestStoragePermission();
    if (!hasPermission) {
      showDialog(
        context: context,
        builder: (context) => const PermissionDialog(),
      );
      return;
    }

    try {
      final resolutions = await YTDLService.getVideoResolutions(videoId);

      if (resolutions.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada format video yang tersedia'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        // --- PERBAIKAN 1: Ubah nama parameter context menjadi dialogContext ---
        builder: (dialogContext) => VideoQualityDialog(
          formats: resolutions,
          onQualitySelected: (formatId) {
            // Tutup dialog kualitas menggunakan context dialog (dialogContext)
            

            // --- PERBAIKAN 2: Gunakan context halaman (this.context) untuk SnackBar ---
            DownloadProgressSnackBar.show(
              context, // Ini menggunakan context dari HalamanUtama, bukan dialog
              title: 'Mengunduh Video: $title',
              downloadFunction: (onProgress) => DownloadService.downloadVideo(
                videoId,
                title,
                channel,
                thumbnailUrl,
                formatId,
                onProgress,
              ),
              onComplete: (filePath) {
                if (filePath != null && mounted) {
                  final sanitizedTitle = DownloadService.sanitizeFileName(title);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video berhasil diunduh: ${sanitizedTitle}.mp4'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              onError: (error) {
                if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat format video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // ======================================================================

  // ==================== METODE SHOW DOWNLOAD OPTIONS ====================
  void _showDownloadOptions(
    String videoId,
    String title,
    String channel,
    String thumbnailUrl,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.audiotrack, color: Colors.pink),
            title: const Text('Unduh Audio', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _downloadAudio(videoId, title, channel, thumbnailUrl);
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.pink),
            title: const Text('Unduh Video', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _downloadVideo(videoId, title, channel, thumbnailUrl);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  // ======================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final topSongs = playerProvider.recentlyPlayed;

        return Scaffold(
          body: topSongs.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada lagu yang diputar',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: topSongs.length,
                  itemBuilder: (context, index) {
                    final song = topSongs[index];
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      // ==================== PERUBAHAN: SUBTITLE ====================
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song['channel'],
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song['durationText'] ?? 'Live',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      // ==========================================================
                      // ==================== PERUBAHAN: MENU ====================
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () => _showDownloadOptions(
                              song['id'],
                              song['title'],
                              song['channel'],
                              song['thumbnail'],
                            ),
                      ),
                      // ==========================================================
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