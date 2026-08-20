import 'package:json_annotation/json_annotation.dart';

import 'department_model.dart';

part 'department_response_model.g.dart';

@JsonSerializable()
class DepartmentResponseModel {
  final List<DepartmentModel> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const DepartmentResponseModel({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory DepartmentResponseModel.fromJson(Map<String, dynamic> json) =>
      _$DepartmentResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentResponseModelToJson(this);
}