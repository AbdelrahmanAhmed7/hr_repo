import 'package:json_annotation/json_annotation.dart';

part 'leave_type_model.g.dart';

@JsonSerializable()
class LeaveTypeModel {
  @JsonKey(name: 'id')
  final int id;
  
  @JsonKey(name: 'name')
  final String name;
  
  @JsonKey(name: 'nameAr')
  final String nameAr;

  LeaveTypeModel({
    required this.id,
    required this.name,
    required this.nameAr,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveTypeModelFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveTypeModelToJson(this);
}
