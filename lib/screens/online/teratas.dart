// lib/screens/online/teratas.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
// Hapus import YTDLService

class TeratasPageOnline extends StatefulWidget {
  const TeratasPageOnline({super.key});

  @override
  State<TeratasPageOnline> createState() => _TeratasPageOnlineState();
}

class _TeratasPageOnlineState extends State<TeratasPageOnline> {
  // Hapus state lokal
  // List<Map<String, dynamic>> _topSongs = [];
  // bool _isLoading = true;

  // Hapus _fetchTopSongs

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendapatkan data dari PlayerProvider
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final topSongs = playerProvider.recentlyPlayed;

        return Scaffold(
          body: topSongs.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada lagu yang diputar',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: topSongs.length,
                  itemBuilder: (context, index) {
                    final song = topSongs[index];
                    return ListTile(
                      leading: Stack(
                        children: [
                          ClipRRect(
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
                          // Hapus nomor urut jika tidak diperlukan lagi
                          // Positioned(...),
                        ],
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
                      
                      onTap: () {
                        playerProvider.playMusic(
                          videoId: song['id'],
                          title: song['title'],
                          channel: song['channel'],
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}