import '../models/attendance_record.dart';

const Duration kMaxShiftDuration = Duration(hours: 16);

enum AttendanceShiftStatus {
  noRecord,
  checkedInActive,
  completed,
  staleOpen,
  unknown,
}

class ResolvedAttendanceState {
  final AttendanceShiftStatus status;
  final AttendanceRecord? record;
  final DateTime? checkInDateTime;
  final DateTime? departureDateTime;
  final List<String> warnings;

  const ResolvedAttendanceState({
    required this.status,
    this.record,
    this.checkInDateTime,
    this.departureDateTime,
    this.warnings = const [],
  });
}

ResolvedAttendanceState resolveAttendanceState({
  required List<AttendanceRecord> records,
  required DateTime now,
  Duration maxShiftDuration = kMaxShiftDuration,
}) {
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  final warnings = <String>[];
  var hasUnparseable = false;

  final enriched = <_EnrichedRecord>[];
  for (final record in records) {
    if (record.id == 0) continue;
    final date = _parseDate(record.date);
    final checkIn = record.attendanceTime != null && date != null
        ? _combineDateAndTime(date, record.attendanceTime!)
        : null;
    if (record.attendanceTime != null && (date == null || checkIn == null)) {
      hasUnparseable = true;
      warnings.add('unparseable attendance record id=${record.id}');
      continue;
    }
    DateTime? departure;
    if (record.departureTime != null && date != null) {
      departure = _resolveDeparture(
        date,
        record.attendanceTime,
        record.departureTime!,
      );
    }
    enriched.add(
      _EnrichedRecord(
        record: record,
        checkInDateTime: checkIn,
        departureDateTime: departure,
      ),
    );
  }

  bool isOpen(_EnrichedRecord e) =>
      e.checkInDateTime != null && e.departureDateTime == null;

  ResolvedAttendanceState unknown() => ResolvedAttendanceState(
        status: AttendanceShiftStatus.unknown,
        warnings: warnings,
      );

  final open = enriched.where(isOpen).toList()
    ..sort((a, b) => b.checkInDateTime!.compareTo(a.checkInDateTime!));
  if (open.isNotEmpty &&
      now.difference(open.first.checkInDateTime!) <= maxShiftDuration) {
    final active = open.first;
    return ResolvedAttendanceState(
      status: AttendanceShiftStatus.checkedInActive,
      record: active.record,
      checkInDateTime: active.checkInDateTime,
      warnings: warnings,
    );
  }

  final withDeparture = enriched
      .where((e) => e.departureDateTime != null)
      .toList()
    ..sort((a, b) => b.departureDateTime!.compareTo(a.departureDateTime!));
  if (withDeparture.isNotEmpty) {
    final done = withDeparture.first;
    final checkIn = done.checkInDateTime;
    if (isSameDay(done.departureDateTime!, now) &&
        checkIn != null &&
        now.difference(checkIn) <= maxShiftDuration) {
      return ResolvedAttendanceState(
        status: AttendanceShiftStatus.completed,
        record: done.record,
        checkInDateTime: done.checkInDateTime,
        departureDateTime: done.departureDateTime,
        warnings: warnings,
      );
    }
  }

  if (hasUnparseable) return unknown();

  if (open.isNotEmpty) {
    final stale = open.first;
    return ResolvedAttendanceState(
      status: AttendanceShiftStatus.staleOpen,
      record: stale.record,
      checkInDateTime: stale.checkInDateTime,
      warnings: warnings,
    );
  }

  return ResolvedAttendanceState(
    status: AttendanceShiftStatus.noRecord,
    warnings: warnings,
  );
}

class _EnrichedRecord {
  final AttendanceRecord record;
  final DateTime? checkInDateTime;
  final DateTime? departureDateTime;

  const _EnrichedRecord({
    required this.record,
    required this.checkInDateTime,
    required this.departureDateTime,
  });
}

DateTime? _parseDate(String value) {
  final head = value.length >= 10 ? value.substring(0, 10) : value;
  final parsed = DateTime.tryParse(head);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

({int hour, int minute, int second})? _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2 || parts.length > 3) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  int second = 0;
  if (parts.length == 3) {
    final parsedSeconds = int.tryParse(parts[2].split('.').first);
    if (parsedSeconds == null) return null;
    second = parsedSeconds;
  }
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  if (second < 0 || second > 59) return null;
  return (hour: hour, minute: minute, second: second);
}

DateTime? _combineDateAndTime(DateTime date, String timeValue) {
  final time = _parseTime(timeValue);
  if (time == null) return null;
  try {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      time.second,
    );
  } catch (_) {
    return null;
  }
}

int _compareTime(
  ({int hour, int minute, int second}) a,
  ({int hour, int minute, int second}) b,
) {
  if (a.hour != b.hour) return a.hour.compareTo(b.hour);
  if (a.minute != b.minute) return a.minute.compareTo(b.minute);
  return a.second.compareTo(b.second);
}

// A departure <= check-in belongs to the next calendar day. Built with the
// DateTime constructor (not +24h) so the wall time survives DST transitions.
DateTime? _resolveDeparture(
  DateTime date,
  String? attendanceTime,
  String departureTime,
) {
  final departure = _parseTime(departureTime);
  if (departure == null) return null;
  var resolved = DateTime(
    date.year,
    date.month,
    date.day,
    departure.hour,
    departure.minute,
    departure.second,
  );
  if (attendanceTime == null) return resolved;
  final attendance = _parseTime(attendanceTime);
  if (attendance == null) return resolved;
  if (_compareTime(departure, attendance) <= 0) {
    resolved = DateTime(
      resolved.year,
      resolved.month,
      resolved.day + 1,
      resolved.hour,
      resolved.minute,
      resolved.second,
    );
  }
  return resolved;
}
