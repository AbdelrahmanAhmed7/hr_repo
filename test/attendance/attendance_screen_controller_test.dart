import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/attendance/attendance_screen_controller.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_list_response.dart';
import 'package:mediconsult_internal/src/features/attendance/models/daily_attendance_record.dart';

void main() {
  group('attendance mapping', () {
    test('combineDateAndTime returns parsed value', () {
      final value = combineDateAndTime('2026-03-01', '09:30:15');

      expect(value, isNotNull);
      expect(value!.year, 2026);
      expect(value.month, 3);
      expect(value.day, 1);
      expect(value.hour, 9);
      expect(value.minute, 30);
      expect(value.second, 15);
    });

    test('combineDateAndTime returns null for invalid data', () {
      expect(combineDateAndTime('bad-date', '09:30'), isNull);
      expect(combineDateAndTime('2026-03-01', null), isNull);
      expect(combineDateAndTime('2026-03-01', ''), isNull);
    });

    test('mapAttendanceItems sorts and maps statuses', () {
      final items = <AttendanceItem>[
        AttendanceItem(
          id: 1,
          employeeName: 'A',
          date: '2026-03-01',
          dayOfWeek: 'Sun',
          attendanceTime: null,
          departureTime: null,
          deviceType: 1,
          createdAt: '2026-03-01T00:00:00',
        ),
        AttendanceItem(
          id: 2,
          employeeName: 'B',
          date: '2026-03-02',
          dayOfWeek: 'Mon',
          attendanceTime: '09:00:00',
          departureTime: null,
          deviceType: 1,
          createdAt: '2026-03-02T00:00:00',
        ),
        AttendanceItem(
          id: 3,
          employeeName: 'C',
          date: '2026-03-03',
          dayOfWeek: 'Tue',
          attendanceTime: '09:00:00',
          departureTime: '17:00:00',
          deviceType: 1,
          createdAt: '2026-03-03T00:00:00',
        ),
      ];

      final result = mapAttendanceItems(items);

      expect(result.length, 3);
      expect(result.first.id, '3');
      expect(result[0].status, AttendanceStatus.present);
      expect(result[1].status, AttendanceStatus.halfDay);
      expect(result[2].status, AttendanceStatus.absent);
    });
  });
}
