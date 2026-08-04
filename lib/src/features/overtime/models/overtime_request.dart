import 'package:flutter/material.dart';

enum OvertimeRequestStatus {
  pending,
  approved,
  rejected,
}

class OvertimeRequest {
  final String id;
  final String userId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double totalHours;
  final double hourlyRate;
  final double amount;
  final String reason;
  final DateTime createdAt;
  final OvertimeRequestStatus status;
  final String? rejectionReason;

  const OvertimeRequest({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.hourlyRate,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  String get statusText {
    switch (status) {
      case OvertimeRequestStatus.pending:
        return 'قيد الانتظار';
      case OvertimeRequestStatus.approved:
        return 'موافق عليه';
      case OvertimeRequestStatus.rejected:
        return 'مرفوض';
    }
  }

  Color get statusColor {
    switch (status) {
      case OvertimeRequestStatus.pending:
        return const Color(0xFFD97706);
      case OvertimeRequestStatus.approved:
        return const Color(0xFF0F7D3E);
      case OvertimeRequestStatus.rejected:
        return const Color(0xFFC41E3A);
    }
  }

  String get durationText {
    if (totalHours <= 0) return '--';
    final wholeHours = totalHours.floor();
    final minutes = ((totalHours - wholeHours) * 60).round();
    if (minutes == 0) {
      return wholeHours == 1 ? '1 ساعة' : '$wholeHours ساعات';
    }
    if (wholeHours == 0) {
      return '$minutes دقيقة';
    }
    return '$wholeHours س و $minutes د';
  }

  String get timeRangeText => '${_formatTime(startTime)} - ${_formatTime(endTime)}';

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
