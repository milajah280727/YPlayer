import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/screens/search/search_page_result.dart';
import 'package:yplayer/widgets/mini_player_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Muat riwayat pencarian saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).loadSearchHistory();
    });
  }

  void _searchSongs(String query) {
    if (query.isEmpty) return;
    // Navigasi ke halaman hasil pencarian
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPageResult(query: query),
      ),
    );
  }

  // Metode untuk menampilkan dialog konfirmasi hapus
  void _showDeleteDialog(String query) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text(
          'Hapus Riwayat',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$query" dari riwayat pencarian?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SearchProvider>(context, listen: false)
                  .removeFromSearchHistory(query);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child: Padding(
                  padding: EdgeInsets.only(bottom: padding.bottom + 70),
                  child: Consumer<SearchProvider>(
                    builder: (context, searchProvider, child) {
                      if (searchProvider.searchHistory.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsetsGeometry.only(top: 15, right: 15, left: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Pencarian Terakhir',
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                      ),
                                    ),
                                    // Tombol hapus semua riwayat
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: const Color(0xFF2E2E2E),
                                            title: const Text(
                                              'Hapus Semua Riwayat',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            content: const Text(
                                              'Apakah Anda yakin ingin menghapus semua riwayat pencarian?',
                                              style: TextStyle(color: Colors.white70),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Provider.of<SearchProvider>(context, listen: false)
                                                      .clearSearchHistory();
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Semua riwayat telah dihapus'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                },
                                                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Hapus Semua',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Padding(
                                padding:EdgeInsetsGeometry.only(right: 15, left: 15),
                                child: Wrap(
                                  
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: searchProvider.searchHistory.map((query) {
                                    // Gunakan GestureDetector untuk menambahkan fungsi tahan
                                    return GestureDetector(
                                      onLongPress: () => _showDeleteDialog(query),
                                      child: ActionChip(
                                        label: Text(
                                          query,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          _searchController.text = query;
                                          _searchSongs(query);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      // Jika tidak ada riwayat, tampilkan pesan atau widget kosong
                      return const Center(
                        child: Text(
                          'Cari lagu favorit Anda',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
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
        padding: EdgeInsets.only(top: padding.top, left: 8.0, right: 8.0),
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
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white), // Agar teks input berwarna putih
                    cursorColor: Colors.white, // Agar kursor berwarna putih
                    decoration: const InputDecoration(
                      hintText: 'Cari lagu...',
                      hintStyle: TextStyle(color: Colors.white70), // Agar hint teks terlihat
                      border: InputBorder.none, // Menghilangkan garis bawah default
                    ),
                    onSubmitted: (value) => _searchSongs(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => _searchSongs(_searchController.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}