// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentRequest _$AssignmentRequestFromJson(Map<String, dynamic> json) =>
    AssignmentRequest(
      where: json['where'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$AssignmentRequestToJson(AssignmentRequest instance) =>
    <String, dynamic>{
      'where': instance.where,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'reason': instance.reason,
    };
