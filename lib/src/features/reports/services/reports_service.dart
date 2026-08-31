import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/dio_client.dart';
import '../../attendance/data/models/punch_pair_response_model.dart';
import '../../attendance/data/models/punch_summary_response_model.dart';
import '../../attendance/models/monthly_report_file.dart';

class TenantModel {
  final int id;
  final String name;
  final bool isActive;

  const TenantModel({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

class ReportsService {
  final DioClient _dioClient;

  ReportsService(this._dioClient);

  // ── Tenants ──────────────────────────────────────────────────────────────

  /// GET /api/Tenant
  Future<List<TenantModel>> getTenants() async {
    final response = await _dioClient.dio.get('/api/Tenant');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => TenantModel.fromJson(e as Map<String, dynamic>))
          .where((t) => t.isActive)
          .toList();
    }
    return const [];
  }

  // ── Excel downloads ──────────────────────────────────────────────────────

  /// GET /api/Attendance/monthly-report?month={month}&year={year}
  Future<MonthlyReportFile> downloadMonthlyReport({
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.dio.get<List<int>>(
      '/api/Attendance/monthly-report',
      queryParameters: {'month': month, 'year': year},
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': '*/*'},
      ),
    );

    final bytes = response.data ?? const <int>[];
    final fileName =
        _extractFileName(response.headers.value('content-disposition')) ??
        'monthly_report_${month}_$year.xlsx';

    return MonthlyReportFile(bytes: bytes, fileName: fileName);
  }

  /// GET /api/Attendance/monthly-report-details-excel-by-tenant
  ///   ?month={month}&year={year}&tenantId={tenantId}
  Future<MonthlyReportFile> downloadDetailsByTenant({
    required int month,
    required int year,
    required int tenantId,
  }) async {
    final response = await _dioClient.dio.get<List<int>>(
      '/api/Attendance/monthly-report-details-excel-by-tenant',
      queryParameters: {
        'month': month,
        'year': year,
        'tenantId': tenantId,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': '*/*'},
      ),
    );

    final bytes = response.data ?? const <int>[];
    final fileName =
        _extractFileName(response.headers.value('content-disposition')) ??
        'details_tenant_${tenantId}_${month}_$year.xlsx';

    return MonthlyReportFile(bytes: bytes, fileName: fileName);
  }

  /// GET /api/Attendance/shift-report-excel?month={month}&year={year}
  Future<MonthlyReportFile> downloadShiftReport({
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.dio.get<List<int>>(
      '/api/Attendance/shift-report-excel',
      queryParameters: {'month': month, 'year': year},
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': '*/*'},
      ),
    );

    final bytes = response.data ?? const <int>[];
    final fileName =
        _extractFileName(response.headers.value('content-disposition')) ??
        'shift_report_${month}_$year.xlsx';

    return MonthlyReportFile(bytes: bytes, fileName: fileName);
  }

  /// GET /api/Payroll/export-excel?month={month}&year={year}&tenantId={tenantId}
  Future<MonthlyReportFile> downloadPayrollExport({
    required int month,
    required int year,
    required int tenantId,
  }) async {
    final response = await _dioClient.dio.get<List<int>>(
      '/api/Payroll/export-excel',
      queryParameters: {
        'month': month,
        'year': year,
        'tenantId': tenantId,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': '*/*'},
      ),
    );

    final bytes = response.data ?? const <int>[];
    final fileName =
        _extractFileName(response.headers.value('content-disposition')) ??
        'payroll_tenant_${tenantId}_${month}_$year.xlsx';

    return MonthlyReportFile(bytes: bytes, fileName: fileName);
  }

  /// GET /api/Payroll/bank-salary-report?month={month}&year={year}&tenantId={tenantId}
  Future<MonthlyReportFile> downloadBankSalaryReport({
    required int month,
    required int year,
    required int tenantId,
  }) async {
    final response = await _dioClient.dio.get<List<int>>(
      '/api/Payroll/bank-salary-report',
      queryParameters: {
        'month': month,
        'year': year,
        'tenantId': tenantId,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': '*/*'},
      ),
    );

    final bytes = response.data ?? const <int>[];
    final fileName =
        _extractFileName(response.headers.value('content-disposition')) ??
        'bank_salary_${tenantId}_${month}_$year.xlsx';

    return MonthlyReportFile(bytes: bytes, fileName: fileName);
  }

  // ── Paginated attendance data ────────────────────────────────────────────

  /// GET /api/Attendance/punch-pairs
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

  /// GET /api/Attendance/punch-summary
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

  // ── File save + open ─────────────────────────────────────────────────────

  /// Saves bytes to a temp file and returns the path.
  Future<String> saveAndOpen(MonthlyReportFile report) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${report.fileName}');
    await file.writeAsBytes(report.bytes, flush: true);
    return file.path;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
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
