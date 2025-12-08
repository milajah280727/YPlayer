// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatefulWidget {
  // Perubahan: Menerima fungsi unduhan yang memiliki parameter onProgress
  final String title;
  final Future<String?> Function(Function(double)) downloadFunction;

  const DownloadProgressDialog({
    super.key,
    required this.title,
    required this.downloadFunction,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  bool _isCompleted = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Mencegah dialog ditutup dengan menekan di luar area
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startDownload();
      }
    });
  }

  void _startDownload() async {
    try {
      // Panggil fungsi unduhan dan berikan callback untuk memperbarui progress
      final result = await widget.downloadFunction((progress) {
        // Callback ini akan dipanggil oleh DownloadService
        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      });

      if (result != null) {
        if (mounted) {
          setState(() {
            _progress = 1.0;
            _isCompleted = true;
          });
        }
        
        // Tunggu sebentar sebelum menutup dialog
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      debugPrint('Error in download dialog: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jangan biarkan dialog ditutup saat proses berlangsung
    return WillPopScope(
      onWillPop: () async => _isCompleted || _hasError,
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasError)
              const Column(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Terjadi kesalahan saat mengunduh'),
                ],
              )
            else if (_isCompleted)
              const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 16),
                  Text('Unduhan selesai'),
                ],
              )
            else
              Column(
                children: [
                  CircularProgressIndicator(value: _progress),
                  const SizedBox(height: 16),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text('Mengunduh...'),
                ],
              ),
          ],
        ),
        // Hanya tampilkan tombol jika ada error atau sudah selesai
        actions: _isCompleted || _hasError
            ? [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ]
            : [],
      ),
    );
  }
}