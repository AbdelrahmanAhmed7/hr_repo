// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentResponse _$AssignmentResponseFromJson(Map<String, dynamic> json) =>
    AssignmentResponse(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      where: json['where'] as String,
      startDate: json['startDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      reason: json['reason'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$AssignmentResponseToJson(AssignmentResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'where': instance.where,
      'startDate': instance.startDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'reason': instance.reason,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'rejectionReason': instance.rejectionReason,
    };
