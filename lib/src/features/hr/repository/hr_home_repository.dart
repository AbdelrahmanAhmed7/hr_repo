import '../models/hr_home_response.dart';
import '../services/hr_home_service.dart';

class HrHomeRepository {
  final HrHomeService _service;

  HrHomeRepository(this._service);

  HrHomeResponse? _cachedData;
  DateTime? _lastFetchTime;

  Future<HrHomeResponse> getHrHomeData({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null && now.difference(_lastFetchTime!).inMinutes < 15) {
      return _cachedData!;
    }
    try {
      _cachedData = await _service.getHrHomeData();
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
