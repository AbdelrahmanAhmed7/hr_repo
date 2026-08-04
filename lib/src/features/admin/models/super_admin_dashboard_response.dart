class SuperAdminDashboardResponse {
  final String greeting;
  final String? fullNameAr;
  final String? fullNameEn;
  final String? jobTitle;
  final String? imageUrl;
  final String? todayAttendanceTime;
  final String? todayDepartureTime;
  final List<SuperAdminDepartmentData> departments;

  SuperAdminDashboardResponse({
    required this.greeting,
    this.fullNameAr,
    this.fullNameEn,
    this.jobTitle,
    this.imageUrl,
    this.todayAttendanceTime,
    this.todayDepartureTime,
    required this.departments,
  });

  /// First + last name only
  String get displayName {
    final name = fullNameAr?.trim().isNotEmpty == true
        ? fullNameAr!.trim()
        : fullNameEn?.trim() ?? 'سوبر أدمن';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length <= 2) return name;
    return '${parts.first} ${parts.last}';
  }

  // ── Computed stats ────────────────────────────────────────────────────────

  int get totalDepartments => departments.length;

  int get totalEmployees =>
      departments.fold(0, (sum, d) => sum + d.employees.length);

  int get presentToday => departments.fold(
    0,
    (sum, d) =>
        sum + d.employees.where((e) => e.todayAttendanceTime != null).length,
  );

  int get totalRequests =>
      departments.fold(0, (sum, d) => sum + d.requests.length);

  int get pendingRequests => departments.fold(
    0,
    (sum, d) => sum + d.requests.where((r) => r.isPending).length,
  );

  factory SuperAdminDashboardResponse.fromJson(Map<String, dynamic> json) {
    return SuperAdminDashboardResponse(
      greeting: json['greeting'] as String? ?? '',
      fullNameAr: json['fullNameAr'] as String?,
      fullNameEn: json['fullNameEn'] as String?,
      jobTitle: json['jobTitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
      todayAttendanceTime: json['todayAttendanceTime'] as String?,
      todayDepartureTime: json['todayDepartureTime'] as String?,
      departments:
          (json['departments'] as List<dynamic>?)
              ?.map(
                (e) => SuperAdminDepartmentData.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}

// ─── Department ───────────────────────────────────────────────────────────────

class SuperAdminDepartmentData {
  final int departmentId;
  final String departmentName;
  final List<SuperAdminDeptEmployee> employees;
  final List<SuperAdminRequest> requests;

  SuperAdminDepartmentData({
    required this.departmentId,
    required this.departmentName,
    required this.employees,
    required this.requests,
  });

  /// userId → employee object (for request card lookup)
  Map<String, SuperAdminDeptEmployee> get employeeMap => {
    for (final e in employees) e.id: e,
  };

  /// userId → employeeNameAr (built from requests that have names)
  Map<String, String> get employeeNameMap {
    final map = <String, String>{};
    for (final r in requests) {
      if (r.userId != null && r.employeeNameAr != null) {
        map[r.userId!] = r.employeeNameAr!;
      }
    }
    return map;
  }

  int get presentToday =>
      employees.where((e) => e.todayAttendanceTime != null).length;

  int get pendingRequestsCount => requests.where((r) => r.isPending).length;

  factory SuperAdminDepartmentData.fromJson(Map<String, dynamic> json) {
    return SuperAdminDepartmentData(
      departmentId: json['departmentId'] as int? ?? 0,
      departmentName: json['departmentName'] as String? ?? '',
      employees:
          (json['employees'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SuperAdminDeptEmployee.fromJson(e as Map<String, dynamic>),
              )
              .where((e) => e.isActive)
              .toList() ??
          [],
      requests:
          (json['requests'] as List<dynamic>?)
              ?.map(
                (e) => SuperAdminRequest.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

// ─── Department Employee (attendance only) ────────────────────────────────────

class SuperAdminDeptEmployee {
  final String id;
  final String? fullNameAr;
  final String? fullNameEn;
  final String? imageUrl;
  final bool isActive;
  final String? todayAttendanceTime;
  final String? todayDepartureTime;
  final String? managerName;

  SuperAdminDeptEmployee({
    required this.id,
    this.fullNameAr,
    this.fullNameEn,
    this.imageUrl,
    this.isActive = true,
    this.todayAttendanceTime,
    this.todayDepartureTime,
    this.managerName,
  });

  bool get isPresent => todayAttendanceTime != null;

  /// First + second name only
  String get shortNameAr {
    final name = fullNameAr?.trim() ?? '';
    if (name.isEmpty) return 'موظف';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length <= 2) return name;
    return '${parts[0]} ${parts[1]}';
  }

  factory SuperAdminDeptEmployee.fromJson(Map<String, dynamic> json) {
    return SuperAdminDeptEmployee(
      id: json['id'] as String,
      fullNameAr: json['fullNameAr'] as String?,
      fullNameEn: json['fullNameEn'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      todayAttendanceTime: json['todayAttendanceTime'] as String?,
      todayDepartureTime: json['todayDepartureTime'] as String?,
      managerName: json['managerName'] as String?,
    );
  }
}

// ─── Request ──────────────────────────────────────────────────────────────────

class SuperAdminRequest {
  final int id;
  final String type;
  final String createdAt;
  final String status;
  final String? userId;
  final String? employeeNameAr;
  final String? employeeNameEn;
  final String? date;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String? where;
  final String? reason;

  SuperAdminRequest({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.status,
    this.userId,
    this.employeeNameAr,
    this.employeeNameEn,
    this.date,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.where,
    this.reason,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved =>
      status.toLowerCase() == 'approved' || status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';

  /// Short name from employeeNameAr (first + second word)
  String get shortNameAr {
    if (employeeNameAr == null || employeeNameAr!.isEmpty) return 'موظف';
    final parts = employeeNameAr!
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) return employeeNameAr!;
    return '${parts[0]} ${parts[1]}';
  }

  factory SuperAdminRequest.fromJson(Map<String, dynamic> json) {
    return SuperAdminRequest(
      id: json['id'] as int,
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String,
      userId: json['userId'] as String?,
      employeeNameAr: json['employeeNameAr'] as String?,
      employeeNameEn: json['employeeNameEn'] as String?,
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

// ─── Backward compat stubs ────────────────────────────────────────────────────

/// Kept so existing code that references these doesn't break immediately
class SuperAdminEmployee {
  final String id;
  final String? firstNameAr;
  final String? lastNameAr;
  final String? departmentName;
  final String? jobTitle;
  final String? imageUrl;

  SuperAdminEmployee({
    required this.id,
    this.firstNameAr,
    this.lastNameAr,
    this.departmentName,
    this.jobTitle,
    this.imageUrl,
  });

  String get fullNameAr {
    final parts = [
      firstNameAr,
      lastNameAr,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? 'موظف' : parts.join(' ');
  }

  factory SuperAdminEmployee.fromJson(Map<String, dynamic> json) {
    return SuperAdminEmployee(
      id: json['id'] as String,
      firstNameAr: json['firstNameAr'] as String?,
      lastNameAr: json['lastNameAr'] as String?,
      departmentName: json['departmentName'] as String?,
      jobTitle: json['jobTitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
