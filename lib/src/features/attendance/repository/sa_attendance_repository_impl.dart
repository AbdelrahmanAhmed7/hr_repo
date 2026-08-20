import '../models/attendance_response_model.dart';
import '../models/monthly_report_file.dart';
import '../data/models/punch_summary_response_model.dart';
import '../data/models/punch_pair_response_model.dart';
import '../services/sa_attendance_service.dart';
import 'sa_attendance_repository.dart';

class SAAttendanceRepositoryImpl implements SAAttendanceRepository {
  final SAAttendanceService _service;

  SAAttendanceRepositoryImpl(this._service);

  @override
  Future<AttendanceResponseModel> getAllAttendance({
    required String startDate,
    required String endDate,
    String? machineCode,
    String? employeeId,
    bool? isCheckIn,
    int? departmentId,
    int pageNumber = 1,
    int pageSize = 100,
  }) {
    return _service.getAllAttendance(
      startDate: startDate,
      endDate: endDate,
      machineCode: machineCode,
      employeeId: employeeId,
      isCheckIn: isCheckIn,
      departmentId: departmentId,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  @override
  Future<PunchSummaryResponseModel> getPunchSummary({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  }) {
    return _service.getPunchSummary(
      userId: userId,
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<PunchPairResponseModel> getPunchPairs({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  }) {
    return _service.getPunchPairs(
      userId: userId,
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<MonthlyReportFile> downloadMonthlyPdf({
    required int month,
    required int year,
  }) {
    return _service.downloadMonthlyPdf(month: month, year: year);
  }
}
