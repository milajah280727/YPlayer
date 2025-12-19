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
        // API Anda mengembalikan {"formats": ["720", "1080", ...]}
        final List<String> stringFormats = List<String>.from(
          data['formats'] ?? [],
        );

        // PERBAIKAN: Ubah List<String> menjadi List<Map<String, dynamic>>
        // Contoh: ['720', '1080'] menjadi [{'resolution': '720'}, {'resolution': '1080'}]
        final List<Map<String, dynamic>> mapFormats = stringFormats
            .map((resolution) => {'resolution': resolution})
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

  // Di dalam class YTDLService

  // --- FUNGSI BARU: Pencarian melalui Backend ---
  static Future<List<Map<String, dynamic>>> searchFromBackend(
    String query,
  ) async {
    try {
      // Ganti URL ini dengan URL backend Anda yang sebenarnya
      // Jika backend berjalan di komputer yang sama dan Anda testing di emulator, localhost bisa digunakan.
      // Jika testing di HP fisik, gunakan IP lokal komputer Anda (misal: http://192.168.1.5:8000)
      final uri = Uri.parse('https://compile-surge-halloween-memorabilia.trycloudflare.com/search?query=$query');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend Anda mengembalikan {"results": [...]}
        final List<dynamic> results = data['results'];
        return results.cast<Map<String, dynamic>>();
      } else {
        debugPrint(
          'Gagal memuat dari backend: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error mengambil data dari backend: $e');
      return [];
    }
  }
}
