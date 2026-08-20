import '../models/attendance_response_model.dart';
import '../models/monthly_report_file.dart';
import '../data/models/punch_summary_response_model.dart';
import '../data/models/punch_pair_response_model.dart';

abstract class SAAttendanceRepository {
  Future<AttendanceResponseModel> getAllAttendance({
    required String startDate,
    required String endDate,
    String? machineCode,
    String? employeeId,
    bool? isCheckIn,
    int? departmentId,
    int pageNumber,
    int pageSize,
  });

  Future<MonthlyReportFile> downloadMonthlyPdf({
    required int month,
    required int year,
  });

  Future<PunchSummaryResponseModel> getPunchSummary({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  });

  Future<PunchPairResponseModel> getPunchPairs({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  });
}
