// lib/providers/search_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yplayer/services/ytdl_service.dart';

class SearchProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = false;
  List<String> _searchHistory = [];

  List<Map<String, dynamic>> get videos => _videos;
  bool get isLoading => _isLoading;
  List<String> get searchHistory => _searchHistory;

  Future<void> search(String query) async {
    if (query.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await YTDLService.search(query);
      _videos = results;
      await addToSearchHistory(query);
    } catch (e) {
      debugPrint('Error searching songs: $e');
      _videos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('search_history') ?? [];
    notifyListeners();
  }

  Future<void> addToSearchHistory(String query) async {
    if (_searchHistory.contains(query)) {
      _searchHistory.remove(query);
    }
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.take(10).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    notifyListeners();
  }

  // 新增：删除单个搜索历史项
  Future<void> removeFromSearchHistory(String query) async {
    _searchHistory.remove(query);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    notifyListeners();
  }

  // 新增：清空所有搜索历史
  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    notifyListeners();
  }
}