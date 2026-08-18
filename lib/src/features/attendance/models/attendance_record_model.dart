import 'package:json_annotation/json_annotation.dart';

part 'attendance_record_model.g.dart';

enum AttendanceStatus { present, departed, absent }

@JsonSerializable()
class AttendanceRecordModel {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'employeeName')
  final String employeeName;

  @JsonKey(name: 'machineCode')
  final String? machineCode;

  @JsonKey(name: 'date')
  final String date;

  @JsonKey(name: 'dayOfWeek')
  final String dayOfWeek;

  @JsonKey(name: 'attendanceTime')
  final String? attendanceTime;

  @JsonKey(name: 'departureTime')
  final String? departureTime;

  @JsonKey(name: 'deviceType')
  final int? deviceType;

  @JsonKey(name: 'location')
  final String? location;

  @JsonKey(name: 'locationId')
  final int? locationId;

  @JsonKey(name: 'isClosed')
  final bool isClosed;

  @JsonKey(name: 'departureSource')
  final String? departureSource;

  @JsonKey(name: 'createdAt')
  final String createdAt;

  @JsonKey(name: 'updatedAt')
  final String? updatedAt;

  const AttendanceRecordModel({
    required this.id,
    required this.employeeName,
    this.machineCode,
    required this.date,
    required this.dayOfWeek,
    this.attendanceTime,
    this.departureTime,
    this.deviceType,
    this.location,
    this.locationId,
    required this.isClosed,
    this.departureSource,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceRecordModelToJson(this);

  bool get isAbsent => id == 0 || attendanceTime == null;

  bool get hasDeparted => departureTime != null;

  bool get isStillPresent => !isAbsent && !hasDeparted;

  AttendanceStatus get status => isAbsent
      ? AttendanceStatus.absent
      : hasDeparted
          ? AttendanceStatus.departed
          : AttendanceStatus.present;
}
