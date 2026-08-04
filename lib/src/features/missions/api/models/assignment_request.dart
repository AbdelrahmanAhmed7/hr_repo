import 'package:json_annotation/json_annotation.dart';

part 'assignment_request.g.dart';

@JsonSerializable()
class AssignmentRequest {
  final String where;
  @JsonKey(name: 'startDate')
  final String startDate; // Format: YYYY-MM-DD
  @JsonKey(name: 'endDate')
  final String endDate; // Format: YYYY-MM-DD
  @JsonKey(name: 'startTime')
  final String startTime; // Format: HH:mm:ss
  @JsonKey(name: 'endTime')
  final String endTime; // Format: HH:mm:ss
  final String reason;

  AssignmentRequest({
    required this.where,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  factory AssignmentRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignmentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentRequestToJson(this);
}
