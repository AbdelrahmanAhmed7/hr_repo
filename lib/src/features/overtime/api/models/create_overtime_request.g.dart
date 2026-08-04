// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_overtime_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOvertimeRequest _$CreateOvertimeRequestFromJson(
  Map<String, dynamic> json,
) => CreateOvertimeRequest(
  date: json['date'] as String,
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
  reason: json['reason'] as String,
);

Map<String, dynamic> _$CreateOvertimeRequestToJson(
  CreateOvertimeRequest instance,
) => <String, dynamic>{
  'date': instance.date,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'reason': instance.reason,
};
