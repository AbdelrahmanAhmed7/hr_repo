// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nominee_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NomineeModel _$NomineeModelFromJson(Map<String, dynamic> json) => NomineeModel(
  userId: json['userId'] as String,
  fullNameAr: json['fullNameAr'] as String,
  fullNameEn: json['fullNameEn'] as String,
  imageUrl: json['imageUrl'] as String?,
  jobId: (json['jobId'] as num).toInt(),
  jobTitleName: json['jobTitleName'] as String,
);

Map<String, dynamic> _$NomineeModelToJson(NomineeModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullNameAr': instance.fullNameAr,
      'fullNameEn': instance.fullNameEn,
      'imageUrl': instance.imageUrl,
      'jobId': instance.jobId,
      'jobTitleName': instance.jobTitleName,
    };
