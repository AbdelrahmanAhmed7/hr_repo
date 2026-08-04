import '../models/super_admin_dashboard_response.dart';
import '../services/super_admin_dashboard_service.dart';

class SuperAdminDashboardRepository {
  final SuperAdminDashboardService _service;

  SuperAdminDashboardRepository(this._service);

  SuperAdminDashboardResponse? _cachedData;
  DateTime? _lastFetchTime;

  SuperAdminDashboardResponse? get cachedData => _cachedData;

  Future<SuperAdminDashboardResponse> getSuperAdminDashboard({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null && now.difference(_lastFetchTime!).inMinutes < 15) {
      return _cachedData!;
    }
    try {
      _cachedData = await _service.getSuperAdminDashboard();
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
