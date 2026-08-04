import '../api/public_holiday_api.dart';
import '../models/public_holiday_model.dart';
import '../models/holiday_exception_model.dart';

class PublicHolidayService {
  final PublicHolidayApi _api;

  PublicHolidayService(this._api);

  Future<List<PublicHolidayModel>> getAllHolidays({int? year}) async {
    return await _api.getPublicHolidays(year: year);
  }

  Future<PublicHolidayModel> getHolidayById(int id) async {
    return await _api.getPublicHolidayById(id);
  }

  Future<List<PublicHolidayModel>> getHolidaysForYear(int year) async {
    final allHolidays = await getAllHolidays(year: year);
    return allHolidays.where((holiday) => holiday.year == year && holiday.isActive).toList();
  }

  Future<bool> isHoliday(DateTime date) async {
    final allHolidays = await getHolidaysForYear(date.year);
    return allHolidays.any((holiday) =>
        holiday.isActive &&
        holiday.date.year == date.year &&
        holiday.date.month == date.month &&
        holiday.date.day == date.day);
  }

  Future<String?> getHolidayName(DateTime date) async {
    final allHolidays = await getHolidaysForYear(date.year);
    try {
      final holiday = allHolidays.firstWhere(
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
    return await _api.createPublicHoliday(holiday);
  }

  Future<PublicHolidayModel> updateHoliday(int id, PublicHolidayModel holiday) async {
    return await _api.updatePublicHoliday(id, holiday);
  }

  Future<void> deleteHoliday(int id) async {
    await _api.deletePublicHoliday(id);
  }

  // Exception Management
  Future<List<HolidayExceptionModel>> getHolidayExceptions(int holidayId) async {
    return await _api.getHolidayExceptions(holidayId);
  }

  Future<HolidayExceptionModel> addHolidayException(int holidayId, HolidayExceptionModel exception) async {
    return await _api.addHolidayException(holidayId, exception);
  }

  Future<void> deleteHolidayException(int exceptionId) async {
    await _api.deleteHolidayException(exceptionId);
  }
}
