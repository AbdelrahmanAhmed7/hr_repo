// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_permission_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePermissionStatusRequest _$UpdatePermissionStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdatePermissionStatusRequest(
  status: (json['status'] as num).toInt(),
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$UpdatePermissionStatusRequestToJson(
  UpdatePermissionStatusRequest instance,
) => <String, dynamic>{
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
