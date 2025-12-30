import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'local_media_service.dart';

class DownloadService {
  static const String _baseUrl =
      'https://output-columns-jet-portable.trycloudflare.com';

  // ================= PERBAIKAN KRUSIAL =================
  // 1. Hapus 'late' agar error LateInitializationError tidak muncul.
  // 2. Inisialisasi langsung menggunakan method pembantu _createDio()
  //    agar interceptor dan konfigurasi terpasang sejak awal.
  static final Dio _dio = _createDio();

  // Fungsi pembantu untuk konfigurasi Dio (diakses saat class dimuat)
  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
      followRedirects: true,
      // PERBAIKAN: Cek null status sebelum dibandingkan
      validateStatus: (status) => status != null && status < 500,
    ));

    // Pasang interceptor disini agar aman
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
    
    return dio;
  }

  // Kita biarkan init() kosong atau gunakan untuk pengecekan tambahan,
  // karena _dio sudah otomatis tersedia saat class dipanggil.
  static void init() {
    // Dio sudah siap di sini
  }

  // Fungsi untuk testing koneksi ke backend
  static Future<bool> testBackendConnection() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend connection test failed: $e');
      return false;
    }
  }

  // Fungsi untuk memeriksa dan meminta izin penyimpanan
  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          final audioPermission = await Permission.audio.request();
          final videoPermission = await Permission.videos.request();
          return audioPermission.isGranted || videoPermission.isGranted;
        } else {
          final storagePermission = await Permission.storage.request();
          return storagePermission.isGranted;
        }
      } else if (Platform.isIOS) {
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

        // Android 11 (SDK 30) ke atas, perlu hati-hati akses direktori eksternal
        if (sdkInt >= 30) {
          try {
            // Coba akses direktori Download langsung
            directory = Directory('/storage/emulated/0/Download/Yplayer');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } catch (e) {
            // Fallback ke direktori aplikasi jika gagal akses langsung
            directory = await getApplicationDocumentsDirectory();
            directory = Directory('${directory.path}/Yplayer');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        } else {
          // Android 10 ke bawah
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
        '/info',
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
        '/get-formats',
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

      // Gunakan judul yang sudah dibersihkan
      final sanitizedTitle = sanitizeFileName(title);
      final fileName = '$sanitizedTitle.mp3';
      final filePath = '${directory.path}/$fileName';

      debugPrint('Starting audio download for title: $sanitizedTitle');
      debugPrint('Download URL: $_baseUrl/download-audio');
      debugPrint('Query parameters: url=https://www.youtube.com/watch?v=$videoId, quality=best');

      await _dio.download(
        '/download-audio',
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

      // Verifikasi file
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Downloaded file does not exist: $filePath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('Downloaded file size: ${fileSize / (1024 * 1024)} MB');

      if (fileSize < 1024) {
        debugPrint('Downloaded file is too small, likely an error');
        return null;
      }

      // Simpan thumbnail & riwayat
      await LocalMediaService.saveThumbnail(videoId, thumbnailUrl);
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

  // Fungsi untuk download video
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

      final sanitizedTitle = sanitizeFileName(title);
      final fileName = '$sanitizedTitle.mp4';
      final filePath = '${directory.path}/$fileName';

      debugPrint('Starting video download for title: $sanitizedTitle');
      debugPrint('Download URL: $_baseUrl/download');
      debugPrint('Query parameters: url=https://www.youtube.com/watch?v=$videoId, format_id=$formatId');

      await _dio.download(
        '/download',
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

      // Verifikasi file
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Downloaded file does not exist: $filePath');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('Downloaded file size: ${fileSize / (1024 * 1024)} MB');

      if (fileSize < 1024) {
        debugPrint('Downloaded file is too small, likely an error');
        return null;
      }

      // Simpan thumbnail & riwayat
      await LocalMediaService.saveThumbnail(videoId, thumbnailUrl);
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

  // Fungsi untuk membersihkan nama file
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}