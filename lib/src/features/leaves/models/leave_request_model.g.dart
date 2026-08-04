// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveRequestModel _$LeaveRequestModelFromJson(Map<String, dynamic> json) =>
    LeaveRequestModel(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      leaveType: json['leaveType'] as String,
      medicalReportUrl: json['medicalReportUrl'] as String?,
    );

Map<String, dynamic> _$LeaveRequestModelToJson(LeaveRequestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'reason': instance.reason,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'rejectionReason': instance.rejectionReason,
      'leaveType': instance.leaveType,
      'medicalReportUrl': instance.medicalReportUrl,
    };
