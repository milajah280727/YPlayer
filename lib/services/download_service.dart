import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'local_media_service.dart';

class DownloadService {
  static late Dio _dio;
  static const String _baseUrl =
      'https://defining-came-buffalo-cups.trycloudflare.com';

  // Inisialisasi Dio dengan konfigurasi yang tepat
  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
      // Tambahkan ini untuk mencegah encoding berlebihan
      followRedirects: true,
      validateStatus: (status) => status! < 500, // Menerima status < 500
    ));
    
    // Tambahkan interceptor untuk logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
  }
  
  // Panggil initialize() saat aplikasi dimulai
  static void init() {
    initialize();
  }

  // Fungsi untuk testing koneksi ke backend
  static Future<bool> testBackendConnection() async {
    try {
      final response = await _dio.get('$_baseUrl/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend connection test failed: $e');
      return false;
    }
  }

  // Fungsi untuk memeriksa dan meminta izin penyimpanan
    // Fungsi untuk memeriksa dan meminta izin penyimpanan
  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Android 13 (API 33) dan ke atas: Gunakan izin media granular
        if (sdkInt >= 33) {
          final audioPermission = await Permission.audio.request();
          final videoPermission = await Permission.videos.request();

          // Berikan akses jika salah satu izin relevan diberikan
          return audioPermission.isGranted || videoPermission.isGranted;
        }
        // Android 12 (API 32) dan ke bawah: Gunakan izin penyimpanan lama
        else {
          final storagePermission = await Permission.storage.request();
          return storagePermission.isGranted;
        }
      } else if (Platform.isIOS) {
        // iOS tidak memerlukan izin eksplisit untuk mengakses dokumen di sandbox-nya sendiri
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }
  // Fungsi untuk mendapatkan direktori penyimpanan yang sesuai
  static Future<Directory?> getStorageDirectory() async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 30) {
          try {
            directory = Directory('/storage/emulated/0/Download/Yplayer');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } catch (e) {
            directory = await getApplicationDocumentsDirectory();
            directory = Directory('${directory.path}/Yplayer');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        } else {
          directory = Directory('/storage/emulated/0/Download/Yplayer');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        directory = Directory('${directory.path}/Yplayer');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }

      return directory;
    } catch (e) {
      debugPrint('Error getting storage directory: $e');
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${appDir.path}/Yplayer');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      } catch (e) {
        debugPrint('Error creating fallback directory: $e');
        return null;
      }
    }
  }

  // Fungsi untuk mendapatkan informasi video
  static Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/info',
        queryParameters: {'url': 'https://www.youtube.com/watch?v=$videoId'},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting video info: $e');
      return null;
    }
  }

  // Fungsi untuk mendapatkan daftar format video
  static Future<List<Map<String, dynamic>>> getVideoFormats(
    String videoId,
  ) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/get-formats',
        queryParameters: {'url': 'https://www.youtube.com/watch?v=$videoId'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> formats = response.data['formats'];
        return formats.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting video formats: $e');
      return [];
    }
  }

  // Fungsi untuk download audio
  static Future<String?> downloadAudio(
    String videoId,
    String title,
    String channel,
    String thumbnailUrl,
    Function(double) onProgress,
  ) async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        debugPrint('Storage permission denied');
        return null;
      }

      final directory = await getStorageDirectory();
      if (directory == null) {
        debugPrint('Could not get storage directory');
        return null;
      }

      // PERUBAHAN: Gunakan judul yang sudah dibersihkan sebagai nama file
      final sanitizedTitle = sanitizeFileName(title);
      final fileName = '$sanitizedTitle.mp3';
      final filePath = '${directory.path}/$fileName';

      debugPrint('Starting audio download for title: $sanitizedTitle');
      debugPrint('Download URL: $_baseUrl/download-audio');
      debugPrint('Query parameters: url=https://www.youtube.com/watch?v=$videoId, quality=best');

      await _dio.download(
        '$_baseUrl/download-audio',
        filePath,
        queryParameters: {
          'url': 'https://www.youtube.com/watch?v=$videoId',
          'quality': 'best',
        },
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        options: Options(
          method: 'GET',
          receiveTimeout: const Duration(minutes: 30),
        ),
      );

      // PERBAIKAN: Verifikasi file telah diunduh dengan benar
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Downloaded file does not exist: $filePath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('Downloaded file size: ${fileSize / (1024 * 1024)} MB');

      if (fileSize < 1024) { // Jika file kurang dari 1KB, kemungkinan error
        debugPrint('Downloaded file is too small, likely an error');
        return null;
      }

      // Simpan thumbnail secara lokal dengan videoId
      await LocalMediaService.saveThumbnail(videoId, thumbnailUrl);

      // Jika berhasil, simpan ke riwayat unduhan
      await LocalMediaService.saveToDownloadHistory(
        videoId: videoId,
        title: title,
        channel: channel,
        thumbnail: thumbnailUrl,
      );

      return filePath;
    } catch (e) {
      debugPrint('Error downloading audio: $e');
      if (e is DioException) {
        debugPrint('Error response: ${e.response?.data}');
        debugPrint('Error headers: ${e.response?.headers}');
        debugPrint('Error request options: ${e.requestOptions}');
      }
      return null;
    }
  }

  // Fungsi untuk download video dengan kualitas tertentu
  static Future<String?> downloadVideo(
    String videoId,
    String title,
    String channel,
    String thumbnailUrl,
    String formatId,
    Function(double) onProgress,
  ) async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        debugPrint('Storage permission denied');
        return null;
      }

      final directory = await getStorageDirectory();
      if (directory == null) {
        debugPrint('Could not get storage directory');
        return null;
      }

      // PERUBAHAN: Gunakan judul yang sudah dibersihkan sebagai nama file
      final sanitizedTitle = sanitizeFileName(title);
      final fileName = '$sanitizedTitle.mp4';
      final filePath = '${directory.path}/$fileName';

      debugPrint('Starting video download for title: $sanitizedTitle');
      debugPrint('Download URL: $_baseUrl/download');
      debugPrint('Query parameters: url=https://www.youtube.com/watch?v=$videoId, format_id=$formatId');

      await _dio.download(
        '$_baseUrl/download',
        filePath,
        queryParameters: {
          'url': 'https://www.youtube.com/watch?v=$videoId',
          'format_id': formatId,
        },
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        options: Options(
          method: 'GET',
          receiveTimeout: const Duration(minutes: 30),
        ),
      );

      // PERBAIKAN: Verifikasi file telah diunduh dengan benar
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Downloaded file does not exist: $filePath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('Downloaded file size: ${fileSize / (1024 * 1024)} MB');

      if (fileSize < 1024) { // Jika file kurang dari 1KB, kemungkinan error
        debugPrint('Downloaded file is too small, likely an error');
        return null;
      }

      // Simpan thumbnail secara lokal dengan videoId
      await LocalMediaService.saveThumbnail(videoId, thumbnailUrl);

      // Jika berhasil, simpan ke riwayat unduhan
      await LocalMediaService.saveToDownloadHistory(
        videoId: videoId,
        title: title,
        channel: channel,
        thumbnail: thumbnailUrl,
      );

      return filePath;
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (e is DioException) {
        debugPrint('Error response: ${e.response?.data}');
        debugPrint('Error headers: ${e.response?.headers}');
        debugPrint('Error request options: ${e.requestOptions}');
      }
      return null;
    }
  }

  // Fungsi untuk membersihkan nama file dari karakter yang tidak valid
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}