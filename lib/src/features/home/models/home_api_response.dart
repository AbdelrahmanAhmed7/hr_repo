import 'package:json_annotation/json_annotation.dart';

part 'home_api_response.g.dart';

String? _cleanImageUrl(String? url) {
  if (url == null) return null;
  // Remove all backticks first, then trim whitespace
  final cleaned = url.replaceAll('`', '').trim();
  return cleaned.isEmpty ? null : cleaned;
}

@JsonSerializable()
class HomeApiResponse {
  final String greeting;
  final String? fullNameAr;
  final String? fullNameEn;
  final String? jobTitle;
  final String? departmentName;
  @JsonKey(fromJson: _cleanImageUrl)
  final String? imageUrl;
  final String? todayAttendanceTime;
  final String? todayDepartureTime;
  final List<HomeRequestItem> allRequests;
  final List<HomeRequestItem> pendingRequests;
  final List<HomeRequestItem> acceptedRequests;
  final List<HomeRequestItem> rejectedRequests;

  HomeApiResponse({
    required this.greeting,
    this.fullNameAr,
    this.fullNameEn,
    this.jobTitle,
    this.departmentName,
    this.imageUrl,
    this.todayAttendanceTime,
    this.todayDepartureTime,
    required this.allRequests,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.rejectedRequests,
  });

  factory HomeApiResponse.fromJson(Map<String, dynamic> json) =>
      _$HomeApiResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HomeApiResponseToJson(this);
}

@JsonSerializable()
class HomeRequestItem {
  final int id;
  final String type;
  final String createdAt;
  final String status;
  final String? userId;
  final String? date;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String? where;
  final String? reason;
  final String? leaveType;
  final String? rejectionReason;

  HomeRequestItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.status,
    this.userId,
    this.date,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.where,
    this.reason,
    this.leaveType,
    this.rejectionReason,
  });

  factory HomeRequestItem.fromJson(Map<String, dynamic> json) =>
      _$HomeRequestItemFromJson(json);

  Map<String, dynamic> toJson() => _$HomeRequestItemToJson(this);
}
