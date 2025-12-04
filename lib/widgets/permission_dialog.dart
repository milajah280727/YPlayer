// lib/widgets/permission_dialog.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Izin Penyimpanan Diperlukan'),
      content: const Text(
        'Aplikasi memerlukan izin penyimpanan untuk mengunduh file. '
        'Silakan berikan izin di pengaturan aplikasi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            // Buka pengaturan aplikasi
            await openAppSettings();
          },
          child: const Text('Buka Pengaturan'),
        ),
      ],
    );
  }
}