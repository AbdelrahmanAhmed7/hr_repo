// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_permission_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePermissionStatusResponse _$UpdatePermissionStatusResponseFromJson(
  Map<String, dynamic> json,
) => UpdatePermissionStatusResponse(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String,
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$UpdatePermissionStatusResponseToJson(
  UpdatePermissionStatusResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
