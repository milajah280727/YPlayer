// lib/widgets/video_quality_dialog.dart

import 'package:flutter/material.dart';

class VideoQualityDialog extends StatelessWidget {
  final List<Map<String, dynamic>> formats;
  final Function(String) onQualitySelected;

  const VideoQualityDialog({
    super.key,
    required this.formats,
    required this.onQualitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Kualitas Video'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: formats.length,
          itemBuilder: (context, index) {
            final format = formats[index];
            final resolution = format['resolution'] ?? 'Unknown';
            final fileSize = format['filesize'] != null
                ? '${(format['filesize'] / (1024 * 1024)).toStringAsFixed(1)} MB'
                : 'Unknown size';
            final fps = format['fps'] != null ? '${format['fps']} fps' : '';
            
            return ListTile(
              title: Text(resolution),
              subtitle: Text('$fileSize ${fps.isNotEmpty ? '• $fps' : ''}'),
              onTap: () {
                Navigator.of(context).pop();
                onQualitySelected(format['format_id']);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}