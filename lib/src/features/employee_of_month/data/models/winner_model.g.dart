// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'winner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WinnerModel _$WinnerModelFromJson(Map<String, dynamic> json) => WinnerModel(
  id: (json['id'] as num).toInt(),
  userId: json['userId'] as String,
  fullNameAr: json['fullNameAr'] as String,
  fullNameEn: json['fullNameEn'] as String,
  imageUrl: json['imageUrl'] as String?,
  departmentId: (json['departmentId'] as num).toInt(),
  departmentName: json['departmentName'] as String,
  month: (json['month'] as num).toInt(),
  year: (json['year'] as num).toInt(),
  voteCount: (json['voteCount'] as num).toInt(),
);

Map<String, dynamic> _$WinnerModelToJson(WinnerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'fullNameAr': instance.fullNameAr,
      'fullNameEn': instance.fullNameEn,
      'imageUrl': instance.imageUrl,
      'departmentId': instance.departmentId,
      'departmentName': instance.departmentName,
      'month': instance.month,
      'year': instance.year,
      'voteCount': instance.voteCount,
    };
