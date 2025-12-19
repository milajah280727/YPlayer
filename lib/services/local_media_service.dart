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
  /// LOGIKA BARU: Membaca dari riwayat dan memverifikasi keberadaan file.
  static Future<List<Map<String, dynamic>>> getDownloadedMedia() async {
    try {
      final directory = await getStorageDirectory();
      if (directory == null) return [];

      // 1. Muat riwayat unduhan dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final List<String> downloadHistory =
          prefs.getStringList(_downloadHistoryKey) ?? [];
      
      final List<Map<String, dynamic>> mediaList = [];

      // 2. Iterasi melalui riwayat, bukan file sistem secara langsung
      for (final item in downloadHistory) {
        final parts = item.split('|||');
        if (parts.length < 4) continue; // Lewati entri yang tidak valid

        final videoId = parts[0];
        final title = parts[1];
        final channel = parts[2];
        final thumbnailUrl = parts[3];

        // 3. Bangun kembali nama file yang diharapkan menggunakan judul yang disimpan
        final sanitizedTitle = sanitizeFileName(title);
        final audioFileName = '$sanitizedTitle.mp3';
        final videoFileName = '$sanitizedTitle.mp4';

        // 4. Periksa keberadaan file audio dan video
        final audioFile = File('${directory.path}/$audioFileName');
        final videoFile = File('${directory.path}/$videoFileName');

        File? primaryFile;
        String type;

        if (await audioFile.exists()) {
          primaryFile = audioFile;
          type = 'audio';
        } else if (await videoFile.exists()) {
          primaryFile = videoFile;
          type = 'video';
        } else {
          // PERBAIKAN: Jika tidak ada file yang ditemukan, lanjut ke item berikutnya
          continue;
        }

        // 5. Jika file ditemukan, tambahkan ke daftar
        mediaList.add({
          'id': videoId, // ID video masih penting untuk thumbnail
          'title': title,
          'channel': channel,
          'thumbnail': thumbnailUrl, // Gunakan URL remote, atau cek thumbnail lokal
          'path': primaryFile.path,
          'type': type,
        });
      }

      // 6. Urutkan berdasarkan urutan di riwayat (terbaru dulu)
      // Karena kita iterasi dari awal riwayat, hasilnya sudah terurut.
      
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