import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum PermissionStatus {
  pending,
  approved,
  rejected,
}

/// Kind of permission derived from its time.
/// Reference day is 9–5 (covers most employees); shift workers fall back
/// to the closest meaning (morning = late arrival, afternoon = early leave).
enum PermissionKind {
  lateArrival,
  earlyLeave,
  exit,
}

class PermissionRequest {
  final String id;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String reason;
  final PermissionStatus status;
  final DateTime submittedDate;
  final String? rejectionReason;

  PermissionRequest({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.status,
    required this.submittedDate,
    this.rejectionReason,
  });

  Duration get duration {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }

  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else if (hours > 0) {
      return '$hours ساعة';
    } else {
      return '$minutes دقيقة';
    }
  }

  String get dateText {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get timeRangeText {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  String get statusText {
    switch (status) {
      case PermissionStatus.pending:
        return 'معلقة';
      case PermissionStatus.approved:
        return 'موافق عليها';
      case PermissionStatus.rejected:
        return 'مرفوضة';
    }
  }

  Color get statusColor {
    switch (status) {
      case PermissionStatus.pending:
        return AppColors.warning;
      case PermissionStatus.approved:
        return AppColors.success;
      case PermissionStatus.rejected:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (kind) {
      case PermissionKind.lateArrival:
        return Icons.login_rounded;
      case PermissionKind.earlyLeave:
        return Icons.logout_rounded;
      case PermissionKind.exit:
        return Icons.output_outlined;
    }
  }

  /// Morning-only permission = late arrival, afternoon-only = early leave,
  /// anything spanning midday = regular exit permission.
  PermissionKind get kind {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= 12 * 60) return PermissionKind.lateArrival;
    if (startMinutes >= 14 * 60) return PermissionKind.earlyLeave;
    return PermissionKind.exit;
  }

  String get kindLabel {
    switch (kind) {
      case PermissionKind.lateArrival:
        return 'تأخير صباحي';
      case PermissionKind.earlyLeave:
        return 'انصراف مبكر';
      case PermissionKind.exit:
        return 'إذن خروج';
    }
  }

  Color get kindColor {
    switch (kind) {
      case PermissionKind.lateArrival:
        return AppColors.warning;
      case PermissionKind.earlyLeave:
        return AppColors.info;
      case PermissionKind.exit:
        return AppColors.primary;
    }
  }
}





