// ignore_for_file: use_build_context_synchronously, unused_local_variable, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';

class BerandaPageOnline extends StatefulWidget {
  const BerandaPageOnline({super.key});

  @override
  State<BerandaPageOnline> createState() => _BerandaPageOnlineState();
}

class _BerandaPageOnlineState extends State<BerandaPageOnline>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _trendingSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrendingSongs();
  }

  Future<void> _fetchTrendingSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await YTDLService.search('multo');
      setState(() {
        _trendingSongs = results.take(20).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching trending songs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      title: title,
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

  void _showDownloadOptions(
    String videoId,
    String title,
    String channel,
    String thumbnailUrl,
  ) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _trendingSongs.length,
            itemBuilder: (context, index) {
              final song = _trendingSongs[index];
              return ListTile(
                onTap: () {
                  final playerProvider = Provider.of<PlayerProvider>(
                    context,
                    listen: false,
                  );
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
                    if (value == 'play') {
                      final playerProvider = Provider.of<PlayerProvider>(
                        context,
                        listen: false,
                      );
                      playerProvider.playMusic(
                        videoId: song['id'],
                        title: song['title'],
                        channel: song['channel'],
                      );
                    } else if (value == 'download') {
                      _showDownloadOptions(
                        song['id'],
                        song['title'],
                        song['channel'],
                        song['thumbnail'],
                      );
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
                  ],
                ),
              );
            },
          );
  }

  @override
  bool get wantKeepAlive => true;
}
