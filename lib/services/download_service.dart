import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DownloadService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://announcements-wto-cologne-reputation.trycloudflare.com';

  // Fungsi untuk memeriksa dan meminta izin penyimpanan
  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          final audioPermission = await Permission.audio.request();
          final videoPermission = await Permission.videos.request();
          final photosPermission = await Permission.photos.request();
          
          return audioPermission.isGranted || videoPermission.isGranted || photosPermission.isGranted;
        } else if (sdkInt >= 30) {
          final storagePermission = await Permission.storage.request();
          final manageStoragePermission = await Permission.manageExternalStorage.request();
          
          return storagePermission.isGranted || manageStoragePermission.isGranted;
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
  static Future<List<Map<String, dynamic>>> getVideoFormats(String videoId) async {
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

      final fileName = '${sanitizeFileName(title)}.mp3';
      final filePath = '${directory.path}/$fileName';

      // ====================================================================
      // PERUBAHAN: Kembali menggunakan 'queryParameters' untuk POST request
      // ====================================================================
      await _dio.download(
        '$_baseUrl/download-audio',
        filePath,
        queryParameters: { // <--- BENAR: Mengirim sebagai query parameter
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
          method: 'POST', // <--- Tetap gunakan metode POST
          receiveTimeout: const Duration(minutes: 30),
        ),
      );
      // ====================================================================

      return filePath;
    } catch (e) {
      debugPrint('Error downloading audio: $e');
      return null;
    }
  }

  // Fungsi untuk download video dengan kualitas tertentu
  static Future<String?> downloadVideo(
    String videoId, 
    String title, 
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

      final fileName = '${sanitizeFileName(title)}.mp4';
      final filePath = '${directory.path}/$fileName';

      // ====================================================================
      // PERUBAHAN: Kembali menggunakan 'queryParameters' untuk POST request
      // ====================================================================
      await _dio.download(
        '$_baseUrl/download',
        filePath,
        queryParameters: { // <--- BENAR: Mengirim sebagai query parameter
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
          method: 'POST', // <--- Tetap gunakan metode POST
          receiveTimeout: const Duration(minutes: 30),
        ),
      );
      // ====================================================================

      return filePath;
    } catch (e) {
      debugPrint('Error downloading video: $e');
      return null;
    }
  }

  // Fungsi untuk membersihkan nama file dari karakter yang tidak valid
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}