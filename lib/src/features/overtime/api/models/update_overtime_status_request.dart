import 'package:json_annotation/json_annotation.dart';

part 'update_overtime_status_request.g.dart';

@JsonSerializable()
class UpdateOvertimeStatusRequest {
  final int status;
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  const UpdateOvertimeStatusRequest({
    required this.status,
    this.rejectionReason,
  });

  factory UpdateOvertimeStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateOvertimeStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOvertimeStatusRequestToJson(this);
}
