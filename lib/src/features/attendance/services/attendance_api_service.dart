import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../api/attendance_api.dart';
import '../models/attendance_checkin_request.dart';
import '../models/attendance_list_response.dart';
import '../models/attendance_record.dart';
import '../models/monthly_report_file.dart';

class AttendanceApiService {
  final AttendanceApi _api;
  final DioClient _dioClient;

  AttendanceApiService(this._api, this._dioClient);

  Future<AttendanceRecord> checkIn(AttendanceCheckinRequest request) async {
    return await _api.checkIn(request.toJson());
  }

  Future<AttendanceRecord> checkOut(AttendanceCheckinRequest request) async {
    return await _api.checkOut(request.toJson());
  }

  Future<AttendanceRecord?> getAttendanceByDate(String date) async {
    final response = await _dioClient.dio.get<Map<String, dynamic>?>(
      '/api/Attendance/my/$date',
      options: Options(
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300 || status == 404,
      ),
    );

    if (response.statusCode == 404 || response.data == null) {
      return null;
    }

    return AttendanceRecord.fromJson(response.data!);
  }

  Future<AttendanceListResponse> getAllAttendance({
    required DateTime startDate,
    required DateTime endDate,
    String? machineCode,
    String? employeeId,
    bool? isCheckIn,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/Attendance/All',
      queryParameters: {
        'startDate': _formatApiDate(startDate),
        'endDate': _formatApiDate(endDate),
        if (machineCode != null && machineCode.trim().isNotEmpty)
          'machineCode': machineCode.trim(),
        if (employeeId != null && employeeId.trim().isNotEmpty)
          'employeeId': employeeId.trim(),
        'isCheckIn': ?isCheckIn,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(response.data);
    return AttendanceListResponse.fromJson(map);
  }

  Future<MonthlyReportFile> downloadMonthlyReport({
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.dio.get<List<int>>(
      '/api/Attendance/monthly-report',
      queryParameters: {'month': month, 'year': year},
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data ?? const <int>[];
    final fileName =
        _extractFileName(response.headers.value('content-disposition')) ??
        'MonthlyReport_${year}_${month.toString().padLeft(2, '0')}.xlsx';

    return MonthlyReportFile(bytes: bytes, fileName: fileName);
  }

  /// Download monthly attendance PDF for the authenticated user.
  /// Endpoint: GET /api/Attendance/my/monthly-pdf?month={month}&year={year}
  Future<MonthlyReportFile> downloadMonthlyAttendancePdf({
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.dio.get<List<int>>(
      '/api/Attendance/my/monthly-pdf',
      queryParameters: {'month': month, 'year': year},
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': '*/*'},
      ),
    );

    final bytes = response.data ?? const <int>[];
    final fileName =
        _extractFileName(response.headers.value('content-disposition')) ??
        'attendance_${month}_$year.pdf';

    return MonthlyReportFile(bytes: bytes, fileName: fileName);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Invalid response format');
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString();
    final day = date.day.toString();
    final year = date.year.toString();
    return '$month-$day-$year';
  }

  String? _extractFileName(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;

    final utfMatch = RegExp(
      "filename\\*=UTF-8''([^;]+)",
    ).firstMatch(contentDisposition);
    if (utfMatch != null) {
      return Uri.decodeComponent(utfMatch.group(1)!);
    }

    final plainMatch = RegExp(
      'filename="?([^";]+)"?',
    ).firstMatch(contentDisposition);
    return plainMatch?.group(1);
  }
}
