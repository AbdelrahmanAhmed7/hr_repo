import 'package:json_annotation/json_annotation.dart';

part 'permission_response.g.dart';

@JsonSerializable()
class PermissionResponse {
  final int id;
  @JsonKey(name: 'userId')
  final String userId;
  final String date; // Format: YYYY-MM-DD
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

  PermissionResponse({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  factory PermissionResponse.fromJson(Map<String, dynamic> json) =>
      _$PermissionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionResponseToJson(this);
}
