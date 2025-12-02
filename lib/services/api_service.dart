// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:8000'; // Ganti dengan URL backend Anda
  
  static Future<Map<String, dynamic>> getVideoInfo(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load video info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching video info: $e');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getVideoFormats(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/formats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['formats']);
      } else {
        throw Exception('Failed to load video formats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching video formats: $e');
    }
  }
  
  static Future<String> downloadVideo(String url, String quality, {String? formatId}) async {
    try {
      final Map<String, dynamic> body = {'url': url, 'quality': quality};
      if (formatId != null) {
        body['format_id'] = formatId;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stream_url']; // URL untuk streaming
      } else {
        throw Exception('Failed to start download: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error starting download: $e');
    }
  }
}