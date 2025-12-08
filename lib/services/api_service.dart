// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Hapus slash di akhir untuk mencegah double slash //
  static const String _baseUrl = 'https://proceedings-pound-farm-get.trycloudflare.com';

  // --- Endpoint untuk Mendapatkan Informasi Video ---
  // Server: @app.get("/info")
  static Future<Map<String, dynamic>> getVideoInfo(String url) async {
    try {
      final uri = Uri.parse('$_baseUrl/info').replace(queryParameters: {'url': url});
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat info video: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error mengambil info video: $e');
    }
  }
  
  // --- Endpoint untuk Mendapatkan Daftar Format/Resolusi ---
  // Server: @app.get("/get-formats")
  static Future<List<String>> getVideoFormats(String url) async {
    try {
      final uri = Uri.parse('$_baseUrl/get-formats').replace(queryParameters: {'url': url});
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Server mengembalikan {"formats": ["720", "1080", ...]}
        return List<String>.from(data['formats']);
      } else {
        throw Exception('Gagal memuat format video: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error mengambil format video: $e');
    }
  }

  // --- Endpoint untuk Mendapatkan URL Streaming Audio ---
  // Server: @app.get("/get-audio-stream-url")
  static Future<String> getAudioStreamUrl(String url) async {
    try {
      final uri = Uri.parse('$_baseUrl/get-audio-stream-url').replace(queryParameters: {'url': url});
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stream_url'];
      } else {
        throw Exception('Gagal mendapatkan URL stream audio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error mengambil URL stream audio: $e');
    }
  }

  // --- Endpoint untuk Memulai Unduhan Video ---
  // Server: @app.post("/download")
  // Meskipun metodenya POST, server Anda tetap menggunakan Query() untuk parameter
  static Future<String> getDownloadVideoUrl(String url, String quality) async {
    try {
      final uri = Uri.parse('$_baseUrl/download').replace(queryParameters: {
        'url': url,
        'quality': quality,
      });
      
      final response = await http.post(uri);
      
      if (response.statusCode == 200) {
        // Endpoint ini di server Anda mengembalikan StreamingResponse untuk download langsung,
        // bukan JSON. Jadi, Anda tidak bisa memanggilnya seperti ini untuk mendapatkan URL.
        // Anda perlu menangani streaming langsung di Flutter.
        // Atau, jika Anda hanya ingin URL streaming, gunakan endpoint lain.
        // Untuk saat ini, kita asumsikan Anda akan menangani download secara berbeda.
        throw Exception('Endpoint /download untuk streaming langsung, bukan mengambil URL. Gunakan fungsi download di DownloadService.');
      } else {
        throw Exception('Gagal memulai unduhan video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error memulai unduhan video: $e');
    }
  }
}