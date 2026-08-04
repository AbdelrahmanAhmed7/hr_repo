import 'package:json_annotation/json_annotation.dart';

part 'update_leave_status_request.g.dart';

@JsonSerializable()
class UpdateLeaveStatusRequest {
  final int status;
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  const UpdateLeaveStatusRequest({
    required this.status,
    this.rejectionReason,
  });

  factory UpdateLeaveStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateLeaveStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateLeaveStatusRequestToJson(this);
}
