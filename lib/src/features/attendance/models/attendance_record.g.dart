// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceRecord _$AttendanceRecordFromJson(Map<String, dynamic> json) =>
    AttendanceRecord(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      date: json['date'] as String,
      attendanceTime: json['attendanceTime'] as String?,
      departureTime: json['departureTime'] as String?,
      deviceType: (json['deviceType'] as num).toInt(),
      location: json['location'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$AttendanceRecordToJson(AttendanceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date,
      'attendanceTime': instance.attendanceTime,
      'departureTime': instance.departureTime,
      'deviceType': instance.deviceType,
      'location': instance.location,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
