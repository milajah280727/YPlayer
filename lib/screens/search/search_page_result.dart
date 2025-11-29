import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/screens/search/search_page.dart'; // IMPORT SearchPage

class SearchPageResult extends StatefulWidget {
  final String query;

  const SearchPageResult({super.key, required this.query});

  @override
  State<SearchPageResult> createState() => _SearchPageResultState();
}

class _SearchPageResultState extends State<SearchPageResult> {
  @override
  void initState() {
    super.initState();
    // Jalankan pencarian saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).search(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Bungkus Text dengan GestureDetector untuk membuatnya dapat diklik
        title: GestureDetector(
          onTap: () {
            // Navigasi kembali ke SearchPage dan bawa query saat ini
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SearchPage(initialQuery: widget.query),
              ),
            );
          },
          child: Text(widget.query),
        ),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          // Tampilkan loading hanya saat pencarian pertama kali untuk query ini
          if (searchProvider.isLoading && searchProvider.videos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            );
          }

          // Jika pencarian selesai dan tidak ada hasil
          if (!searchProvider.isLoading && searchProvider.videos.isEmpty) {
            return Center(
              child: Text("Tidak ada hasil ditemukan untuk '${searchProvider.currentSearchQuery}'"),
            );
          }

          // Tampilkan daftar video jika ada hasil
          return ListView.builder(
            itemCount: searchProvider.videos.length,
            itemBuilder: (context, index) {
              final video = searchProvider.videos[index];
              return ListTile(
                leading: Image.network(
                  video.thumbnails.lowResUrl,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.music_note, color: Colors.grey);
                  },
                ),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${video.author} • ${video.duration?.toString().split('.').first ?? 'Live'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  
                  // ignore: avoid_print
                  print('Video dipilih: ${video.title}');
                },
              );
            },
          );
        },
      ),
    );
  }
}