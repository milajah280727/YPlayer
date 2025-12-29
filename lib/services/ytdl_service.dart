// lib/services/ytdl_service.dart

import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class YTDLService {
  static final YoutubeExplode _yt = YoutubeExplode();

  // --- FUNGSI INI TETAP, MENGGUNAKAN youtube_explode_dart ---
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

  // --- FUNGSI INI TETAP, MENGGUNAKAN youtube_explode_dart ---
  static Future<Video> getInfo(String videoId) async {
    return await _yt.videos.get(videoId);
  }

  // --- FUNGSI INI TETAP, MENGGUNAKAN youtube_explode_dart ---
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

  // --- PERUBAHAN: Sekarang mengambil URL streaming dari API kita ---
  static Future<String> getVideoStream(
    String videoId,
    String resolution,
  ) async {
    return ApiService.getStreamVideoEndpoint(videoId, resolution);
  }

  // --- PERUBAHAN: Sekarang mengambil URL streaming dari API kita ---
  static Future<String> getAudioStream(String videoId) async {
    return ApiService.getStreamAudioEndpoint(videoId);
  }

  // --- PERUBAHAN: Mengubah tipe data yang dikembalikan ---
    static Future<List<Map<String, dynamic>>> getVideoResolutions(
    String videoId,
  ) async {
    try {
      final uri = Uri.parse(ApiService.getFormatsEndpoint(videoId));
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // PERBAIKAN: Jangan dipaksa jadi List<String>, tapi ambil sebagai List<dynamic>
        // lalu cast ke Map<String, dynamic>
        final List<dynamic> rawFormats = data['formats'] ?? [];
        
        // Ubah list dynamic menjadi list Map yang aman
        final List<Map<String, dynamic>> mapFormats = rawFormats
            .map((item) => item as Map<String, dynamic>)
            .toList();

        return mapFormats;
      } else {
        debugPrint(
          'Gagal memuat format video: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error mengambil format video: $e');
      return [];
    }
  }
}