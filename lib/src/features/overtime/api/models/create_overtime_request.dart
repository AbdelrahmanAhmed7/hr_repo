import 'package:json_annotation/json_annotation.dart';

part 'create_overtime_request.g.dart';

@JsonSerializable()
class CreateOvertimeRequest {
  final String date;
  final String startTime;
  final String endTime;
  final String reason;

  CreateOvertimeRequest({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  factory CreateOvertimeRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOvertimeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOvertimeRequestToJson(this);
}
