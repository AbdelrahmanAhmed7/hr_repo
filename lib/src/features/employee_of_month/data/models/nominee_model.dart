import 'package:json_annotation/json_annotation.dart';

part 'nominee_model.g.dart';

@JsonSerializable()
class NomineeModel {
  final String userId;
  final String fullNameAr;
  final String fullNameEn;
  final String? imageUrl;
  final int jobId;
  final String jobTitleName;

  const NomineeModel({
    required this.userId,
    required this.fullNameAr,
    required this.fullNameEn,
    this.imageUrl,
    required this.jobId,
    required this.jobTitleName,
  });

  factory NomineeModel.fromJson(Map<String, dynamic> json) =>
      _$NomineeModelFromJson(json);

  Map<String, dynamic> toJson() => _$NomineeModelToJson(this);
}
