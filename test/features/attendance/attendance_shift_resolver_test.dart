import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/features/attendance/models/attendance_record.dart';
import 'package:mediconsult_internal/src/features/attendance/utils/attendance_shift_resolver.dart';

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

DateTime _at(int month, int day, int hour, [int minute = 0]) =>
    DateTime(2026, month, day, hour, minute);

void main() {
  group('overnight shift 23:00 -> 08:00 stored under the start date', () {
    // Monday 2026-09-28 23:00 check-in, no departure yet.
    final openShift = [
      _record(date: '2026-09-28', inTime: '23:00:00'),
    ];

    test('22:50 with no record -> noRecord', () {
      final state = resolveAttendanceState(
        records: const [],
        now: _at(9, 28, 22, 50),
      );
      expect(state.status, AttendanceShiftStatus.noRecord);
      expect(state.record, isNull);
    });

    test('23:05 just after check-in -> checkedInActive', () {
      final state = resolveAttendanceState(
        records: openShift,
        now: _at(9, 28, 23, 5),
      );
      expect(state.status, AttendanceShiftStatus.checkedInActive);
      expect(state.checkInDateTime, DateTime(2026, 9, 28, 23, 0));
    });

    test('23:59 still active', () {
      final state = resolveAttendanceState(
        records: openShift,
        now: _at(9, 28, 23, 59),
      );
      expect(state.status, AttendanceShiftStatus.checkedInActive);
    });

    test('00:05 after midnight stays active (check-out offered)', () {
      final state = resolveAttendanceState(
        records: openShift,
        now: _at(9, 29, 0, 5),
      );
      expect(state.status, AttendanceShiftStatus.checkedInActive);
      expect(state.checkInDateTime, DateTime(2026, 9, 28, 23, 0));
    });

    test('03:00 active', () {
      final state = resolveAttendanceState(
        records: openShift,
        now: _at(9, 29, 3),
      );
      expect(state.status, AttendanceShiftStatus.checkedInActive);
    });

    test('07:55 active', () {
      final state = resolveAttendanceState(
        records: openShift,
        now: _at(9, 29, 7, 55),
      );
      expect(state.status, AttendanceShiftStatus.checkedInActive);
    });

    test('08:05 after check-out -> completed with next-day departure', () {
      final state = resolveAttendanceState(
        records: [
          _record(date: '2026-09-28', inTime: '23:00:00', outTime: '08:00:00'),
        ],
        now: _at(9, 29, 8, 5),
      );
      expect(state.status, AttendanceShiftStatus.completed);
      expect(state.departureDateTime, DateTime(2026, 9, 29, 8, 0));
      expect(state.checkInDateTime, DateTime(2026, 9, 28, 23, 0));
    });

    test('22:50 next day -> available again (noRecord)', () {
      final state = resolveAttendanceState(
        records: [
          _record(date: '2026-09-28', inTime: '23:00:00', outTime: '08:00:00'),
        ],
        now: _at(9, 29, 22, 50),
      );
      expect(state.status, AttendanceShiftStatus.noRecord);
    });
  });

  group('normal day shift 09:00 -> 17:00 is unchanged', () {
    test('midday active, evening completed, next morning available', () {
      final open = [_record(date: '2026-09-28', inTime: '09:00:00')];
      expect(
        resolveAttendanceState(records: open, now: _at(9, 28, 12)).status,
        AttendanceShiftStatus.checkedInActive,
      );

      final done = [
        _record(date: '2026-09-28', inTime: '09:00:00', outTime: '17:00:00'),
      ];
      expect(
        resolveAttendanceState(records: done, now: _at(9, 28, 18)).status,
        AttendanceShiftStatus.completed,
      );
      expect(
        resolveAttendanceState(records: done, now: _at(9, 29, 9)).status,
        AttendanceShiftStatus.noRecord,
      );
    });
  });

  group('manually edited conventions', () {
    test('14:00 -> 00:00:00 works', () {
      final open = [_record(date: '2026-09-28', inTime: '14:00:00')];
      expect(
        resolveAttendanceState(records: open, now: _at(9, 28, 23, 30)).status,
        AttendanceShiftStatus.checkedInActive,
      );

      final done = [
        _record(date: '2026-09-28', inTime: '14:00:00', outTime: '00:00:00'),
      ];
      final state = resolveAttendanceState(
        records: done,
        now: _at(9, 29, 0, 5),
      );
      expect(state.status, AttendanceShiftStatus.completed);
      expect(state.departureDateTime, DateTime(2026, 9, 29, 0, 0));
    });

    test('00:00:00 -> 08:00:00 works', () {
      final open = [_record(date: '2026-09-28', inTime: '00:00:00')];
      expect(
        resolveAttendanceState(records: open, now: _at(9, 28, 3)).status,
        AttendanceShiftStatus.checkedInActive,
      );

      final done = [
        _record(date: '2026-09-28', inTime: '00:00:00', outTime: '08:00:00'),
      ];
      final state = resolveAttendanceState(
        records: done,
        now: _at(9, 28, 9),
      );
      expect(state.status, AttendanceShiftStatus.completed);
      expect(state.departureDateTime, DateTime(2026, 9, 28, 8, 0));
    });
  });

  group('placeholders, staleness and formats', () {
    test('id=0 placeholder with null times is ignored', () {
      final state = resolveAttendanceState(
        records: [_record(id: 0)],
        now: _at(9, 28, 23, 5),
      );
      expect(state.status, AttendanceShiftStatus.noRecord);
    });

    test('stale open record does not block check-in', () {
      final state = resolveAttendanceState(
        records: [_record(date: '2026-09-26', inTime: '09:00:00')],
        now: _at(9, 28, 9),
      );
      expect(state.status, AttendanceShiftStatus.staleOpen);
      expect(state.status, isNot(AttendanceShiftStatus.checkedInActive));
      expect(state.checkInDateTime, DateTime(2026, 9, 26, 9, 0));
    });

    test('MAX_SHIFT_DURATION boundary: 16h active, 16h01 stale', () {
      final open = [_record(date: '2026-09-28', inTime: '23:00:00')];
      expect(
        resolveAttendanceState(records: open, now: _at(9, 29, 15)).status,
        AttendanceShiftStatus.checkedInActive,
      );
      expect(
        resolveAttendanceState(records: open, now: _at(9, 29, 15, 1)).status,
        AttendanceShiftStatus.staleOpen,
      );
    });

    test('7-fractional-digit times parse', () {
      final state = resolveAttendanceState(
        records: [
          _record(
            date: '2026-09-28',
            inTime: '23:00:00.0000000',
            outTime: '08:00:05.1234567',
          ),
        ],
        now: _at(9, 29, 8, 5),
      );
      expect(state.status, AttendanceShiftStatus.completed);
      expect(state.departureDateTime, DateTime(2026, 9, 29, 8, 0, 5));
      expect(state.checkInDateTime, DateTime(2026, 9, 28, 23, 0, 0));
    });

    test('garbage times yield unknown, never noRecord', () {
      final state = resolveAttendanceState(
        records: [_record(date: '2026-09-28', inTime: 'not-a-time')],
        now: _at(9, 28, 23, 5),
      );
      expect(state.status, AttendanceShiftStatus.unknown);
      expect(state.warnings, isNotEmpty);
    });

    test('unparseable date with a check-in yields unknown', () {
      final state = resolveAttendanceState(
        records: [_record(date: 'not-a-date', inTime: '23:00:00')],
        now: _at(9, 28, 23, 5),
      );
      expect(state.status, AttendanceShiftStatus.unknown);
    });

    test('valid active shift wins over an unparseable record', () {
      final state = resolveAttendanceState(
        records: [
          _record(date: '2026-09-28', inTime: 'not-a-time'),
          _record(date: '2026-09-28', inTime: '23:00:00'),
        ],
        now: _at(9, 28, 23, 5),
      );
      expect(state.status, AttendanceShiftStatus.checkedInActive);
    });

    test('ISO date with time part parses', () {
      final state = resolveAttendanceState(
        records: [
          _record(date: '2026-09-28T00:00:00', inTime: '23:00:00'),
        ],
        now: _at(9, 28, 23, 5),
      );
      expect(state.status, AttendanceShiftStatus.checkedInActive);
      expect(state.checkInDateTime, DateTime(2026, 9, 28, 23, 0));
    });

    test('DST-safe next-day departure keeps wall time', () {
      final spring = resolveAttendanceState(
        records: [
          _record(date: '2026-04-23', inTime: '23:00:00', outTime: '08:00:00'),
        ],
        now: DateTime(2026, 4, 24, 8, 5),
      );
      expect(spring.status, AttendanceShiftStatus.completed);
      expect(spring.departureDateTime?.day, 24);
      expect(spring.departureDateTime?.hour, 8);

      final autumn = resolveAttendanceState(
        records: [
          _record(date: '2026-10-28', inTime: '23:00:00', outTime: '08:00:00'),
        ],
        now: DateTime(2026, 10, 29, 8, 5),
      );
      expect(autumn.status, AttendanceShiftStatus.completed);
      expect(autumn.departureDateTime?.day, 29);
      expect(autumn.departureDateTime?.hour, 8);
    });

    test('today completed wins over an older stale open record', () {
      final state = resolveAttendanceState(
        records: [
          _record(date: '2026-09-26', inTime: '09:00:00'),
          _record(
            date: '2026-09-29',
            inTime: '09:00:00',
            outTime: '10:00:00',
          ),
        ],
        now: _at(9, 29, 18),
      );
      expect(state.status, AttendanceShiftStatus.completed);
    });
  });
}
