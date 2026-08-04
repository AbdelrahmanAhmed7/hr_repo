import 'package:json_annotation/json_annotation.dart';

part 'attendance_record.g.dart';

@JsonSerializable()
class AttendanceRecord {
  @JsonKey(name: 'id')
  final int id;
  
  @JsonKey(name: 'userId')
  final String userId;
  
  @JsonKey(name: 'date')
  final String date;
  
  @JsonKey(name: 'attendanceTime')
  final String? attendanceTime;
  
  @JsonKey(name: 'departureTime')
  final String? departureTime;
  
  @JsonKey(name: 'deviceType')
  final int deviceType;
  
  @JsonKey(name: 'location')
  final String? location;
  
  @JsonKey(name: 'createdAt')
  final String createdAt;
  
  @JsonKey(name: 'updatedAt')
  final String? updatedAt; // Make nullable

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.attendanceTime,
    this.departureTime,
    required this.deviceType,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceRecordToJson(this);
  
  bool get hasCheckedIn => attendanceTime != null;
  bool get hasCheckedOut => departureTime != null;
}
