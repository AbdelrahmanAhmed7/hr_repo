// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetingResponseModel _$MeetingResponseModelFromJson(
  Map<String, dynamic> json,
) => MeetingResponseModel(
  items: (json['items'] as List<dynamic>)
      .map((e) => MeetingModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  pageNumber: (json['pageNumber'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalCount: (json['totalCount'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$MeetingResponseModelToJson(
  MeetingResponseModel instance,
) => <String, dynamic>{
  'items': instance.items,
  'pageNumber': instance.pageNumber,
  'pageSize': instance.pageSize,
  'totalCount': instance.totalCount,
  'totalPages': instance.totalPages,
};
