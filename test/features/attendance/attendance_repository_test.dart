import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_list_response.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_record.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_checkin_request.dart';
import 'package:mediconsult_internal/src/features/attendance/models/monthly_report_file.dart';
import 'package:mediconsult_internal/src/features/attendance/repository/attendance_repository.dart';
import 'package:mediconsult_internal/src/features/attendance/services/attendance_api_service.dart';

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

class _FakeAttendanceApiService implements AttendanceApiService {
  final Map<String, AttendanceRecord?> byDate;
  final Set<String> failDates;

  _FakeAttendanceApiService({this.byDate = const {}, this.failDates = const {}});

  @override
  Future<AttendanceRecord?> getAttendanceByDate(String date) async {
    if (failDates.contains(date)) throw Exception('timeout');
    return byDate[date];
  }

  @override
  Future<AttendanceRecord> checkIn(AttendanceCheckinRequest request) =>
      throw UnimplementedError();

  @override
  Future<AttendanceRecord> checkOut(AttendanceCheckinRequest request) =>
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
  test('merges today and yesterday, filters id=0 placeholders', () async {
    final service = _FakeAttendanceApiService(byDate: {
      '2026-09-29': _record(date: '2026-09-29', inTime: '09:00:00'),
      '2026-09-28': _record(date: '2026-09-28', inTime: '23:00:00'),
    });
    final repository = AttendanceRepository(service: service);

    final records = await repository.getTodayAndYesterdayRecords(
      cairoNow: DateTime(2026, 9, 29, 10, 0),
    );

    expect(records.map((r) => r.date).toSet(), {'2026-09-29', '2026-09-28'});
  });

  test('placeholder rows are filtered out', () async {
    final service = _FakeAttendanceApiService(byDate: {
      '2026-09-29': _record(id: 0, date: '2026-09-29'),
      '2026-09-28': _record(date: '2026-09-28', inTime: '23:00:00'),
    });
    final repository = AttendanceRepository(service: service);

    final records = await repository.getTodayAndYesterdayRecords(
      cairoNow: DateTime(2026, 9, 29, 10, 0),
    );

    expect(records.length, 1);
    expect(records.first.id, isNot(0));
  });

  test('either day failing throws (caller yields unknown)', () async {
    final service = _FakeAttendanceApiService(
      byDate: {'2026-09-29': _record(date: '2026-09-29', inTime: '09:00:00')},
      failDates: const {'2026-09-28'},
    );
    final repository = AttendanceRepository(service: service);

    await expectLater(
      repository.getTodayAndYesterdayRecords(
        cairoNow: DateTime(2026, 9, 29, 10, 0),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
