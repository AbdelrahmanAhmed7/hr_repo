import 'package:intl/intl.dart';
import '../services/attendance_api_service.dart';
import '../models/attendance_checkin_request.dart';
import '../models/attendance_list_response.dart';
import '../models/attendance_record.dart';
import '../models/monthly_report_file.dart';

class AttendanceRepository {
  final AttendanceApiService _service;

  AttendanceRepository({required AttendanceApiService service})
    : _service = service;

  Future<AttendanceRecord> checkIn({
    required String fingerprintKey,
    required double latitude,
    required double longitude,
  }) async {
    final request = AttendanceCheckinRequest(
      fingerprintKey: fingerprintKey,
      latitude: latitude,
      longitude: longitude,
    );

    return await _service.checkIn(request);
  }

  Future<AttendanceRecord> checkOut({
    required String fingerprintKey,
    required double latitude,
    required double longitude,
  }) async {
    final request = AttendanceCheckinRequest(
      fingerprintKey: fingerprintKey,
      latitude: latitude,
      longitude: longitude,
    );

    return await _service.checkOut(request);
  }

  Future<AttendanceRecord?> getTodayAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _service.getAttendanceByDate(today);
  }

  Future<AttendanceRecord?> getAttendanceByDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await _service.getAttendanceByDate(dateStr);
  }

  Future<AttendanceListResponse> getAllAttendance({
    required DateTime startDate,
    required DateTime endDate,
    String? machineCode,
    String? employeeId,
    bool? isCheckIn,
    int pageNumber = 1,
    int pageSize = 50,
  }) {
    return _service.getAllAttendance(
      startDate: startDate,
      endDate: endDate,
      machineCode: machineCode,
      employeeId: employeeId,
      isCheckIn: isCheckIn,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  Future<MonthlyReportFile> downloadMonthlyReport({
    required int month,
    required int year,
  }) {
    return _service.downloadMonthlyReport(month: month, year: year);
  }

  /// Download the authenticated user's monthly attendance PDF.
  Future<MonthlyReportFile> downloadMonthlyAttendancePdf({
    required int month,
    required int year,
  }) {
    return _service.downloadMonthlyAttendancePdf(month: month, year: year);
  }
}
