// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PermissionRequest _$PermissionRequestFromJson(Map<String, dynamic> json) =>
    PermissionRequest(
      date: json['Date'] as String,
      startTime: json['StartTime'] as String,
      endTime: json['EndTime'] as String,
      reason: json['Reason'] as String,
    );

Map<String, dynamic> _$PermissionRequestToJson(PermissionRequest instance) =>
    <String, dynamic>{
      'Date': instance.date,
      'StartTime': instance.startTime,
      'EndTime': instance.endTime,
      'Reason': instance.reason,
    };
