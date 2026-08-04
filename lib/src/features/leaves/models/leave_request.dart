import 'package:flutter/material.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected,
}

enum LeaveType {
  annual,
  casual,
  sick,
}

class LeaveRequest {
  final String id;
  final LeaveType type;
  final LeaveStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime submittedDate;
  final String reason;
  final String? rejectionReason;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.submittedDate,
    required this.reason,
    this.rejectionReason,
  });

  int get numberOfDays {
    return endDate.difference(startDate).inDays + 1;
  }

  String get dateRangeText {
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  String get typeText {
    switch (type) {
      case LeaveType.annual:
        return 'إجازة سنوية';
      case LeaveType.casual:
        return 'إجازة عارضة';
      case LeaveType.sick:
        return 'إجازة مرضية';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case LeaveType.annual:
        return Icons.calendar_today_rounded;
      case LeaveType.casual:
        return Icons.event_available_rounded;
      case LeaveType.sick:
        return Icons.medical_services_rounded;
    }
  }

  String get statusText {
    switch (status) {
      case LeaveStatus.pending:
        return 'معلقة';
      case LeaveStatus.approved:
        return 'موافق عليها';
      case LeaveStatus.rejected:
        return 'مرفوضة';
    }
  }

  Color get statusColor {
    switch (status) {
      case LeaveStatus.pending:
        return const Color(0xFFD97706); // warning
      case LeaveStatus.approved:
        return const Color(0xFF0F7D3E); // success
      case LeaveStatus.rejected:
        return const Color(0xFFC41E3A); // error
    }
  }


}



