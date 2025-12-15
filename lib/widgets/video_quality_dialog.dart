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
    // --- LOGIKA UNTUK MENGHAPUS DUPLIKASI DAN MEMILIH FORMAT TERBAIK ---
    // 1. Kelompokkan format berdasarkan resolusi
    final Map<String, List<Map<String, dynamic>>> groupedFormats = {};
    for (final format in formats) {
      final resolution = format['resolution'] ?? 'Unknown';
      if (!groupedFormats.containsKey(resolution)) {
        groupedFormats[resolution] = [];
      }
      groupedFormats[resolution]!.add(format);
    }

    // 2. Dari setiap grup, pilih satu format terbaik untuk ditampilkan
    final List<Map<String, dynamic>> uniqueFormats = [];
    for (final entry in groupedFormats.entries) {
      final formatList = entry.value;
      
      // Cari format yang memiliki 'filesize'
      Map<String, dynamic>? bestFormat = formatList.firstWhere(
        (f) => f['filesize'] != null,
        orElse: () => formatList.first, // Jika tidak ada yang memiliki size, ambil yang pertama
      );
      
      uniqueFormats.add(bestFormat);
    }

    // 3. Urutkan format unik dari resolusi tertinggi ke terendah
    uniqueFormats.sort((a, b) {
      final resA = int.tryParse(a['resolution']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
      final resB = int.tryParse(b['resolution']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
      return resB.compareTo(resA); // Urutkan menurun (1080p sebelum 720p)
    });
    // --- AKHIR LOGIKA ---

    return AlertDialog(
      title: const Text('Pilih Kualitas Video'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          // Gunakan panjang dari list yang sudah difilter dan dipilih
          itemCount: uniqueFormats.length,
          itemBuilder: (context, index) {
            // Ambil format dari list yang sudah dipilih
            final format = uniqueFormats[index];
            final resolution = format['resolution'] ?? 'Unknown';
            
            // Tampilkan ukuran file jika ada, jika tidak tampilkan 'Unknown size'
            final fileSize = format['filesize'] != null
                ? '${(format['filesize'] / (1024 * 1024)).toStringAsFixed(1)} MB'
                : 'Unknown size';
                
            final fps = format['fps'] != null ? '${format['fps']} fps' : '';
            
            return ListTile(
              title: Text(resolution),
              subtitle: Text('$fileSize ${fps.isNotEmpty ? '• $fps' : ''}'),
              onTap: () {
                Navigator.of(context).pop();
                // PERBAIKAN: Gunakan resolution sebagai pengganti format_id
                final qualityId = format['format_id'] ?? format['resolution'] ?? '720';
                onQualitySelected(qualityId.toString());
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