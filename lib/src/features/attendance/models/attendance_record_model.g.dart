// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceRecordModel _$AttendanceRecordModelFromJson(
  Map<String, dynamic> json,
) => AttendanceRecordModel(
  id: (json['id'] as num).toInt(),
  employeeName: json['employeeName'] as String,
  machineCode: json['machineCode'] as String?,
  date: json['date'] as String,
  dayOfWeek: json['dayOfWeek'] as String,
  attendanceTime: json['attendanceTime'] as String?,
  departureTime: json['departureTime'] as String?,
  deviceType: (json['deviceType'] as num?)?.toInt(),
  location: json['location'] as String?,
  locationId: (json['locationId'] as num?)?.toInt(),
  isClosed: json['isClosed'] as bool,
  departureSource: json['departureSource'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$AttendanceRecordModelToJson(
  AttendanceRecordModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'employeeName': instance.employeeName,
  'machineCode': instance.machineCode,
  'date': instance.date,
  'dayOfWeek': instance.dayOfWeek,
  'attendanceTime': instance.attendanceTime,
  'departureTime': instance.departureTime,
  'deviceType': instance.deviceType,
  'location': instance.location,
  'locationId': instance.locationId,
  'isClosed': instance.isClosed,
  'departureSource': instance.departureSource,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
