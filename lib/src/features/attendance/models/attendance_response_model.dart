import 'attendance_record_model.dart';

class AttendanceResponseModel {
  final List<AttendanceRecordModel> attendances;
  final int totalEmployees;
  final int employeesWithAttendance;
  final int employeesWithDeparture;
  final int totalDays;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  const AttendanceResponseModel({
    required this.attendances,
    required this.totalEmployees,
    required this.employeesWithAttendance,
    required this.employeesWithDeparture,
    required this.totalDays,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory AttendanceResponseModel.fromJson(Map<String, dynamic> json) {
    final attendancesRaw = json['attendances'] as List<dynamic>? ?? const [];

    return AttendanceResponseModel(
      attendances: attendancesRaw
          .map((item) => AttendanceRecordModel.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
      totalEmployees: _toInt(json['totalEmployees']),
      employeesWithAttendance: _toInt(json['employeesWithAttendance']),
      employeesWithDeparture: _toInt(json['employeesWithDeparture']),
      totalDays: _toInt(json['totalDays']),
      pageNumber: _toInt(json['pageNumber'], fallback: 1),
      pageSize: _toInt(json['pageSize'], fallback: 50),
      totalCount: _toInt(json['totalCount']),
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int get absentCount => totalEmployees - employeesWithAttendance;

  double get attendancePercentage =>
      totalEmployees == 0 ? 0 : (employeesWithAttendance / totalEmployees) * 100;
}
