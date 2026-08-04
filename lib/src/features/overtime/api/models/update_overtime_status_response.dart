import 'package:json_annotation/json_annotation.dart';

part 'update_overtime_status_response.g.dart';

@JsonSerializable()
class UpdateOvertimeStatusResponse {
  final int id;
  final String status;
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  const UpdateOvertimeStatusResponse({
    required this.id,
    required this.status,
    this.rejectionReason,
  });

  factory UpdateOvertimeStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateOvertimeStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOvertimeStatusResponseToJson(this);
}
