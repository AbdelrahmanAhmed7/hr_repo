import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/core/time/server_clock.dart';
import 'package:mediconsult_internal/src/features/attendance/cubit/attendance_cubit.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_checkin_request.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_list_response.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_record.dart';
import 'package:mediconsult_internal/src/features/attendance/models/monthly_report_file.dart';
import 'package:mediconsult_internal/src/features/attendance/repository/attendance_repository.dart';

AttendanceRecord _record({
  int id = 1,
  String date = '2026-09-28',
  String? inTime,
  String? outTime,
}) {
  return AttendanceRecord(
    id: id,
    userId: 'user-1',
    date: date,
    attendanceTime: inTime,
    departureTime: outTime,
    deviceType: 1,
    location: null,
    createdAt: '${date}T00:00:00',
    updatedAt: null,
  );
}

class _FakeAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> records;
  final bool throwOnLoad;

  _FakeAttendanceRepository({this.records = const [], this.throwOnLoad = false});

  @override
  Future<List<AttendanceRecord>> getTodayAndYesterdayRecords({
    required DateTime cairoNow,
  }) async {
    if (throwOnLoad) throw Exception('network down');
    return records;
  }

  @override
  Future<AttendanceRecord> checkIn({
    required String fingerprintKey,
    required double latitude,
    required double longitude,
  }) =>
      throw UnimplementedError();

  @override
  Future<AttendanceRecord> checkOut({
    required String fingerprintKey,
    required double latitude,
    required double longitude,
  }) =>
      throw UnimplementedError();

  @override
  Future<AttendanceRecord?> getAttendanceByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<AttendanceListResponse> getAllAttendance({
    required DateTime startDate,
    required DateTime endDate,
    String? machineCode,
    String? employeeId,
    bool? isCheckIn,
    int pageNumber = 1,
    int pageSize = 50,
  }) =>
      throw UnimplementedError();

  @override
  Future<MonthlyReportFile> downloadMonthlyReport({
    required int month,
    required int year,
  }) =>
      throw UnimplementedError();

  @override
  Future<MonthlyReportFile> downloadMonthlyAttendancePdf({
    required int month,
    required int year,
  }) =>
      throw UnimplementedError();
}

void main() {
  test('unsynced clock yields unknown, never a default state', () async {
    final cubit = AttendanceCubit(
      _FakeAttendanceRepository(
        records: [_record(date: '2026-09-28', inTime: '23:00:00')],
      ),
      serverClock: ServerClock(),
    );

    await cubit.stream.firstWhere(
      (s) => s.todayAttendance.isUnknown,
    );
    expect(cubit.state.todayAttendance.isUnknown, isTrue);
    expect(cubit.state.todayAttendance.isCheckedIn, isFalse);
    await cubit.close();
  });

  test('open record from yesterday offers check-out', () async {
    final clock = ServerClock();
    clock.sync(DateTime.utc(2026, 9, 29, 0, 5));
    final cubit = AttendanceCubit(
      _FakeAttendanceRepository(
        records: [_record(date: '2026-09-28', inTime: '23:00:00')],
      ),
      serverClock: clock,
    );

    await Future.delayed(const Duration(milliseconds: 300));
    final today = cubit.state.todayAttendance;
    expect(today.isUnknown, isFalse);
    expect(today.isCheckedIn, isTrue);
    expect(today.isCheckedOut, isFalse);
    expect(today.checkInTime, DateTime(2026, 9, 28, 23, 0));
    await cubit.close();
  });

  test('failed load yields unknown', () async {
    final clock = ServerClock();
    clock.sync(DateTime.utc(2026, 9, 29, 0, 5));
    final cubit = AttendanceCubit(
      _FakeAttendanceRepository(throwOnLoad: true),
      serverClock: clock,
    );

    await cubit.stream.firstWhere(
      (s) => s.todayAttendance.isUnknown,
    );
    expect(cubit.state.todayAttendance.isUnknown, isTrue);
    await cubit.close();
  });
}
