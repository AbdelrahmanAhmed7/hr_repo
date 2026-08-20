import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../data/models/punch_pair_response_model.dart';
import '../data/models/punch_summary_response_model.dart';
import '../models/attendance_response_model.dart';
import '../models/monthly_report_file.dart';

class SAAttendanceService {
  final DioClient _dioClient;

  SAAttendanceService(this._dioClient);

  Future<AttendanceResponseModel> getAllAttendance({
    required String startDate,
    required String endDate,
    String? machineCode,
    String? employeeId,
    bool? isCheckIn,
    int? departmentId,
    int pageNumber = 1,
    int pageSize = 100,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/Attendance/All',
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
        if (machineCode != null && machineCode.trim().isNotEmpty)
          'machineCode': machineCode.trim(),
        if (employeeId != null && employeeId.trim().isNotEmpty)
          'employeeId': employeeId.trim(),
        'isCheckIn': ?isCheckIn,
        'departmentId': ?departmentId,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(response.data);
    return AttendanceResponseModel.fromJson(map);
  }

  Future<PunchSummaryResponseModel> getPunchSummary({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/Attendance/punch-summary',
      queryParameters: {
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        'from': ?from,
        'to': ?to,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(response.data);
    return PunchSummaryResponseModel.fromJson(map);
  }

  Future<PunchPairResponseModel> getPunchPairs({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/Attendance/punch-pairs',
      queryParameters: {
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        'from': ?from,
        'to': ?to,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(response.data);
    return PunchPairResponseModel.fromJson(map);
  }

  Future<MonthlyReportFile> downloadMonthlyPdf({
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

  String? _extractFileName(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;

    final utfMatch = RegExp(
      r"filename\*=UTF-8''([^;]+)",
    ).firstMatch(contentDisposition);
    if (utfMatch != null) {
      return Uri.decodeComponent(utfMatch.group(1)!);
    }

    final plainMatch = RegExp(
      r'filename="?([^";]+)"?',
    ).firstMatch(contentDisposition);
    return plainMatch?.group(1);
  }
}
