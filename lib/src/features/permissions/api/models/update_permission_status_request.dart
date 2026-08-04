import 'package:json_annotation/json_annotation.dart';

part 'update_permission_status_request.g.dart';

@JsonSerializable()
class UpdatePermissionStatusRequest {
  final int status; // 1 = Pending, 2 = Approved, 3 = Rejected
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  UpdatePermissionStatusRequest({
    required this.status,
    this.rejectionReason,
  });

  factory UpdatePermissionStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePermissionStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePermissionStatusRequestToJson(this);
}
