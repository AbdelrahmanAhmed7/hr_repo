import 'package:json_annotation/json_annotation.dart';

part 'update_leave_status_response.g.dart';

@JsonSerializable()
class UpdateLeaveStatusResponse {
  final int id;
  final String status;
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  const UpdateLeaveStatusResponse({
    required this.id,
    required this.status,
    this.rejectionReason,
  });

  factory UpdateLeaveStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateLeaveStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateLeaveStatusResponseToJson(this);
}
