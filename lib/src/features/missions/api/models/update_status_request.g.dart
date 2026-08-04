// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateStatusRequest _$UpdateStatusRequestFromJson(Map<String, dynamic> json) =>
    UpdateStatusRequest(
      status: (json['status'] as num).toInt(),
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$UpdateStatusRequestToJson(
  UpdateStatusRequest instance,
) => <String, dynamic>{
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
