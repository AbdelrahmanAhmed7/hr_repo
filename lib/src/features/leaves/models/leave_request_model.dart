import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'leave_request_model.g.dart';

@JsonSerializable()
class LeaveRequestModel {
  @JsonKey(name: 'id')
  final int id;
  
  @JsonKey(name: 'userId')
  final String userId;
  
  @JsonKey(name: 'startDate')
  final String startDate;
  
  @JsonKey(name: 'endDate')
  final String endDate;
  
  @JsonKey(name: 'reason')
  final String? reason;
  
  @JsonKey(name: 'createdAt')
  final String createdAt;
  
  @JsonKey(name: 'status')
  final String status;
  
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;
  
  @JsonKey(name: 'leaveType')
  final String leaveType;
  
  @JsonKey(name: 'medicalReportUrl')
  final String? medicalReportUrl;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
    required this.leaveType,
    this.medicalReportUrl,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveRequestModelToJson(this);
  
  // Helpers
  DateTime get startDateDateTime => DateTime.parse(startDate);
  DateTime get endDateDateTime => DateTime.parse(endDate);
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  
  // UI Helpers (mimicking the old LeaveRequest model)
  DateTime get submittedDate => createdAtDateTime;

  int get numberOfDays {
    return endDateDateTime.difference(startDateDateTime).inDays + 1;
  }

  String get dateRangeText {
    return '${startDateDateTime.day}/${startDateDateTime.month}/${startDateDateTime.year} - ${endDateDateTime.day}/${endDateDateTime.month}/${endDateDateTime.year}';
  }

  String get typeText {
    // Basic mapping, ideally this should come from LeaveTypeModel or localization
    switch (leaveType.toLowerCase()) {
      case 'annual':
        return 'إجازة سنوية';
      case 'casual':
        return 'إجازة عرضية';
      case 'sick':
        return 'إجازة مرضية';
      case 'maternity':
        return 'إجازة وضع';
      case 'paternity':
        return 'إجازة أبوة';
      case 'hajj':
        return 'إجازة حج';
      case 'exam':
        return 'إجازة امتحانات';
      default:
        return leaveType;
    }
  }

  IconData get typeIcon {
    switch (leaveType.toLowerCase()) {
      case 'annual':
        return Icons.calendar_today_rounded;
      case 'casual':
        return Icons.event_available_rounded;
      case 'sick':
        return Icons.medical_services_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'معلقة';
      case 'approved':
        return 'موافق عليها';
      case 'rejected':
        return 'مرفوضة';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706); // warning
      case 'approved':
        return const Color(0xFF0F7D3E); // success
      case 'rejected':
        return const Color(0xFFC41E3A); // error
      default:
        return Colors.grey;
    }
  }
}
