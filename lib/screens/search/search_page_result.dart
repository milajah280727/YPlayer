// lib/screens/search/search_page_result.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/providers/search_provider.dart';
// HAPUS BARIS INI: import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchPageResult extends StatefulWidget {
  const SearchPageResult({super.key, required this.query});
  final String query;

  @override
  State<SearchPageResult> createState() => _SearchPageResultState();
}

class _SearchPageResultState extends State<SearchPageResult> {
  @override
  void initState() {
    super.initState();
    // Lakukan pencarian saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).search(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              final video = searchProvider.videos[index];
              return ListTile(
                leading: Image.network(
                  video.thumbnails.highResUrl,
                  width: 120,
                  height: 70,
                  fit: BoxFit.cover,
                ),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${video.author} • ${video.duration?.toString().split('.').first ?? 'Live'}',
                ),
                onTap: () {
                  // Mainkan musik saat video dipilih
                  Provider.of<PlayerProvider>(context, listen: false).playMusic(
                    videoId: video.id.value,
                    title: video.title,
                    channel: video.author,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}