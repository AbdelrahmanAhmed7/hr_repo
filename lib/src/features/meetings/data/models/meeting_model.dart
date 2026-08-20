import 'package:json_annotation/json_annotation.dart';

part 'meeting_model.g.dart';

@JsonSerializable()
class MeetingModel {
  final int id;
  final String title;
  final String message;
  final String meetingDate;
  final String meetingTime;
  final String createdAt;
  final String createdByUserId;
  final String? targetDepartment;

  const MeetingModel({
    required this.id,
    required this.title,
    required this.message,
    required this.meetingDate,
    required this.meetingTime,
    required this.createdAt,
    required this.createdByUserId,
    this.targetDepartment,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingModelFromJson(json);

  Map<String, dynamic> toJson() => _$MeetingModelToJson(this);
}