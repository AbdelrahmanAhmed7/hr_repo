import '../models/attendance_record.dart';

/// Maximum duration of a single shift. An open record older than this is
/// considered stale (forgotten check-out) and must not block a new check-in.
const Duration kMaxShiftDuration = Duration(hours: 16);

/// Explicit punch state resolved from attendance records.
enum AttendanceShiftStatus {
  /// No usable record: user may check in.
  noRecord,

  /// An open shift within [kMaxShiftDuration]: offer check-out.
  checkedInActive,

  /// A shift whose departure falls today: day is done.
  completed,

  /// An open shift older than [kMaxShiftDuration]: must NOT block check-in,
  /// but should be logged/flagged.
  staleOpen,
}

/// Result of [resolveAttendanceState].
class ResolvedAttendanceState {
  final AttendanceShiftStatus status;

  /// The record behind the state (the active, completed or stale record).
  final AttendanceRecord? record;

  /// Resolved check-in instant (record.date + attendanceTime).
  final DateTime? checkInDateTime;

  /// Resolved departure instant. Time-only departures that are
  /// <= the check-in time belong to the next calendar day.
  final DateTime? departureDateTime;

  const ResolvedAttendanceState({
    required this.status,
    this.record,
    this.checkInDateTime,
    this.departureDateTime,
  });
}

/// Resolves the current punch state from attendance records.
///
/// [records] should contain today and yesterday (placeholder rows with
/// id == 0 are ignored). [now] is injected so the logic is unit-testable;
/// never call DateTime.now() inside.
///
/// Rules:
/// - A record is "open" when it has a check-in and no departure.
/// - The most recent open record within [maxShiftDuration] of [now] wins
///   ([AttendanceShiftStatus.checkedInActive]).
/// - Otherwise a departure falling on [now]'s calendar day whose check-in
///   is still within [maxShiftDuration] of [now] wins
///   ([AttendanceShiftStatus.completed]). The check-in recency keeps a
///   morning checkout from marking the whole evening as completed, so a
///   new shift can start later the same day.
/// - Otherwise any remaining open record is
///   ([AttendanceShiftStatus.staleOpen]) — it must not block check-in.
/// - Otherwise ([AttendanceShiftStatus.noRecord]).
ResolvedAttendanceState resolveAttendanceState({
  required List<AttendanceRecord> records,
  required DateTime now,
  Duration maxShiftDuration = kMaxShiftDuration,
}) {
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  final usable = records.where((r) => r.id != 0).toList();

  final enriched = <_EnrichedRecord>[];
  for (final record in usable) {
    final checkIn = record.attendanceTime != null
        ? _combineDateAndTime(record.date, record.attendanceTime!)
        : null;
    DateTime? departure;
    if (record.departureTime != null) {
      departure = _resolveDeparture(
        record.date,
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

  final open = enriched.where(isOpen).toList()
    ..sort((a, b) => b.checkInDateTime!.compareTo(a.checkInDateTime!));
  if (open.isNotEmpty &&
      now.difference(open.first.checkInDateTime!) <= maxShiftDuration) {
    final active = open.first;
    return ResolvedAttendanceState(
      status: AttendanceShiftStatus.checkedInActive,
      record: active.record,
      checkInDateTime: active.checkInDateTime,
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
      );
    }
  }

  if (open.isNotEmpty) {
    final stale = open.first;
    return ResolvedAttendanceState(
      status: AttendanceShiftStatus.staleOpen,
      record: stale.record,
      checkInDateTime: stale.checkInDateTime,
    );
  }

  return const ResolvedAttendanceState(status: AttendanceShiftStatus.noRecord);
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

/// Parses "HH:mm:ss" and "HH:mm:ss.fffffff" (any fractional digits).
/// Returns null when unparseable. Hours may be 0-23 (00:00:00 is valid).
({int hour, int minute, int second})? _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2 || parts.length > 3) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  int second = 0;
  if (parts.length == 3) {
    final secondsPart = parts[2].split('.').first;
    final parsedSeconds = int.tryParse(secondsPart);
    if (parsedSeconds == null) return null;
    second = parsedSeconds;
  }
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  if (second < 0 || second > 59) return null;
  return (hour: hour, minute: minute, second: second);
}

/// Combines a "yyyy-MM-dd" date with a time string. Null when unparseable.
DateTime? _combineDateAndTime(String dateValue, String timeValue) {
  final dateParts = dateValue.split('-');
  if (dateParts.length != 3) return null;
  final year = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final day = int.tryParse(dateParts[2]);
  final time = _parseTime(timeValue);
  if (year == null || month == null || day == null || time == null) {
    return null;
  }
  try {
    return DateTime(year, month, day, time.hour, time.minute, time.second);
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

/// Resolves a time-only departure to a full instant. When the departure
/// time-of-day is <= the check-in time-of-day, the departure belongs to
/// the next calendar day (overnight shift, e.g. 23:00 -> 08:00,
/// 14:00 -> 00:00). [attendanceTime] may be null (departure without a
/// recorded check-in); then the departure stays on the record's date.
DateTime? _resolveDeparture(
  String dateValue,
  String? attendanceTime,
  String departureTime,
) {
  final base = _combineDateAndTime(dateValue, departureTime);
  if (base == null) return null;
  if (attendanceTime == null) return base;
  final attendance = _parseTime(attendanceTime);
  final departure = _parseTime(departureTime);
  if (attendance == null || departure == null) return base;
  if (_compareTime(departure, attendance) <= 0) {
    return base.add(const Duration(days: 1));
  }
  return base;
}
