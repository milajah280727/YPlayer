// lib/screens/online/beranda.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/services/ytdl_service.dart';

class BerandaPageOnline extends StatefulWidget {
  const BerandaPageOnline({super.key});

  @override
  State<BerandaPageOnline> createState() => _BerandaPageOnlineState();
}

class _BerandaPageOnlineState extends State<BerandaPageOnline> {
  List<Map<String, dynamic>> _trendingSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrendingSongs();
  }

  Future<void> _fetchTrendingSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await YTDLService.search('trending music in indonesia');
      setState(() {
        _trendingSongs = results.take(20).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching trending songs: $e');
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
              itemCount: _trendingSongs.length,
              itemBuilder: (context, index) {
                final song = _trendingSongs[index];
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