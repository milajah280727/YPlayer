// lib/screens/online/teratas.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';

class TeratasPageOnline extends StatefulWidget {
  const TeratasPageOnline({super.key});

  @override
  State<TeratasPageOnline> createState() => _TeratasPageOnlineState();
}

class _TeratasPageOnlineState extends State<TeratasPageOnline> {
  List<Map<String, dynamic>> _topSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopSongs();
  }

  Future<void> _fetchTopSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await YTDLService.search('top hits indonesia');
      setState(() {
        _topSongs = results.take(20).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching top songs: $e');
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
              itemCount: _topSongs.length,
              itemBuilder: (context, index) {
                final song = _topSongs[index];
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
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
                  trailing: const Icon(Icons.play_circle),
                  onTap: () {
                    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
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
  }
}