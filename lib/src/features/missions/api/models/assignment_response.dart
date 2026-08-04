import 'package:json_annotation/json_annotation.dart';

part 'assignment_response.g.dart';

@JsonSerializable()
class AssignmentResponse {
  final int id;
  @JsonKey(name: 'userId')
  final String userId;
  final String where;
  @JsonKey(name: 'startDate')
  final String startDate; // Format: YYYY-MM-DD
  @JsonKey(name: 'startTime')
  final String startTime; // Format: HH:mm:ss
  @JsonKey(name: 'endTime')
  final String endTime; // Format: HH:mm:ss
  final String reason;
  @JsonKey(name: 'createdAt')
  final String createdAt; // ISO 8601 format
  final String status; // "Pending", "Approved", "Rejected"
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  AssignmentResponse({
    required this.id,
    required this.userId,
    required this.where,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  factory AssignmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AssignmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentResponseToJson(this);
}