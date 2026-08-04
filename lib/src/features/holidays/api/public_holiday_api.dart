import 'package:dio/dio.dart';
import '../models/public_holiday_model.dart';
import '../models/holiday_exception_model.dart';

class PublicHolidayApi {
  final Dio _dio;

  PublicHolidayApi(this._dio);

  /// Get all public holidays
  Future<List<PublicHolidayModel>> getPublicHolidays({int? year}) async {
    final response = await _dio.get(
      '/api/PublicHoliday',
      queryParameters: year == null ? null : <String, dynamic>{'year': year},
      options: Options(headers: const <String, String>{'Accept': 'text/plain'}),
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => PublicHolidayModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get public holiday by ID
  Future<PublicHolidayModel> getPublicHolidayById(int id) async {
    final response = await _dio.get('/api/PublicHoliday/$id');
    return PublicHolidayModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create new public holiday
  Future<PublicHolidayModel> createPublicHoliday(PublicHolidayModel holiday) async {
    final response = await _dio.post(
      '/api/PublicHoliday',
      data: holiday.toJson(),
    );
    return _holidayFromResponse(response.data, holiday);
  }

  /// Update public holiday
  Future<PublicHolidayModel> updatePublicHoliday(int id, PublicHolidayModel holiday) async {
    final response = await _dio.put(
      '/api/PublicHoliday/$id',
      data: holiday.toJson(),
    );
    return _holidayFromResponse(response.data, holiday);
  }

  /// Delete public holiday
  Future<void> deletePublicHoliday(int id) async {
    await _dio.delete('/api/PublicHoliday/$id');
  }

  /// Get exceptions for a holiday
  Future<List<HolidayExceptionModel>> getHolidayExceptions(int holidayId) async {
    final response = await _dio.get('/api/PublicHoliday/$holidayId/exceptions');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => HolidayExceptionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Add exception to a holiday
  Future<HolidayExceptionModel> addHolidayException(int holidayId, HolidayExceptionModel exception) async {
    final response = await _dio.post(
      '/api/PublicHoliday/$holidayId/exceptions',
      data: exception.toJson(),
    );
    return HolidayExceptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete exception
  Future<void> deleteHolidayException(int exceptionId) async {
    await _dio.delete('/api/PublicHoliday/exceptions/$exceptionId');
  }

  PublicHolidayModel _holidayFromResponse(dynamic data, PublicHolidayModel fallback) {
    if (data is Map<String, dynamic>) {
      return PublicHolidayModel.fromJson(data);
    }
    return fallback;
  }
}
