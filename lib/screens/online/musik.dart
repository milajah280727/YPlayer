// ignore_for_file: use_build_context_synchronously, duplicate_ignore, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';

class MusikPageOnline extends StatefulWidget {
  const MusikPageOnline({super.key});

  @override
  State<MusikPageOnline> createState() => _MusikPageOnlineState();
}

class _MusikPageOnlineState extends State<MusikPageOnline>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _trendingSongs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final String _searchQuery = 'Musik Viral Spotify 2025';
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isFetching = false; // Untuk mencegah fetch ganda

  @override
  void initState() {
    super.initState();
    _fetchTrendingSongs();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Trigger load more saat scroll mendekati akhir (100px dari akhir)
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore && _hasMore && !_isFetching) {
        _fetchTrendingSongs(loadMore: true);
      }
    }
  }

  Future<void> _fetchTrendingSongs({bool loadMore = false}) async {
    if (_isFetching) return; // Cegah fetch ganda
    
    _isFetching = true;

    if (loadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _trendingSongs = [];
        _hasMore = true;
      });
    }

    try {
      final results = await YTDLService.search(_searchQuery);

      if (loadMore) {
        // Tambahkan data baru ke list yang sudah ada
        final startIndex = _currentPage * _itemsPerPage;
        final newSongs = results.skip(startIndex).take(_itemsPerPage).toList();
        
        setState(() {
          _trendingSongs.addAll(newSongs);
          _currentPage++;
          _isLoadingMore = false;
          _isFetching = false;

          if (newSongs.isEmpty) {
            _hasMore = false;
          }
        });
      } else {
        // Load data pertama kali
        setState(() {
          _trendingSongs = results.take(_itemsPerPage).toList();
          _isLoading = false;
          _isFetching = false;
          _hasMore = results.length > _itemsPerPage;
        });
      }
    } catch (e) {
      debugPrint('Error fetching trending songs: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isFetching = false;
      });
    }
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

            // Tampilkan progress download video
            final sanitizedTitle = DownloadService.sanitizeFileName(title);
            DownloadProgressSnackBar.show(
              context,
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
  // ======================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Column(
        children: [
          // Header dengan informasi pencarian
          
          // Daftar lagu dengan infinite scroll
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchTrendingSongs(),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _trendingSongs.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Tampilkan indikator loading di akhir daftar
                        if (index == _trendingSongs.length && _hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final song = _trendingSongs[index];
                        return ListTile(
                          onTap: () {
                            final playerProvider =
                                Provider.of<PlayerProvider>(
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
          ),
          )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}