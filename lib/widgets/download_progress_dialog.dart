import 'package:flutter/material.dart';

class DownloadProgressSnackBar {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  // Menampilkan snackbar dengan progress bar
  static void show(
    BuildContext context, {
    required String title,
    required Future<String?> Function(Function(double)) downloadFunction,
    Function(String?)? onComplete,
    Function(String)? onError,
  }) {
    // Jangan tampilkan jika sudah ada snackbar yang aktif
    if (_isShowing) return;

    _isShowing = true;
    
    // Buat overlay untuk menampilkan snackbar kustom
    _overlayEntry = OverlayEntry(
      builder: (context) => _DownloadProgressSnackBar(
        title: title,
        downloadFunction: downloadFunction,
        onComplete: (result) {
          _isShowing = false;
          _overlayEntry?.remove();
          _overlayEntry = null;
          onComplete?.call(result);
        },
        onError: (error) {
          _isShowing = false;
          _overlayEntry?.remove();
          _overlayEntry = null;
          onError?.call(error);
        },
      ),
    );

    // Tambahkan overlay ke context
    Overlay.of(context).insert(_overlayEntry!);
  }

  // Menyembunyikan snackbar
  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }
}

class _DownloadProgressSnackBar extends StatefulWidget {
  final String title;
  final Future<String?> Function(Function(double)) downloadFunction;
  final Function(String?) onComplete;
  final Function(String) onError;

  const _DownloadProgressSnackBar({
    Key? key,
    required this.title,
    required this.downloadFunction,
    required this.onComplete,
    required this.onError,
  }) : super(key: key);

  @override
  State<_DownloadProgressSnackBar> createState() => _DownloadProgressSnackBarState();
}

class _DownloadProgressSnackBarState extends State<_DownloadProgressSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _progress = 0.0;
  bool _isCompleted = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi animasi
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    
    // Mulai animasi dan download
    _controller.forward();
    _startDownload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDownload() async {
    try {
      // Panggil fungsi download dan berikan callback untuk progress
      final result = await widget.downloadFunction((progress) {
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
        
        // Tunggu sebentar sebelum menutup
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          widget.onComplete(result);
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          widget.onError('Download failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      debugPrint('Error in download snackbar: $e');
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        widget.onError('Download error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Positioned untuk menempatkan snackbar di bagian bawah
    return Positioned(
      bottom: 75,
      left: 0,
      right: 0,
      child: Material(
        color: const Color.fromARGB(0, 86, 83, 83),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // Animasi slide up dari bawah
            return Transform.translate(
              offset: Offset(0, (1 - _animation.value) * 100),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hasError 
                  ? Colors.red.shade400 
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_hasError)
                      const Icon(Icons.error, color: Color.fromARGB(255, 255, 0, 0))
                    else if (_isCompleted)
                      const Icon(Icons.check_circle, color: Color.fromARGB(255, 5, 255, 97))
                    else
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 255, 1, 1)),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _hasError 
                            ? 'Error downloading' 
                            : _isCompleted 
                                ? 'Download completed' 
                                : widget.title,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_hasError && !_isCompleted)
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                if (!_hasError && !_isCompleted) ...[
                  const SizedBox(height: 12),
                  // Progress bar linear
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}