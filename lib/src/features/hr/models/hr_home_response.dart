class HrHomeResponse {
  final String greeting;
  final String? jobTitle;
  final String? departmentName;
  final String? todayAttendanceTime;
  final String? todayDepartureTime;
  final List<HrRequestItem> allRequests;
  final List<HrRequestItem> pendingRequests;
  final List<HrRequestItem> acceptedRequests;
  final List<HrRequestItem> rejectedRequests;
  final List<dynamic> employees;
  final HrStatistics statistics;

  HrHomeResponse({
    required this.greeting,
    this.jobTitle,
    this.departmentName,
    this.todayAttendanceTime,
    this.todayDepartureTime,
    required this.allRequests,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.rejectedRequests,
    required this.employees,
    required this.statistics,
  });

  factory HrHomeResponse.fromJson(Map<String, dynamic> json) {
    return HrHomeResponse(
      greeting: json['greeting'] as String,
      jobTitle: json['jobTitle'] as String?,
      departmentName: json['departmentName'] as String?,
      todayAttendanceTime: json['todayAttendanceTime'] as String?,
      todayDepartureTime: json['todayDepartureTime'] as String?,
      allRequests: (json['allRequests'] as List<dynamic>?)
              ?.map((e) => HrRequestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingRequests: (json['pendingRequests'] as List<dynamic>?)
              ?.map((e) => HrRequestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      acceptedRequests: (json['acceptedRequests'] as List<dynamic>?)
              ?.map((e) => HrRequestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rejectedRequests: (json['rejectedRequests'] as List<dynamic>?)
              ?.map((e) => HrRequestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      employees: json['employees'] as List<dynamic>? ?? [],
      statistics: HrStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
    );
  }
}

class HrRequestItem {
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

  HrRequestItem({
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
  });

  factory HrRequestItem.fromJson(Map<String, dynamic> json) {
    return HrRequestItem(
      id: json['id'] as int,
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
    );
  }
}

class HrStatistics {
  final int totalEmployees;
  final int totalDepartments;
  final List<DepartmentEmployeeCount> employeesPerDepartment;

  HrStatistics({
    required this.totalEmployees,
    required this.totalDepartments,
    required this.employeesPerDepartment,
  });

  factory HrStatistics.fromJson(Map<String, dynamic> json) {
    return HrStatistics(
      totalEmployees: json['totalEmployees'] as int,
      totalDepartments: json['totalDepartments'] as int,
      employeesPerDepartment: (json['employeesPerDepartment'] as List<dynamic>?)
              ?.map((e) => DepartmentEmployeeCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DepartmentEmployeeCount {
  final int departmentId;
  final String departmentName;
  final int employeeCount;

  DepartmentEmployeeCount({
    required this.departmentId,
    required this.departmentName,
    required this.employeeCount,
  });

  factory DepartmentEmployeeCount.fromJson(Map<String, dynamic> json) {
    return DepartmentEmployeeCount(
      departmentId: json['departmentId'] as int,
      departmentName: json['departmentName'] as String,
      employeeCount: json['employeeCount'] as int,
    );
  }
}
