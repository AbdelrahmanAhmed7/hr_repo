import 'package:json_annotation/json_annotation.dart';

part 'leave_submission_model.g.dart';

@JsonSerializable()
class LeaveSubmissionModel {
  @JsonKey(name: 'Id')
  final int id;
  
  @JsonKey(name: 'UserId')
  final String userId;
  
  @JsonKey(name: 'StartDate')
  final String startDate;
  
  @JsonKey(name: 'EndDate')
  final String endDate;
  
  @JsonKey(name: 'Reason')
  final String reason;
  
  @JsonKey(name: 'CreatedAt')
  final String createdAt;
  
  @JsonKey(name: 'Status')
  final String status;
  
  @JsonKey(name: 'RejectionReason')
  final String? rejectionReason;
  
  @JsonKey(name: 'LeaveType')
  final String leaveType;
  
  @JsonKey(name: 'MedicalReportUrl')
  final String? medicalReportUrl;

  LeaveSubmissionModel({
    this.id = 0,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdAt,
    this.status = "Pending",
    this.rejectionReason,
    required this.leaveType,
    this.medicalReportUrl,
  });

  factory LeaveSubmissionModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveSubmissionModelFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveSubmissionModelToJson(this);
}
