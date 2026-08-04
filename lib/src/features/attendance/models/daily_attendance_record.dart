import 'package:flutter/material.dart';
import '../../../core/utils/work_rules.dart';

enum AttendanceStatus {
  present,
  absent,
  leave,
  late,
  halfDay,
  weeklyOff,
}

class DailyAttendanceRecord {
  final String id;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final String? location;
  final double? workHours;
  final String? notes;

  DailyAttendanceRecord({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.location,
    this.workHours,
    this.notes,
  });

  double get regularHours {
    final worked = workHours ??
        ((checkInTime != null && checkOutTime != null)
            ? WorkRules.workedHours(checkInTime!, checkOutTime!)
            : 0);
    return WorkRules.regularHours(worked);
  }

  double get overtimeHours {
    final worked = workHours ??
        ((checkInTime != null && checkOutTime != null)
            ? WorkRules.workedHours(checkInTime!, checkOutTime!)
            : 0);
    return WorkRules.overtimeHours(worked);
  }

  LatePenalty get latePenalty {
    if (checkInTime == null) return LatePenalty.none;
    return WorkRules.latePenalty(checkInTime!);
  }

  double get deductionFraction {
    if (checkInTime == null) return 0;
    return WorkRules.deductionFraction(checkInTime!);
  }

  String get statusText {
    switch (status) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.leave:
        return 'إجازة';
      case AttendanceStatus.late:
        return 'متأخر';
      case AttendanceStatus.halfDay:
        return 'نصف يوم';
      case AttendanceStatus.weeklyOff:
        return 'إجازة أسبوعية';
    }
  }

  Color get statusColor {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF0F7D3E);
      case AttendanceStatus.absent:
        return const Color(0xFFC41E3A);
      case AttendanceStatus.leave:
        return const Color(0xFF4A90E2);
      case AttendanceStatus.late:
        return const Color(0xFFD97706);
      case AttendanceStatus.halfDay:
        return const Color(0xFF8C8C8C);
      case AttendanceStatus.weeklyOff:
        return const Color(0xFF8C8C8C);
    }
  }
}
