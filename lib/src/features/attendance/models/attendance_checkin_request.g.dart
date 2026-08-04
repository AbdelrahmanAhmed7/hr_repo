// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_checkin_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceCheckinRequest _$AttendanceCheckinRequestFromJson(
  Map<String, dynamic> json,
) => AttendanceCheckinRequest(
  fingerprintKey: json['fingerprintKey'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$AttendanceCheckinRequestToJson(
  AttendanceCheckinRequest instance,
) => <String, dynamic>{
  'fingerprintKey': instance.fingerprintKey,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
