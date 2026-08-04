// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_overtime_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOvertimeStatusRequest _$UpdateOvertimeStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdateOvertimeStatusRequest(
  status: (json['status'] as num).toInt(),
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$UpdateOvertimeStatusRequestToJson(
  UpdateOvertimeStatusRequest instance,
) => <String, dynamic>{
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
