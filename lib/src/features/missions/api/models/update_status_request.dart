import 'package:json_annotation/json_annotation.dart';

part 'update_status_request.g.dart';

@JsonSerializable()
class UpdateStatusRequest {
  final int status; // 1 = Pending, 2 = Approved, 3 = Rejected
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  UpdateStatusRequest({
    required this.status,
    this.rejectionReason,
  });

  factory UpdateStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateStatusRequestToJson(this);
}