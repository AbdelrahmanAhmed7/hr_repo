// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_overtime_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOvertimeStatusResponse _$UpdateOvertimeStatusResponseFromJson(
  Map<String, dynamic> json,
) => UpdateOvertimeStatusResponse(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String,
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$UpdateOvertimeStatusResponseToJson(
  UpdateOvertimeStatusResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
