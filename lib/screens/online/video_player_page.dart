import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({super.key, required this.videoId, required String backendUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  final String _backendUrl = 'https://yt-dlp-server-yplayer.vercel.app'; // Ganti dengan URL backend Anda

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final url = Uri.parse('$_backendUrl/info?url=https://www.youtube.com/watch?v=${widget.videoId}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final info = json.decode(response.body);
        final formats = info['streaming_formats'] as Map;
        
        if (formats.isNotEmpty) {
          // Ambil URL dari resolusi tertinggi
          final firstKey = formats.keys.first;
          final streamUrl = formats[firstKey]['url'];

          _controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
          
          _controller!.addListener(() {
            if (_controller!.value.isInitialized) {
              setState(() {
                _isLoading = false;
              });
            }
          });

          await _controller!.initialize();
        } else {
          throw Exception('Tidak ada format streaming yang tersedia');
        }
      } else {
        throw Exception('Gagal mendapatkan info video');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _controller != null && _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : const Text('Gagal memuat video.'),
      ),
      floatingActionButton: _controller != null && _controller!.value.isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}