import '../models/public_holiday_model.dart';
import '../models/holiday_exception_model.dart';
import '../services/public_holiday_service.dart';

class PublicHolidayRepository {
  final PublicHolidayService _service;
  List<PublicHolidayModel>? _cachedHolidays;
  DateTime? _lastFetchTime;
  final Map<int, List<PublicHolidayModel>> _cachedHolidaysByYear = {};
  final Map<int, DateTime> _lastFetchTimeByYear = {};

  PublicHolidayRepository(this._service);

  /// Get all holidays with caching (cache for 1 hour)
  Future<List<PublicHolidayModel>> getAllHolidays({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final shouldRefresh = forceRefresh ||
        _cachedHolidays == null ||
        _lastFetchTime == null ||
        now.difference(_lastFetchTime!).inHours >= 1;

    if (shouldRefresh) {
      _cachedHolidays = await _service.getAllHolidays();
      _lastFetchTime = now;
    }

    return _cachedHolidays!;
  }

  Future<PublicHolidayModel> getHolidayById(int id) async {
    return await _service.getHolidayById(id);
  }

  Future<List<PublicHolidayModel>> getHolidaysForYear(int year) async {
    final now = DateTime.now();
    final shouldRefresh = !_cachedHolidaysByYear.containsKey(year) ||
        !_lastFetchTimeByYear.containsKey(year) ||
        now.difference(_lastFetchTimeByYear[year]!).inHours >= 1;

    if (shouldRefresh) {
      _cachedHolidaysByYear[year] = await _service.getHolidaysForYear(year);
      _lastFetchTimeByYear[year] = now;
    }

    final holidays = _cachedHolidaysByYear[year]!;
    return holidays.where((holiday) => holiday.year == year && holiday.isActive).toList();
  }

  Future<bool> isHoliday(DateTime date) async {
    final holidays = await getHolidaysForYear(date.year);
    return holidays.any((holiday) =>
        holiday.isActive &&
        holiday.date.year == date.year &&
        holiday.date.month == date.month &&
        holiday.date.day == date.day);
  }

  Future<String?> getHolidayName(DateTime date) async {
    final holidays = await getHolidaysForYear(date.year);
    try {
      final holiday = holidays.firstWhere(
        (h) =>
            h.isActive &&
            h.date.year == date.year &&
            h.date.month == date.month &&
            h.date.day == date.day,
      );
      return holiday.nameAr;
    } catch (e) {
      return null;
    }
  }

  // CRUD Operations
  Future<PublicHolidayModel> createHoliday(PublicHolidayModel holiday) async {
    final created = await _service.createHoliday(holiday);
    clearCache();
    return created;
  }

  Future<PublicHolidayModel> updateHoliday(int id, PublicHolidayModel holiday) async {
    final updated = await _service.updateHoliday(id, holiday);
    clearCache();
    return updated;
  }

  Future<void> deleteHoliday(int id) async {
    await _service.deleteHoliday(id);
    clearCache();
  }

  // Exception Management
  Future<List<HolidayExceptionModel>> getHolidayExceptions(int holidayId) async {
    return await _service.getHolidayExceptions(holidayId);
  }

  Future<HolidayExceptionModel> addHolidayException(int holidayId, HolidayExceptionModel exception) async {
    return await _service.addHolidayException(holidayId, exception);
  }

  Future<void> deleteHolidayException(int exceptionId) async {
    await _service.deleteHolidayException(exceptionId);
  }

  /// Clear cache
  void clearCache() {
    _cachedHolidays = null;
    _lastFetchTime = null;
    _cachedHolidaysByYear.clear();
    _lastFetchTimeByYear.clear();
  }
}
