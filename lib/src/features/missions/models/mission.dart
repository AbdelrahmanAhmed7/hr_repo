import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/assignment_response.dart';

enum MissionStatus {
  pending,
  approved,
  rejected,
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime submittedDate;
  final String? rejectionReason;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.submittedDate,
    this.rejectionReason,
  });

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    MissionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? submittedDate,
    String? rejectionReason,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      submittedDate: submittedDate ?? this.submittedDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  int get numberOfDays {
    return endDate.difference(startDate).inDays + 1;
  }

  String get dateRangeText {
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  String get statusText {
    switch (status) {
      case MissionStatus.pending:
        return 'معلقة';
      case MissionStatus.approved:
        return 'موافق عليها';
      case MissionStatus.rejected:
        return 'مرفوضة';
    }
  }

  Color get statusColor {
    switch (status) {
      case MissionStatus.pending:
        return AppColors.warning; // أصفر
      case MissionStatus.approved:
        return AppColors.success; // أخضر
      case MissionStatus.rejected:
        return AppColors.error; // أحمر
    }
  }

  IconData get icon {
    return Icons.assignment_rounded;
  }

  /// Convert AssignmentResponse from API to Mission model
  factory Mission.fromAssignmentResponse(AssignmentResponse response) {
    // Parse startDate + startTime to DateTime
    final startDateTime = _parseDateTime(response.startDate, response.startTime);
    
    // Parse startDate + endTime to DateTime
    final endDateTime = _parseDateTime(response.startDate, response.endTime);
    
    // Parse createdAt to DateTime
    DateTime submittedDate;
    try {
      submittedDate = DateTime.parse(response.createdAt);
    } catch (e) {
      submittedDate = DateTime.now();
    }
    
    // Map status string to enum
    MissionStatus status;
    final statusLower = response.status.toLowerCase();
    if (statusLower == 'approved') {
      status = MissionStatus.approved;
    } else if (statusLower == 'rejected') {
      status = MissionStatus.rejected;
    } else {
      status = MissionStatus.pending;
    }
    
    return Mission(
      id: response.id.toString(),
      title: response.where,
      description: response.reason,
      status: status,
      startDate: startDateTime,
      endDate: endDateTime,
      submittedDate: submittedDate,
      rejectionReason: response.rejectionReason,
    );
  }
  
  /// Helper method to parse date (YYYY-MM-DD) + time (HH:mm:ss) to DateTime
  static DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Parse date: YYYY-MM-DD
      final dateParts = dateStr.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      
      // Parse time: HH:mm:ss
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
      
      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      // Fallback to current date/time if parsing fails
      return DateTime.now();
    }
  }


}
