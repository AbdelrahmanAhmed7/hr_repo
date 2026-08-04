import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../models/view_mode.dart';

/// Service for caching organization chart user preferences
/// 
/// Persists user settings locally using SharedPreferences:
/// - View mode (tree, list, grid, department)
/// - Orientation (horizontal/vertical)
/// - Compact mode preference
class OrganizationChartPreferencesService {
  /// Save view mode preference
  static Future<void> saveViewMode(OrganizationViewMode viewMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.orgChartViewMode, viewMode.name);
  }

  /// Get saved view mode preference
  static Future<OrganizationViewMode?> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final viewModeString = prefs.getString(StorageKeys.orgChartViewMode);
    if (viewModeString == null) return null;
    
    try {
      return OrganizationViewMode.values.firstWhere(
        (mode) => mode.name == viewModeString,
      );
    } catch (e) {
      return null;
    }
  }

  /// Save orientation preference (horizontal/vertical)
  static Future<void> saveOrientation(bool isHorizontal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.orgChartIsHorizontal, isHorizontal);
  }

  /// Get saved orientation preference
  static Future<bool?> getOrientation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.orgChartIsHorizontal);
  }

  /// Save compact mode preference
  static Future<void> saveCompactMode(bool isCompactMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.orgChartIsCompactMode, isCompactMode);
  }

  /// Get saved compact mode preference
  static Future<bool?> getCompactMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.orgChartIsCompactMode);
  }

  /// Clear all preferences
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.orgChartViewMode);
    await prefs.remove(StorageKeys.orgChartIsHorizontal);
    await prefs.remove(StorageKeys.orgChartIsCompactMode);
  }
}

