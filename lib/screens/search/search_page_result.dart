// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/screens/search/search_page.dart';
import 'package:yplayer/services/ytdl_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';
import 'package:yplayer/widgets/mini_player_widget.dart';

class SearchPageResult extends StatefulWidget {
  const SearchPageResult({super.key, required this.query});
  final String query;

  @override
  State<SearchPageResult> createState() => _SearchPageResultState();
}

class _SearchPageResultState extends State<SearchPageResult>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    // Lakukan pencarian saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).search(widget.query);
    });
  }

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
              // ignore: unnecessary_brace_in_string_interps
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
        builder: (dialogContext) => VideoQualityDialog(
          formats: resolutions,
          onQualitySelected: (formatId) {
            // Tutup dialog kualitas
            Navigator.pop(dialogContext);

            final sanitizedTitle = DownloadService.sanitizeFileName(title);
            DownloadProgressSnackBar.show(
              context, // Context halaman
              title: 'Mengunduh Video: $title',
              downloadFunction: (onProgress) => DownloadService.downloadVideo(
                videoId,
                sanitizedTitle,
                channel,
                thumbnailUrl,
                formatId,
                onProgress,
              ),
              onComplete: (filePath) {
                if (filePath != null && mounted) {
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
  // --- AKHIR FUNGSI DOWNLOAD ---

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.of(context).padding;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomAppBar(context, padding),
              Expanded(
                child: Consumer<SearchProvider>(
                  builder: (context, searchProvider, child) {
                    if (searchProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    if (searchProvider.videos.isEmpty) {
                      return const Center(child: Text('Tidak ada hasil ditemukan', style: TextStyle(color: Colors.white)));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(bottom: padding.bottom + 70), // Tambahkan padding untuk mini player
                      itemCount: searchProvider.videos.length,
                      itemBuilder: (context, index) {
                        final video = searchProvider.videos[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                video['thumbnail'],
                                width: 100,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.music_video, color: Colors.white70),
                                ),
                              ),
                            ),
                            title: Text(
                              video['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            // ==================== PERUBAHAN: SUBTITLE ====================
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  video['channel'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  video['durationText'] ?? 'Live',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            // ==========================================================
                            onTap: () {
                              // Mainkan musik saat video dipilih
                              Provider.of<PlayerProvider>(context, listen: false).playMusic(
                                videoId: video['id'],
                                title: video['title'],
                                channel: video['channel'],
                              );
                            },
                            // ==================== PERUBAHAN: MENU ====================
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                              color: const Color(0xFF1E1E1E),
                              onPressed: () => _showDownloadOptions(
                                    video['id'],
                                    video['title'],
                                    video['channel'],
                                    video['thumbnail'],
                              ),
                            ),
                            // ==========================================================
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Tambahkan MiniPlayerWidget di bagian bawah
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayerWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, EdgeInsets padding) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 50, left: 8.0, right: 8.0, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.query,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      )
      );
    }
  
  @override
  bool get wantKeepAlive => true;
}