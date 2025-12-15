// ignore_for_file: deprecated_member_use

import 'dart:io'; // Tambahkan import ini
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/local_media_service.dart';

class BerandaPageOffline extends StatefulWidget {
  const BerandaPageOffline({super.key});

  @override
  State<BerandaPageOffline> createState() => _BerandaPageOfflineState();
}

class _BerandaPageOfflineState extends State<BerandaPageOffline> {
  List<Map<String, dynamic>> _downloadedMedia = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedMedia();
  }

  Future<void> _loadDownloadedMedia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final media = await LocalMediaService.getDownloadedMedia();
      if (mounted) {
        setState(() {
          _downloadedMedia = media;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading downloaded media: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playLocalMedia(Map<String, dynamic> media) async {
    try {
      final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
      
      if (media['type'] == 'audio') {
        await playerProvider.playLocalAudio(
          path: media['path'],
          title: media['title'],
          channel: media['channel'],
          videoId: media['id'],
        );
      } else {
        await playerProvider.playLocalVideo(
          path: media['path'],
          title: media['title'],
          channel: media['channel'],
          videoId: media['id'],
        );
      }
    } catch (e) {
      debugPrint('Error playing local media: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memutar media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget untuk menampilkan thumbnail dengan fallback
  Widget _buildThumbnail(Map<String, dynamic> media, {double width = 80, double height = 80}) {
    return FutureBuilder<String?>(
      future: LocalMediaService.getLocalThumbnailPath(media['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Tampilkan thumbnail lokal jika ada
          return ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(snapshot.data!),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(media, width, height),
            ),
          );
        } else {
          // Tampilkan thumbnail dari URL jika tidak ada lokal
          return ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              media['thumbnail'],
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackIcon(media, width, height),
            ),
          );
        }
      },
    );
  }

  // Widget untuk ikon fallback jika thumbnail gagal dimuat
  Widget _buildFallbackIcon(Map<String, dynamic> media, double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[700],
      child: Icon(
        media['type'] == 'audio' ? Icons.audiotrack : Icons.videocam,
        color: Colors.white70,
        size: width * 0.5, // Ukuran ikon proporsional
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _downloadedMedia.isEmpty
            ? const Center(
                child: Text(
                  "Belum ada media yang diunduh.\nUnduh lagu atau video dari mode Online!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDownloadedMedia,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  
                    // Bagian untuk semua media
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                      child: Text(
                        'Semua Media',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        itemCount: _downloadedMedia.length,
                        itemBuilder: (context, index) {
                          final media = _downloadedMedia[index];
                          return ListTile(
                            leading: _buildThumbnail(media, width: 60, height: 60),
                            title: Text(
                              media['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              media['channel'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              media['type'] == 'audio'
                                  ? Icons.audiotrack
                                  : Icons.videocam,
                              color: Colors.grey,
                            ),
                            onTap: () => _playLocalMedia(media),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
  }
}