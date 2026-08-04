import 'package:json_annotation/json_annotation.dart';

part 'leave_balance_model.g.dart';

@JsonSerializable()
class LeaveBalanceModel {
  @JsonKey(name: 'annualLeaveBalance')
  final int annualLeaveBalance;
  
  @JsonKey(name: 'annualLeaveUsed')
  final int annualLeaveUsed;
  
  @JsonKey(name: 'annualLeaveRemaining')
  final int annualLeaveRemaining;
  
  @JsonKey(name: 'casualLeaveUsed')
  final int casualLeaveUsed;
  
  @JsonKey(name: 'sickLeaveBalance')
  final int sickLeaveBalance;
  
  @JsonKey(name: 'sickLeaveUsed')
  final int sickLeaveUsed;
  
  @JsonKey(name: 'maternity')
  final int maternity;
  
  @JsonKey(name: 'paternity')
  final int paternity;
  
  @JsonKey(name: 'hajj')
  final int hajj;
  
  @JsonKey(name: 'exam')
  final int exam;

  @JsonKey(name: 'paid')
  final int paid;

  LeaveBalanceModel({
    required this.annualLeaveBalance,
    required this.annualLeaveUsed,
    required this.annualLeaveRemaining,
    required this.casualLeaveUsed,
    required this.sickLeaveBalance,
    required this.sickLeaveUsed,
    required this.maternity,
    required this.paternity,
    required this.hajj,
    required this.exam,
    this.paid = 0,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveBalanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveBalanceModelToJson(this);
}
