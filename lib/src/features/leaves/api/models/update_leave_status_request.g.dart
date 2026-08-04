// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_leave_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLeaveStatusRequest _$UpdateLeaveStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdateLeaveStatusRequest(
  status: (json['status'] as num).toInt(),
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$UpdateLeaveStatusRequestToJson(
  UpdateLeaveStatusRequest instance,
) => <String, dynamic>{
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
