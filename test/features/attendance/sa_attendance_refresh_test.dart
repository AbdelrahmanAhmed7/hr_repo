import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/attendance/cubit/sa_attendance_cubit.dart';
import 'package:mediconsult_internal/src/features/attendance/cubit/sa_attendance_state.dart';
import 'package:mediconsult_internal/src/features/attendance/data/models/punch_pair_response_model.dart';
import 'package:mediconsult_internal/src/features/attendance/data/models/punch_summary_response_model.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_record_model.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_response_model.dart';
import 'package:mediconsult_internal/src/features/attendance/models/monthly_report_file.dart';
import 'package:mediconsult_internal/src/features/attendance/repository/sa_attendance_repository.dart';

class _FakeRepo implements SAAttendanceRepository {
  final List<AttendanceRecordModel> rows;
  final List<Map<String, String?>> calls = [];
  bool shouldFail = false;

  _FakeRepo([this.rows = const []]);

  @override
  Future<AttendanceResponseModel> getAllAttendance({
    required String startDate,
    required String endDate,
    String? machineCode,
    String? employeeId,
    bool? isCheckIn,
    int? departmentId,
    int? pageNumber,
    int? pageSize,
  }) async {
    calls.add({'startDate': startDate, 'endDate': endDate});
    if (shouldFail) throw Exception('network');
    return AttendanceResponseModel(
      attendances: rows,
      totalEmployees: rows.length,
      employeesWithAttendance: rows.length,
      employeesAbsent: 0,
      employeesWithDeparture: 0,
      totalDays: 1,
      pageNumber: 1,
      pageSize: 500,
      totalCount: rows.length,
    );
  }

  @override
  Future<MonthlyReportFile> downloadMonthlyPdf({
    required int month,
    required int year,
  }) =>
      throw UnimplementedError();

  @override
  Future<PunchSummaryResponseModel> getPunchSummary({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  }) =>
      throw UnimplementedError();

  @override
  Future<PunchPairResponseModel> getPunchPairs({
    String? userId,
    String? from,
    String? to,
    required int page,
    required int pageSize,
  }) =>
      throw UnimplementedError();
}

const _record = AttendanceRecordModel(
  id: 1,
  employeeName: 'أحمد محمد',
  date: '10-05-2026',
  dayOfWeek: 'الأحد',
  isClosed: false,
  createdAt: '2026-10-05T08:00:00',
);

void main() {
  group('SAAttendanceCubit.refresh', () {
    test('reloads the selected day when no range filter is active', () async {
      final repo = _FakeRepo([_record]);
      final cubit = SAAttendanceCubit(repo);

      await cubit.refresh();

      expect(repo.calls, hasLength(1));
      expect(cubit.state.status, SAAttendanceStatus.success);
      expect(cubit.state.records, hasLength(1));
      await cubit.close();
    });

    test('keeps the active date range instead of falling back to one day',
        () async {
      final repo = _FakeRepo([_record]);
      final cubit = SAAttendanceCubit(repo);
      final from = DateTime(2026, 9, 1);
      final to = DateTime(2026, 9, 30);

      await cubit.loadAttendanceWithRange(startDate: from, endDate: to);
      repo.calls.clear();

      await cubit.refresh();

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single['startDate'], '09-01-2026');
      expect(repo.calls.single['endDate'], '09-30-2026');
      expect(cubit.state.status, SAAttendanceStatus.success);
      await cubit.close();
    });

    test('failed refresh with cached data keeps stale records visible',
        () async {
      final repo = _FakeRepo([_record]);
      final cubit = SAAttendanceCubit(repo);

      await cubit.refresh();
      expect(cubit.state.records, hasLength(1));

      repo.shouldFail = true;
      await cubit.refresh();

      expect(cubit.state.status, SAAttendanceStatus.error);
      // Cached rows are still there for the UI to keep rendering.
      expect(cubit.state.records, hasLength(1));
      expect(cubit.state.filteredRecords, hasLength(1));
      await cubit.close();
    });
  });
}
