import '../../features/holidays/repository/public_holiday_repository.dart';
import '../services/service_locator.dart';

/// Class to handle Egyptian official holidays using API
class EgyptianHolidays {
  static PublicHolidayRepository get _repository =>
      getIt<PublicHolidayRepository>();

  /// Get all holidays for a specific year
  static Future<List<Holiday>> getHolidaysForYear(int year) async {
    final apiHolidays = await _repository.getHolidaysForYear(year);
    return apiHolidays
        .map(
          (h) => Holiday(
            name: h.nameAr,
            date: h.date,
            isFixed:
                true,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Check if a date is a holiday
  static Future<bool> isHoliday(DateTime date) async {
    return await _repository.isHoliday(date);
  }

  /// Get holiday name for a specific date (if it's a holiday)
  static Future<String?> getHolidayName(DateTime date) async {
    return await _repository.getHolidayName(date);
  }

  /// Get all holidays for the current year
  static Future<List<Holiday>> getCurrentYearHolidays() async {
    return getHolidaysForYear(DateTime.now().year);
  }

  /// Get all holidays for next year
  static Future<List<Holiday>> getNextYearHolidays() async {
    return getHolidaysForYear(DateTime.now().year + 1);
  }
}

/// Holiday with date information
class Holiday {
  final String name;
  final DateTime date;
  final bool isFixed;

  Holiday({required this.name, required this.date, required this.isFixed});
}