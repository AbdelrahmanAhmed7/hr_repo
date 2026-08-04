// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveBalanceModel _$LeaveBalanceModelFromJson(Map<String, dynamic> json) =>
    LeaveBalanceModel(
      annualLeaveBalance: (json['annualLeaveBalance'] as num).toInt(),
      annualLeaveUsed: (json['annualLeaveUsed'] as num).toInt(),
      annualLeaveRemaining: (json['annualLeaveRemaining'] as num).toInt(),
      casualLeaveUsed: (json['casualLeaveUsed'] as num).toInt(),
      sickLeaveBalance: (json['sickLeaveBalance'] as num).toInt(),
      sickLeaveUsed: (json['sickLeaveUsed'] as num).toInt(),
      maternity: (json['maternity'] as num).toInt(),
      paternity: (json['paternity'] as num).toInt(),
      hajj: (json['hajj'] as num).toInt(),
      exam: (json['exam'] as num).toInt(),
      paid: (json['paid'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LeaveBalanceModelToJson(LeaveBalanceModel instance) =>
    <String, dynamic>{
      'annualLeaveBalance': instance.annualLeaveBalance,
      'annualLeaveUsed': instance.annualLeaveUsed,
      'annualLeaveRemaining': instance.annualLeaveRemaining,
      'casualLeaveUsed': instance.casualLeaveUsed,
      'sickLeaveBalance': instance.sickLeaveBalance,
      'sickLeaveUsed': instance.sickLeaveUsed,
      'maternity': instance.maternity,
      'paternity': instance.paternity,
      'hajj': instance.hajj,
      'exam': instance.exam,
      'paid': instance.paid,
    };
