import 'package:json_annotation/json_annotation.dart';

part 'update_permission_status_response.g.dart';

@JsonSerializable()
class UpdatePermissionStatusResponse {
  final int id;
  final String status; // "Pending", "Approved", "Rejected"
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  UpdatePermissionStatusResponse({
    required this.id,
    required this.status,
    this.rejectionReason,
  });

  factory UpdatePermissionStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdatePermissionStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePermissionStatusResponseToJson(this);
}
