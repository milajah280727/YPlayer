// ignore_for_file: use_build_context_synchronously, unused_local_variable, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/video_quality_dialog.dart';
import 'package:yplayer/widgets/download_progress_dialog.dart';
import 'package:yplayer/widgets/permission_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BerandaPageOnline extends StatefulWidget {
  const BerandaPageOnline({super.key});

  @override
  State<BerandaPageOnline> createState() => _BerandaPageOnlineState();
}

class _BerandaPageOnlineState extends State<BerandaPageOnline>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _trendingSongs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _currentSearchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isFetching = false;
  List<String> _searchQueries = []; // List untuk menyimpan berbagai query

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore && _hasMore && !_isFetching) {
        _fetchTrendingSongs(loadMore: true);
      }
    }
  }

  Future<void> _fetchTrendingSongs({bool loadMore = false}) async {
    if (_isFetching) return;

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
        _searchQueries = []; // Reset query list
      });
    }

    try {
      // Generate berbagai query untuk mendapatkan lebih banyak hasil
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];

      if (loadMore) {
        // Gunakan query berbeda untuk setiap halaman
        String searchQuery;

        if (_searchQueries.isEmpty) {
          // Buat query baru berdasarkan riwayat
          if (history.isNotEmpty) {
            _searchQueries = [
              'trending music indonesia',
              'lagu viral 2025',
              'music pop indonesia',
              'lagu terbaru',
              'indonesian music hits',
              'top songs indonesia',
              'music trending',
              'best indonesian songs',
              'popular music indonesia',
              'indonesian pop songs',
            ];
          } else {
            // Gunakan query dari riwayat
            _searchQueries = history.take(10).toList();
          }
        }

        // Ambil query berikutnya dari list
        final queryIndex = (_currentPage - 1) % _searchQueries.length;
        searchQuery = _searchQueries[queryIndex];

        debugPrint('Fetching page $_currentPage with query: $searchQuery');
        final results = await YTDLService.search(searchQuery);

        // Filter lagu yang sudah ada di list
        final existingIds = _trendingSongs.map((song) => song['id']).toSet();
        final newSongs = results
            .where((song) => !existingIds.contains(song['id']))
            .take(_itemsPerPage)
            .toList();

        setState(() {
          _trendingSongs.addAll(newSongs);
          _currentPage++;
          _isLoadingMore = false;
          _isFetching = false;

          // Jika tidak dapat lagu baru, coba query lain
          if (newSongs.isEmpty) {
            _hasMore = _currentPage < 50; // Batasi maksimal 50 halaman
          }
        });
      } else {
        // Load pertama kali
        List<Map<String, dynamic>> results;

        if (history.isEmpty) {
          _currentSearchQuery = 'trending music in indonesia';
          results = await YTDLService.search(_currentSearchQuery);
        } else {
          final lastFiveSearches = history.take(5).toList();
          _currentSearchQuery = lastFiveSearches
              .map((query) => '"$query"')
              .join(' OR ');
          results = await YTDLService.search(_currentSearchQuery);
        }

        setState(() {
          _trendingSongs = results.take(_itemsPerPage).toList();
          _currentPage = 1;
          _isLoading = false;
          _isFetching = false;

          // Periksa apakah masih ada data
          if (results.length <= _itemsPerPage) {
            _hasMore = true; // Masih mungkin ada data dengan query lain
          }
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

  // ... (Kode _downloadAudio, _downloadVideo, dan _showDownloadOptions tetap sama)
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video berhasil diunduh: ${title}.mp4'),
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

    return Scaffold(
      body: Column(
        children: [
          // Header dengan informasi pencarian
          if (_currentSearchQuery.isNotEmpty)
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
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
