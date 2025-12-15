// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';

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

  // --- FUNGSI UNDUHAN (SAMA SEPERTI HALAMAN LAIN) ---
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
              content: Text('Audio berhasil diunduh: ${title}.mp3'),
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
        builder: (context) => VideoQualityDialog(
          formats: resolutions,
          onQualitySelected: (formatId) {
            final sanitizedTitle = DownloadService.sanitizeFileName(title);

            DownloadService.downloadAudio;
          },
        ),
      );
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

  void _showDownloadOptions(String videoId, String title, String channel, String thumbnailUrl) {
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
              _downloadAudio(videoId, title, channel, thumbnailUrl);
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Unduh Video'),
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
  // --- AKHIR FUNGSI UNDUHAN ---

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.query),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (searchProvider.videos.isEmpty) {
            return const Center(child: Text('Tidak ada hasil ditemukan'));
          }

          return ListView.builder(
            itemCount: searchProvider.videos.length,
            itemBuilder: (context, index) {
              final video = searchProvider.videos[index]; // Asumsikan ini adalah Map
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    video['thumbnail'], // Asumsikan ini adalah Map
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
                  video['title'], // Asumsikan ini adalah Map
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  video['channel'], // Asumsikan ini adalah Map
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // Mainkan musik saat video dipilih
                  Provider.of<PlayerProvider>(context, listen: false).playMusic(
                    videoId: video['id'], // Asumsikan ini adalah Map
                    title: video['title'], // Asumsikan ini adalah Map
                    channel: video['channel'], // Asumsikan ini adalah Map
                  );
                },
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'play') {
                      Provider.of<PlayerProvider>(context, listen: false).playMusic(
                        videoId: video['id'], // Asumsikan ini adalah Map
                        title: video['title'], // Asumsikan ini adalah Map
                        channel: video['channel'], // Asumsikan ini adalah Map
                      );
                    } else if (value == 'download') {
                      _showDownloadOptions(video['id'], video['title'], video['channel'], video['thumbnail']); // Asumsikan ini adalah Map
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: Row(children: [
                        Icon(Icons.play_circle),
                        SizedBox(width: 8),
                        Text('Putar')
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Unduh')
                      ]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}