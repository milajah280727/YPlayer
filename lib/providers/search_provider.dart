import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchProvider extends ChangeNotifier {
  final YoutubeExplode _youtube = YoutubeExplode();
  static const String _historyKey = 'search_history';

  // State variables
  List<Video> _videos = [];
  bool _isLoading = false;
  List<String> _searchHistory = [];
  String _currentSearchQuery = '';

  // Getters
  List<Video> get videos => _videos;
  bool get isLoading => _isLoading;
  List<String> get searchHistory => _searchHistory;
  String get currentSearchQuery => _currentSearchQuery;

  SearchProvider() {
    _loadHistory();
  }

  /// Memuat riwayat pencarian dari shared_preferences
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList(_historyKey) ?? [];
    notifyListeners();
  }

  /// Menyimpan riwayat pencarian ke shared_preferences
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _searchHistory);
  }

  /// Menambahkan query ke riwayat pencarian
  void addToHistory(String query) {
    if (query.isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.take(10).toList();
    }
    _saveHistory();
    notifyListeners();
  }

  /// Menghapus semua riwayat pencarian
  void clearHistory() async {
    _searchHistory.clear();
    await _saveHistory();
    notifyListeners();
  }

  /// MENAMBAHKAN FUNGSI BARU: Menghapus query tertentu dari riwayat pencarian
  void removeFromHistory(String query) {
    _searchHistory.remove(query);
    _saveHistory();
    notifyListeners();
  }

  /// Fungsi untuk melakukan pencarian video
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _videos.clear();
      _currentSearchQuery = '';
      notifyListeners();
      return;
    }

    _currentSearchQuery = query;
    _isLoading = true;
    _videos.clear();
    notifyListeners();

    try {
      final searchList = await _youtube.search.search(query);
      _videos = searchList.take(20).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error during search: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _youtube.close();
    super.dispose();
  }
}