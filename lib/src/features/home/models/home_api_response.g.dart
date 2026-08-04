// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeApiResponse _$HomeApiResponseFromJson(Map<String, dynamic> json) =>
    HomeApiResponse(
      greeting: json['greeting'] as String,
      fullNameAr: json['fullNameAr'] as String?,
      fullNameEn: json['fullNameEn'] as String?,
      jobTitle: json['jobTitle'] as String?,
      departmentName: json['departmentName'] as String?,
      imageUrl: _cleanImageUrl(json['imageUrl'] as String?),
      todayAttendanceTime: json['todayAttendanceTime'] as String?,
      todayDepartureTime: json['todayDepartureTime'] as String?,
      allRequests: (json['allRequests'] as List<dynamic>)
          .map((e) => HomeRequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingRequests: (json['pendingRequests'] as List<dynamic>)
          .map((e) => HomeRequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptedRequests: (json['acceptedRequests'] as List<dynamic>)
          .map((e) => HomeRequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      rejectedRequests: (json['rejectedRequests'] as List<dynamic>)
          .map((e) => HomeRequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HomeApiResponseToJson(HomeApiResponse instance) =>
    <String, dynamic>{
      'greeting': instance.greeting,
      'fullNameAr': instance.fullNameAr,
      'fullNameEn': instance.fullNameEn,
      'jobTitle': instance.jobTitle,
      'departmentName': instance.departmentName,
      'imageUrl': instance.imageUrl,
      'todayAttendanceTime': instance.todayAttendanceTime,
      'todayDepartureTime': instance.todayDepartureTime,
      'allRequests': instance.allRequests,
      'pendingRequests': instance.pendingRequests,
      'acceptedRequests': instance.acceptedRequests,
      'rejectedRequests': instance.rejectedRequests,
    };

HomeRequestItem _$HomeRequestItemFromJson(Map<String, dynamic> json) =>
    HomeRequestItem(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      userId: json['userId'] as String?,
      date: json['date'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      where: json['where'] as String?,
      reason: json['reason'] as String?,
      leaveType: json['leaveType'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$HomeRequestItemToJson(HomeRequestItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'createdAt': instance.createdAt,
      'status': instance.status,
      'userId': instance.userId,
      'date': instance.date,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'where': instance.where,
      'reason': instance.reason,
      'leaveType': instance.leaveType,
      'rejectionReason': instance.rejectionReason,
    };
