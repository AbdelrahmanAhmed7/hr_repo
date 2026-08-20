// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetingModel _$MeetingModelFromJson(Map<String, dynamic> json) => MeetingModel(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  message: json['message'] as String,
  meetingDate: json['meetingDate'] as String,
  meetingTime: json['meetingTime'] as String,
  createdAt: json['createdAt'] as String,
  createdByUserId: json['createdByUserId'] as String,
  targetDepartment: json['targetDepartment'] as String?,
);

Map<String, dynamic> _$MeetingModelToJson(MeetingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'meetingDate': instance.meetingDate,
      'meetingTime': instance.meetingTime,
      'createdAt': instance.createdAt,
      'createdByUserId': instance.createdByUserId,
      'targetDepartment': instance.targetDepartment,
    };
