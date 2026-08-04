// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_submission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveSubmissionModel _$LeaveSubmissionModelFromJson(
  Map<String, dynamic> json,
) => LeaveSubmissionModel(
  id: (json['Id'] as num?)?.toInt() ?? 0,
  userId: json['UserId'] as String,
  startDate: json['StartDate'] as String,
  endDate: json['EndDate'] as String,
  reason: json['Reason'] as String,
  createdAt: json['CreatedAt'] as String,
  status: json['Status'] as String? ?? "Pending",
  rejectionReason: json['RejectionReason'] as String?,
  leaveType: json['LeaveType'] as String,
  medicalReportUrl: json['MedicalReportUrl'] as String?,
);

Map<String, dynamic> _$LeaveSubmissionModelToJson(
  LeaveSubmissionModel instance,
) => <String, dynamic>{
  'Id': instance.id,
  'UserId': instance.userId,
  'StartDate': instance.startDate,
  'EndDate': instance.endDate,
  'Reason': instance.reason,
  'CreatedAt': instance.createdAt,
  'Status': instance.status,
  'RejectionReason': instance.rejectionReason,
  'LeaveType': instance.leaveType,
  'MedicalReportUrl': instance.medicalReportUrl,
};
