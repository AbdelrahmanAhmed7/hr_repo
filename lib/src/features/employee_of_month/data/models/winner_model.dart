import 'package:json_annotation/json_annotation.dart';

part 'winner_model.g.dart';

@JsonSerializable()
class WinnerModel {
  final int id;
  final String userId;
  final String fullNameAr;
  final String fullNameEn;
  final String? imageUrl;
  final int departmentId;
  final String departmentName;
  final int month;
  final int year;
  final int voteCount;

  const WinnerModel({
    required this.id,
    required this.userId,
    required this.fullNameAr,
    required this.fullNameEn,
    this.imageUrl,
    required this.departmentId,
    required this.departmentName,
    required this.month,
    required this.year,
    required this.voteCount,
  });

  factory WinnerModel.fromJson(Map<String, dynamic> json) =>
      _$WinnerModelFromJson(json);

  Map<String, dynamic> toJson() => _$WinnerModelToJson(this);
}
