import 'package:json_annotation/json_annotation.dart';

part 'update_status_response.g.dart';

@JsonSerializable()
class UpdateStatusResponse {
  final int id;
  final String status; // "Pending", "Approved", "Rejected"
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;

  UpdateStatusResponse({
    required this.id,
    required this.status,
    this.rejectionReason,
  });

  factory UpdateStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateStatusResponseToJson(this);
}
