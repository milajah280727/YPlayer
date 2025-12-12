// lib/screens/search/search_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/screens/search/search_page_result.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // PERUBAHAN: TextField dipindahkan ke sini
        title: TextField(
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
        foregroundColor: Colors.white,
        backgroundColor: Colors.pink,
      ),
      // PERUBAHAN: Body sekarang hanya berisi riwayat pencarian
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchHistory.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pencarian Terakhir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: searchProvider.searchHistory.map((query) {
                      return ActionChip(
                        label: Text(query),
                        onPressed: () {
                          _searchController.text = query;
                          _searchSongs(query);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }
          // Jika tidak ada riwayat, tampilkan pesan atau widget kosong
          return const Center(
            child: Text(
              'Cari lagu favorit Anda',
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}