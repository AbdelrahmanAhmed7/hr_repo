import '../models/attendance_response_model.dart';
import '../models/monthly_report_file.dart';
import '../models/punch_pair.dart';

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

  Future<PunchPairsResponse> getPunchPairs({
    String? userId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 15,
  });
}
