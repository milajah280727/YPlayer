// lib/screens/online/favorit.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
// Hapus import YTDLService karena tidak lagi digunakan di sini

class FavoritPageOnline extends StatefulWidget {
  const FavoritPageOnline({super.key});

  @override
  State<FavoritPageOnline> createState() => _FavoritPageOnlineState();
}

class _FavoritPageOnlineState extends State<FavoritPageOnline> {
  // Hapus state lokal karena data akan diambil dari PlayerProvider
  // bool _isLoading = true; -> Tidak lagi diperlukan

  @override
  void initState() {
    super.initState();
    // Tidak perlu _fetchFavoriteSongs() lagi
  }

  // Hapus _fetchFavoriteSongs karena tidak lagi digunakan

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendapatkan data dari PlayerProvider
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final favoriteSongs = playerProvider.favorites;

        return Scaffold(
          body: favoriteSongs.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada lagu favorit',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final song = favoriteSongs[index];
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
                              // Panggil metode untuk menghapus dari favorit
                              playerProvider.removeFromFavorites(song['id']);
                              
                              // Tampilkan SnackBar konfirmasi
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dihapus dari favorit'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_circle),
                            onPressed: () {
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
      },
    );
  }
}