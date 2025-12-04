// lib/widgets/download_progress_dialog.dart

import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatefulWidget {
  final String title;
  final Future<String?> downloadFuture;

  const DownloadProgressDialog({
    super.key,
    required this.title,
    required this.downloadFuture,
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
    _startDownload();
  }

  void _startDownload() async {
    try {
      final result = await widget.downloadFuture;
      if (result != null) {
        setState(() {
          _progress = 1.0;
          _isCompleted = true;
        });
        
        // Tunggu sebentar sebelum menutup dialog
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      } else {
        setState(() {
          _hasError = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                Text('${(_progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
        ],
      ),
    );
  }
}