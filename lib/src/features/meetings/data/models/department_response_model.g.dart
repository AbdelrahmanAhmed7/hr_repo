// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepartmentResponseModel _$DepartmentResponseModelFromJson(
  Map<String, dynamic> json,
) => DepartmentResponseModel(
  items: (json['items'] as List<dynamic>)
      .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  pageNumber: (json['pageNumber'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalCount: (json['totalCount'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$DepartmentResponseModelToJson(
  DepartmentResponseModel instance,
) => <String, dynamic>{
  'items': instance.items,
  'pageNumber': instance.pageNumber,
  'pageSize': instance.pageSize,
  'totalCount': instance.totalCount,
  'totalPages': instance.totalPages,
};
