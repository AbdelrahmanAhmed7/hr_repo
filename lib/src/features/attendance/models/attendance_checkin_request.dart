import 'package:json_annotation/json_annotation.dart';

part 'attendance_checkin_request.g.dart';

@JsonSerializable(explicitToJson: true)
class AttendanceCheckinRequest {
  @JsonKey(name: 'fingerprintKey')
  final String fingerprintKey;

  @JsonKey(name: 'latitude')
  final double latitude;

  @JsonKey(name: 'longitude')
  final double longitude;

  AttendanceCheckinRequest({
    required this.fingerprintKey,
    required this.latitude,
    required this.longitude,
  });

  factory AttendanceCheckinRequest.fromJson(Map<String, dynamic> json) =>
      _$AttendanceCheckinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceCheckinRequestToJson(this);
}
