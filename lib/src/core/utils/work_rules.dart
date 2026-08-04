import 'package:flutter/material.dart';

enum LatePenalty {
  none,
  quarterDay,
  halfDay,
  fullDay,
}

class WorkRules {
  /// Official working hours: 09:00 -> 17:00 (8 hours).
  static const TimeOfDay start = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay end = TimeOfDay(hour: 17, minute: 0);
  static const double standardHoursPerDay = 8.0;

  /// Grace period: up to 09:16 (inclusive) no deduction.
  static const TimeOfDay lateGraceUntil = TimeOfDay(hour: 9, minute: 16);

  /// After 09:16 and up to 09:31 (inclusive): quarter day deduction.
  /// After 09:31: half day deduction.
  static const TimeOfDay quarterDayUntil = TimeOfDay(hour: 9, minute: 31);

  /// After 10:00 (inclusive): full day deduction.
  static const TimeOfDay fullDayFrom = TimeOfDay(hour: 10, minute: 0);

  static DateTime atStartOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, start.hour, start.minute);

  static DateTime atEndOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, end.hour, end.minute);

  /// Returns worked hours as double (e.g. 8.5).
  static double workedHours(DateTime checkIn, DateTime checkOut) {
    final minutes = checkOut.difference(checkIn).inMinutes;
    return minutes <= 0 ? 0 : minutes / 60.0;
  }

  static double regularHours(double worked) =>
      worked <= 0 ? 0 : (worked > standardHoursPerDay ? standardHoursPerDay : worked);

  static double overtimeHours(double worked) =>
      worked <= standardHoursPerDay ? 0 : (worked - standardHoursPerDay);

  /// Minutes late relative to 09:00; 0 if on time/early.
  static int lateMinutes(DateTime checkIn) {
    final startDt = atStartOfDay(checkIn);
    final diff = checkIn.difference(startDt).inMinutes;
    return diff <= 0 ? 0 : diff;
  }

  static int _minutesFromStart(TimeOfDay t) => (t.hour - start.hour) * 60 + (t.minute - start.minute);

  /// Returns the lateness penalty based on check-in time:
  /// - <= 09:16 : none
  /// - 09:17..09:31 : quarter day
  /// - 09:32..09:59 : half day
  /// - >= 10:00 : full day
  static LatePenalty latePenalty(DateTime checkIn) {
    final late = lateMinutes(checkIn);
    if (late <= _minutesFromStart(lateGraceUntil)) return LatePenalty.none;
    if (late <= _minutesFromStart(quarterDayUntil)) return LatePenalty.quarterDay;
    if (late >= _minutesFromStart(fullDayFrom)) return LatePenalty.fullDay;
    return LatePenalty.halfDay;
  }

  /// Deduction fraction of the day (0, 0.25, 0.5, 1.0).
  static double deductionFraction(DateTime checkIn) {
    switch (latePenalty(checkIn)) {
      case LatePenalty.none:
        return 0;
      case LatePenalty.quarterDay:
        return 0.25;
      case LatePenalty.halfDay:
        return 0.5;
      case LatePenalty.fullDay:
        return 1.0;
    }
  }
}