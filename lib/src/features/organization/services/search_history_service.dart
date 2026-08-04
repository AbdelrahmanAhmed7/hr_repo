import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';

/// Service for managing organization chart search history
/// 
/// Stores and retrieves search queries from local storage.
/// Used to provide search suggestions and recent searches.
class SearchHistoryService {
  static const int _maxHistoryItems = 10;

  /// Get search history
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(StorageKeys.orgChartSearchHistory);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => item as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add search query to history
  static Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      final history = await getSearchHistory();
      
      // Remove duplicate if exists
      history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      
      // Add to beginning
      history.insert(0, query.trim());
      
      // Keep only max items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.orgChartSearchHistory, jsonEncode(history));
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear search history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.orgChartSearchHistory);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Remove specific item from history
  static Future<void> removeFromHistory(String query) async {
    try {
      final history = await getSearchHistory();
      history.removeWhere((item) => item == query);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.orgChartSearchHistory, jsonEncode(history));
    } catch (e) {
      // Ignore errors
    }
  }
}

