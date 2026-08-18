import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/attendance_response_model.dart';
import '../models/monthly_report_file.dart';
import '../models/punch_pair.dart';

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

  Future<PunchPairsResponse> getPunchPairs({
    String? userId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 15,
  }) async {
    String fmt(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}-${d.year}';

    final response = await _dioClient.dio.get(
      '/api/Attendance/punch-pairs',
      queryParameters: {
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        if (from != null) 'from': fmt(from),
        if (to != null) 'to': fmt(to),
        'page': page,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(response.data);
    return PunchPairsResponse.fromJson(map);
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
