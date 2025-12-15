import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LocalMediaService {
  static const String _downloadHistoryKey = 'download_history';

  /// Mendapatkan direktori penyimpanan tempat file diunduh.
  static Future<Directory?> getStorageDirectory() async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        // Coba gunakan folder Download publik terlebih dahulu
        directory = Directory('/storage/emulated/0/Download/Yplayer');
        if (!await directory.exists()) {
          // Jika gagal, gunakan direktori aplikasi sebagai fallback
          final appDir = await getApplicationDocumentsDirectory();
          directory = Directory('${appDir.path}/Yplayer');
        }
      } else if (Platform.isIOS) {
        final appDir = await getApplicationDocumentsDirectory();
        directory = Directory('${appDir.path}/Yplayer');
      }

      if (directory != null && !await directory.exists()) {
        await directory.create(recursive: true);
      }

      return directory;
    } catch (e) {
      debugPrint('Error getting storage directory: $e');
      // Fallback ke direktori aplikasi jika semua gagal
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

  /// Mendapatkan direktori khusus untuk thumbnail
  static Future<Directory?> getThumbnailsDirectory() async {
    try {
      final directory = await getStorageDirectory();
      if (directory == null) return null;

      final thumbnailsDir = Directory('${directory.path}/thumbnails');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      return thumbnailsDir;
    } catch (e) {
      debugPrint('Error getting thumbnails directory: $e');
      return null;
    }
  }

  /// Menyimpan informasi file yang baru diunduh ke riwayat.
  static Future<void> saveToDownloadHistory({
    required String videoId,
    required String title,
    required String channel,
    required String thumbnail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> downloadHistory =
          prefs.getStringList(_downloadHistoryKey) ?? [];

      // Hapus entri lama jika ada untuk mencegah duplikat
      downloadHistory.removeWhere((item) => item.startsWith('$videoId|||'));

      // Tambahkan entri baru dengan timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      downloadHistory
          .add('$videoId|||$title|||$channel|||$thumbnail|||$timestamp');

      // Batasi riwayat hanya 100 item terbaru
      if (downloadHistory.length > 100) {
        downloadHistory.sort((a, b) =>
            b.split('|||').last.compareTo(a.split('|||').last));
        downloadHistory.removeRange(100, downloadHistory.length);
      }

      await prefs.setStringList(_downloadHistoryKey, downloadHistory);
    } catch (e) {
      debugPrint('Error saving to download history: $e');
    }
  }

  /// Mendapatkan semua media yang diunduh, diurutkan dari yang terbaru.
  static Future<List<Map<String, dynamic>>> getDownloadedMedia() async {
    try {
      final directory = await getStorageDirectory();
      if (directory == null) return [];

      final List<FileSystemEntity> files = directory.listSync();
      final List<Map<String, dynamic>> mediaList = [];

      // Dapatkan riwayat unduhan dan urutkan berdasarkan timestamp
      final prefs = await SharedPreferences.getInstance();
      final List<String> downloadHistory =
          prefs.getStringList(_downloadHistoryKey) ?? [];

      // Buat map untuk pencarian cepat metadata dari riwayat
      final Map<String, Map<String, String>> historyMap = {};
      for (final item in downloadHistory) {
        final parts = item.split('|||');
        if (parts.length >= 5) {
          historyMap[parts[0]] = {
            'title': parts[1],
            'channel': parts[2],
            'thumbnail': parts[3],
            'timestamp': parts[4],
          };
        }
      }

      // Kelompokkan file berdasarkan nama dasar (tanpa ekstensi)
      final Map<String, List<File>> groupedFiles = {};
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          final baseName = fileName.contains('.')
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;
          if (!groupedFiles.containsKey(baseName)) {
            groupedFiles[baseName] = [];
          }
          groupedFiles[baseName]!.add(file);
        }
      }

      // Proses setiap kelompok file
      for (final entry in groupedFiles.entries) {
        final baseName = entry.key;
        final filesInGroup = entry.value;

        File? audioFile;
        File? videoFile;
        File? thumbnailFile;

        for (final file in filesInGroup) {
          if (file.path.endsWith('.mp3')) {
            audioFile = file;
          } else if (file.path.endsWith('.mp4') || file.path.endsWith('.webm')) {
            videoFile = file;
          } else if (file.path.endsWith('.jpg') || file.path.endsWith('.png')) {
            thumbnailFile = file;
          }
        }

        final primaryFile = audioFile ?? videoFile;
        if (primaryFile == null) continue;

        // Coba ekstrak videoId dari baseName
        String videoId = baseName;
        
        // Jika baseName adalah videoId (alphanumeric)
        if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(baseName)) {
          videoId = baseName;
        } else {
          // Coba cari videoId dari historyMap berdasarkan title
          final foundEntry = historyMap.entries.firstWhere(
            (entry) => sanitizeFileName(entry.value['title']!) == baseName,
            orElse: () => MapEntry('', {}),
          );
          if (foundEntry.key.isNotEmpty) {
            videoId = foundEntry.key;
          }
        }

        final historyData = historyMap[videoId] ?? historyMap.values.firstWhere(
          (data) => sanitizeFileName(data['title']!) == baseName,
          orElse: () => {
            'title': baseName,
            'channel': 'Unknown Channel',
            'thumbnail': 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        final title = historyData['title'] ?? baseName;
        final channel = historyData['channel'] ?? 'Unknown Channel';
        final thumbnail = thumbnailFile?.path ?? historyData['thumbnail'] ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
        final downloadTime = historyData['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(historyData['timestamp']!))
            : primaryFile.statSync().modified;

        mediaList.add({
          'id': videoId,
          'title': title,
          'channel': channel,
          'thumbnail': thumbnail,
          'path': primaryFile.path,
          'type': primaryFile.path.endsWith('.mp3') ? 'audio' : 'video',
          'downloadTime': downloadTime,
        });
      }

      // Urutkan berdasarkan waktu unduhan (terbaru pertama)
      mediaList.sort((a, b) => b['downloadTime'].compareTo(a['downloadTime']));

      return mediaList;
    } catch (e) {
      debugPrint('Error getting downloaded media: $e');
      return [];
    }
  }

  /// Mendapatkan path thumbnail lokal jika ada
  static Future<String?> getLocalThumbnailPath(String videoId) async {
    try {
      final thumbnailsDir = await getThumbnailsDirectory();
      if (thumbnailsDir == null) return null;

      // PERBAIKAN: Cari thumbnail di folder thumbnails
      final thumbnailPath = '${thumbnailsDir.path}/$videoId.jpg';
      final thumbnailFile = File(thumbnailPath);

      debugPrint("Checking for thumbnail at: $thumbnailPath");

      if (await thumbnailFile.exists()) {
        debugPrint("Found thumbnail!");
        return thumbnailPath;
      }

      debugPrint("No local thumbnail found for ID: $videoId");
      return null;
    } catch (e) {
      debugPrint('Error getting local thumbnail: $e');
      return null;
    }
  }

  /// Menyimpan thumbnail ke penyimpanan lokal
  static Future<void> saveThumbnail(String videoId, String thumbnailUrl) async {
    try {
      final thumbnailsDir = await getThumbnailsDirectory();
      if (thumbnailsDir == null) return;

      // PERBAIKAN: Simpan thumbnail di folder thumbnails dengan nama videoId
      final thumbnailPath = '${thumbnailsDir.path}/$videoId.jpg';
      final thumbnailFile = File(thumbnailPath);

      // Hanya unduh jika thumbnail belum ada
      if (!await thumbnailFile.exists()) {
        final response = await http.get(Uri.parse(thumbnailUrl));
        await thumbnailFile.writeAsBytes(response.bodyBytes);
        debugPrint('Thumbnail saved: ${thumbnailFile.path}');
      } else {
        debugPrint('Thumbnail already exists: ${thumbnailFile.path}');
      }
    } catch (e) {
      debugPrint('Error saving thumbnail: $e');
    }
  }

  /// Fungsi untuk membersihkan nama file dari karakter yang tidak valid.
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}