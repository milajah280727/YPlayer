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
    /// Mendapatkan semua media yang diunduh.
  /// LOGIKA BARU: Scan fisik folder penyimpanan + Lookup Metadata dari Riwayat.
  static Future<List<Map<String, dynamic>>> getDownloadedMedia() async {
    try {
      final directory = await getStorageDirectory();
      if (directory == null) return [];

      if (!await directory.exists()) return [];

      // 1. Load History untuk Metadata Lookup (Judul, Thumbnail, Channel)
      final prefs = await SharedPreferences.getInstance();
      final List<String> downloadHistory = prefs.getStringList(_downloadHistoryKey) ?? [];
      
      final Map<String, dynamic> historyMetadata = {};
      for (final item in downloadHistory) {
        final parts = item.split('|||');
        if (parts.length >= 4) {
          final title = parts[1];
          final sanitized = sanitizeFileName(title);
          // Simpan metadata berdasarkan nama file (karena kita cari file berdasarkan nama)
          historyMetadata[sanitized] = {
            'id': parts[0],
            'channel': parts[2],
            'thumbnail': parts[3],
            'originalTitle': parts[1],
          };
        }
      }

      final List<Map<String, dynamic>> mediaList = [];

      // 2. SCAN FISIK DIREKTORI (Langkah Kunci)
      // Mengambil semua entity di folder
      final Stream<FileSystemEntity> entityList = directory.list();
      
      await for (final entity in entityList) {
        if (entity is File) {
          // Ambil nama file saja (misal: "Lagu A.mp3")
          final fileName = entity.path.split('/').last;

          if (fileName.endsWith('.mp3') || fileName.endsWith('.mp4')) {
            // Ambil nama tanpa ekstensi
            final baseName = fileName.replaceAll('.mp3', '').replaceAll('.mp4', '');
            final type = fileName.endsWith('.mp3') ? 'audio' : 'video';

            // Cek apakah file ini ada di metadata history kita?
            final info = historyMetadata[baseName];

            mediaList.add({
              'id': info != null ? info['id'] : baseName, // Pakai nama file jika tidak ada ID
              'title': info != null ? info['originalTitle'] ?? baseName : baseName,
              'channel': info != null ? info['channel'] : 'Local File',
              'thumbnail': info != null ? info['thumbnail'] : '', // Kosong jika file lama
              'path': entity.path,
              'type': type,
            });
          }
        }
      }

      // 3. Urutkan berdasarkan waktu modifikasi file (Terbaru di atas)
      mediaList.sort((a, b) {
        final fileA = File(a['path']);
        final fileB = File(b['path']);
        try {
          return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
        } catch (e) {
          return 0;
        }
      });

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