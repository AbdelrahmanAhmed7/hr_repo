import 'package:flutter/material.dart';

enum PendingRequestType {
  leave,
  permission,
  mission,
}

class PendingRequest {
  final String id;
  final PendingRequestType type;
  final dynamic requestData;
  final String employeeName;
  final String employeeId;
  final DateTime submittedDate;

  PendingRequest({
    required this.id,
    required this.type,
    required this.requestData,
    required this.employeeName,
    required this.employeeId,
    required this.submittedDate,
  });

  String get typeText {
    switch (type) {
      case PendingRequestType.leave:
        return 'إجازة';
      case PendingRequestType.permission:
        return 'إذن خروج';
      case PendingRequestType.mission:
        return 'مأمورية';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case PendingRequestType.leave:
        return Icons.calendar_today_rounded;
      case PendingRequestType.permission:
        return Icons.access_time_rounded;
      case PendingRequestType.mission:
        return Icons.assignment_rounded;
    }
  }

  Color get typeColor {
    switch (type) {
      case PendingRequestType.leave:
        return const Color(0xFF2196F3); // Blue
      case PendingRequestType.permission:
        return const Color(0xFFFF9800); // Orange
      case PendingRequestType.mission:
        return const Color(0xFF9C27B0); // Purple
    }
  }
}





