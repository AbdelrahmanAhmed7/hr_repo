import 'package:json_annotation/json_annotation.dart';

part 'permission_request.g.dart';

@JsonSerializable()
class PermissionRequest {
  @JsonKey(name: 'Date')
  final String date; // Format: YYYY-MM-DD
  
  @JsonKey(name: 'StartTime')
  final String startTime; // Format: HH:mm:ss
  
  @JsonKey(name: 'EndTime')
  final String endTime; // Format: HH:mm:ss
  
  @JsonKey(name: 'Reason')
  final String reason; // Required

  PermissionRequest({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) =>
      _$PermissionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionRequestToJson(this);
}
