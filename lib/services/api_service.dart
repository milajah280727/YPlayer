// lib/services/api_service.dart

// PERBAIKAN: Hapus import yang tidak digunakan
// import 'package:yplayer/services/ytdl_service.dart';

class ApiService {
  // Ganti dengan URL backend streaming Anda
  static const String _baseUrl = 'https://compile-surge-halloween-memorabilia.trycloudflare.com';

  // --- Endpoint untuk Mendapatkan Daftar Format/Resolusi ---
  // Digunakan oleh YTDLService untuk mendapatkan pilihan kualitas video
  static String getFormatsEndpoint(String videoId) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/get-formats?url=$url';
  }

  // --- Endpoint untuk Streaming Audio ---
  // Digunakan oleh YTDLService.getAudioStream()
  static String getStreamAudioEndpoint(String videoId) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/stream-audio?url=$url';
  }

  // --- Endpoint untuk Streaming Video ---
  // Digunakan oleh YTDLService.getVideoStream()
  static String getStreamVideoEndpoint(String videoId, String resolution) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/stream-video?url=$url&resolution=$resolution';
  }

  // --- Endpoint untuk Unduhan Audio ---
  // Digunakan oleh DownloadService.downloadAudio()
static String getDownloadAudioEndpoint(String videoId) {
  final url = 'https://www.youtube.com/watch?v=$videoId';
  // Tidak perlu encoding manual, Dio akan menangani ini
  return '$_baseUrl/download-audio?url=$url';
}

  // --- Endpoint untuk Unduhan Video ---
  // Digunakan oleh DownloadService.downloadVideo()
  static String getDownloadVideoEndpoint(String videoId, String resolution) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    return '$_baseUrl/download?url=$url&quality=$resolution';
  }
}