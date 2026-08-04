import '../models/admin_dashboard_response.dart';
import '../services/admin_dashboard_service.dart';

class AdminDashboardRepository {
  final AdminDashboardService _service;

  AdminDashboardRepository(this._service);

  AdminDashboardResponse? _cachedData;
  DateTime? _lastFetchTime;

  /// Expose cached data for immediate display
  AdminDashboardResponse? get cachedData => _cachedData;

  Future<AdminDashboardResponse> getAdminDashboard({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null && now.difference(_lastFetchTime!).inMinutes < 15) {
      return _cachedData!;
    }
    try {
      _cachedData = await _service.getAdminDashboard();
      _lastFetchTime = now;
      return _cachedData!;
    } catch (e) {
      if (_cachedData != null) return _cachedData!;
      rethrow;
    }
  }

  void clearCache() {
    _cachedData = null;
    _lastFetchTime = null;
  }
}
