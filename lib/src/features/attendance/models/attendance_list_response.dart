class AttendanceListResponse {
  final List<AttendanceItem> attendances;
  final int totalEmployees;
  final int employeesWithAttendance;
  final int employeesWithDeparture;
  final int totalDays;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  const AttendanceListResponse({
    required this.attendances,
    required this.totalEmployees,
    required this.employeesWithAttendance,
    required this.employeesWithDeparture,
    required this.totalDays,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory AttendanceListResponse.fromJson(Map<String, dynamic> json) {
    final attendancesRaw = json['attendances'] as List<dynamic>? ?? const [];

    return AttendanceListResponse(
      attendances: attendancesRaw
          .map((item) => AttendanceItem.fromJson(Map<String, dynamic>.from(item as Map)))
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
}

class AttendanceItem {
  final int id;
  final String? employeeName;
  final String? machineCode;
  final String date;
  final String? dayOfWeek;
  final String? attendanceTime;
  final String? departureTime;
  final int? deviceType;
  final String? location;
  final int? locationId;
  final String? createdAt;
  final String? updatedAt;

  const AttendanceItem({
    required this.id,
    this.employeeName,
    this.machineCode,
    required this.date,
    this.dayOfWeek,
    this.attendanceTime,
    this.departureTime,
    this.deviceType,
    this.location,
    this.locationId,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceItem.fromJson(Map<String, dynamic> json) {
    return AttendanceItem(
      id: AttendanceListResponse._toInt(json['id']),
      employeeName: json['employeeName']?.toString(),
      machineCode: json['machineCode']?.toString(),
      date: json['date']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek']?.toString(),
      attendanceTime: json['attendanceTime']?.toString(),
      departureTime: json['departureTime']?.toString(),
      deviceType: json['deviceType'] is int
          ? json['deviceType'] as int
          : int.tryParse(json['deviceType']?.toString() ?? ''),
      location: json['location']?.toString(),
      locationId: json['locationId'] is int
          ? json['locationId'] as int
          : int.tryParse(json['locationId']?.toString() ?? ''),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  bool get hasCheckedIn => attendanceTime != null && attendanceTime!.trim().isNotEmpty;

  bool get hasCheckedOut =>
      departureTime != null && departureTime!.trim().isNotEmpty;

  bool get isComplete => hasCheckedIn && hasCheckedOut;
}
