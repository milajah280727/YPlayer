// lib/services/ytdl_service.dart

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YTDLService {
  static final YoutubeExplode _yt = YoutubeExplode();

  static Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results.map((video) {
        return {
          'id': video.id.value,
          'title': video.title,
          'channel': video.author,
          'duration': video.duration?.toString().split('.').first ?? 'Live',
          'thumbnail': video.thumbnails.highResUrl,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String> getVideoStream(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final streamInfo = manifest.muxed.withHighestBitrate();
    return streamInfo.url.toString();
  }

  // --- FUNGSI INI ADALAH KUNCI SUKSESNYA ---
  static Future<String> getAudioStream(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    
    // Ambil semua stream muxed (video + audio)
    final allMuxedStreams = manifest.muxed.toList();
    
    // Urutkan dari bitrate terendah ke tertinggi
    allMuxedStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));
    
    // Ambil yang pertama (bitrate terendah)
    final lowestBitrateStream = allMuxedStreams.first;
    
    return lowestBitrateStream.url.toString();
  }

  static Future<Video> getInfo(String videoId) async {
    return await _yt.videos.get(videoId);
  }

  static Future<Map<String, dynamic>> getInfoAsMap(String videoId) async {
    final video = await _yt.videos.get(videoId);
    return {
      'id': video.id.value,
      'title': video.title,
      'channel': video.author,
      'duration': video.duration,
      'thumbnailUrl': video.thumbnails.highResUrl,
    };
  }
}