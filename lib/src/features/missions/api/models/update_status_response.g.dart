// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateStatusResponse _$UpdateStatusResponseFromJson(
  Map<String, dynamic> json,
) => UpdateStatusResponse(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String,
  rejectionReason: json['rejectionReason'] as String?,
);

Map<String, dynamic> _$UpdateStatusResponseToJson(
  UpdateStatusResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'rejectionReason': instance.rejectionReason,
};
