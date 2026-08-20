import 'package:json_annotation/json_annotation.dart';

part 'department_model.g.dart';

@JsonSerializable()
class DepartmentModel {
  final int id;
  final String name;

  const DepartmentModel({required this.id, required this.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) =>
      _$DepartmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentModelToJson(this);
}