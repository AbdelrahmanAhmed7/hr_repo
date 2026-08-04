import 'package:json_annotation/json_annotation.dart';

part 'overtime_response.g.dart';

@JsonSerializable()
class OvertimeResponse {
  final int id;
  final String userId;
  final String date;
  final String startTime;
  final String endTime;
  final double totalHours;
  final double hourlyRate;
  final double amount;
  final String reason;
  final String createdAt;
  final String status;
  final String? rejectionReason;

  OvertimeResponse({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.hourlyRate,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
  });

  factory OvertimeResponse.fromJson(Map<String, dynamic> json) =>
      _$OvertimeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OvertimeResponseToJson(this);
}
