// lib/screens/online/favorit.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';

class FavoritPageOnline extends StatefulWidget {
  const FavoritPageOnline({super.key});

  @override
  State<FavoritPageOnline> createState() => _FavoritPageOnlineState();
}

class _FavoritPageOnlineState extends State<FavoritPageOnline> {
  List<Map<String, dynamic>> _favoriteSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteSongs();
  }

  Future<void> _fetchFavoriteSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Untuk saat ini, kita akan menggunakan lagu-lagu populer sebagai favorit
      // Dalam implementasi nyata, ini akan mengambil dari database favorit pengguna
      final results = await YTDLService.search('indonesian pop hits');
      setState(() {
        _favoriteSongs = results.take(20).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching favorite songs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _favoriteSongs.length,
              itemBuilder: (context, index) {
                final song = _favoriteSongs[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      song['thumbnail'],
                      width: 50,
                      height: 50,
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.pink),
                        onPressed: () {
                          // Implementasi untuk menghapus dari favorit
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dihapus dari favorit')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle),
                        onPressed: () {
                          final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                          playerProvider.playMusic(
                            videoId: song['id'],
                            title: song['title'],
                            channel: song['channel'],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

