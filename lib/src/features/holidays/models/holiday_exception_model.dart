class HolidayExceptionModel {
  final int id;
  final int publicHolidayId;
  final String? employeeId;
  final String? employeeName;
  final int? departmentId;
  final String? departmentName;
  final int? employmentModeId;
  final String? employmentModeName;

  HolidayExceptionModel({
    required this.id,
    required this.publicHolidayId,
    this.employeeId,
    this.employeeName,
    this.departmentId,
    this.departmentName,
    this.employmentModeId,
    this.employmentModeName,
  });

  factory HolidayExceptionModel.fromJson(Map<String, dynamic> json) {
    return HolidayExceptionModel(
      id: json['id'] as int,
      publicHolidayId: json['publicHolidayId'] as int,
      employeeId: json['employeeId'] as String?,
      employeeName: json['employeeName'] as String?,
      departmentId: json['departmentId'] as int?,
      departmentName: json['departmentName'] as String?,
      employmentModeId: json['employmentModeId'] as int?,
      employmentModeName: json['employmentModeName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicHolidayId': publicHolidayId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'employmentModeId': employmentModeId,
      'employmentModeName': employmentModeName,
    };
  }

  /// Create a copy with modified fields
  HolidayExceptionModel copyWith({
    int? id,
    int? publicHolidayId,
    String? employeeId,
    String? employeeName,
    int? departmentId,
    String? departmentName,
    int? employmentModeId,
    String? employmentModeName,
  }) {
    return HolidayExceptionModel(
      id: id ?? this.id,
      publicHolidayId: publicHolidayId ?? this.publicHolidayId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      employmentModeId: employmentModeId ?? this.employmentModeId,
      employmentModeName: employmentModeName ?? this.employmentModeName,
    );
  }
}
