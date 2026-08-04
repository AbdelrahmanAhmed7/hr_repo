// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overtime_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OvertimeResponse _$OvertimeResponseFromJson(Map<String, dynamic> json) =>
    OvertimeResponse(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      totalHours: (json['totalHours'] as num).toDouble(),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$OvertimeResponseToJson(OvertimeResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'totalHours': instance.totalHours,
      'hourlyRate': instance.hourlyRate,
      'amount': instance.amount,
      'reason': instance.reason,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'rejectionReason': instance.rejectionReason,
    };
