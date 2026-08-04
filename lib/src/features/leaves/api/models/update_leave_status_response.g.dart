// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_leave_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLeaveStatusResponse _$UpdateLeaveStatusResponseFromJson(
  Map<String, dynamic> json,
) => UpdateLeaveStatusResponse(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String,
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$UpdateLeaveStatusResponseToJson(
  UpdateLeaveStatusResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
