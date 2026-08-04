class AdminDashboardResponse {
  final String greeting;
  final String? fullNameAr;
  final String? fullNameEn;
  final String? jobTitle;
  final String? departmentName;
  final String? imageUrl;
  final String? todayAttendanceTime;
  final String? todayDepartureTime;
  final List<AdminRequest> allRequests;
  final List<AdminRequest> pendingRequests;
  final List<AdminRequest> acceptedRequests;
  final List<AdminRequest> rejectedRequests;
  final List<AdminEmployee> employees;

  AdminDashboardResponse({
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
    required this.employees,
  });

  String get displayName {
    final name = (fullNameAr?.isNotEmpty == true)
        ? fullNameAr!
        : (fullNameEn ?? 'مدير');
    final parts = name.trim().split(' ');
    if (parts.length <= 2) return name;
    return '${parts.first} ${parts.last}';
  }

  factory AdminDashboardResponse.fromJson(Map<String, dynamic> json) {
    return AdminDashboardResponse(
      greeting: json['greeting'] as String? ?? '',
      fullNameAr: json['fullNameAr'] as String?,
      fullNameEn: json['fullNameEn'] as String?,
      jobTitle: json['jobTitle'] as String?,
      departmentName: json['departmentName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      todayAttendanceTime: json['todayAttendanceTime'] as String?,
      todayDepartureTime: json['todayDepartureTime'] as String?,
      allRequests:
          (json['allRequests'] as List<dynamic>?)
              ?.map((e) => AdminRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingRequests:
          (json['pendingRequests'] as List<dynamic>?)
              ?.map((e) => AdminRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      acceptedRequests:
          (json['acceptedRequests'] as List<dynamic>?)
              ?.map((e) => AdminRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rejectedRequests:
          (json['rejectedRequests'] as List<dynamic>?)
              ?.map((e) => AdminRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      employees:
          (json['employees'] as List<dynamic>?)
              ?.map((e) => AdminEmployee.fromJson(e as Map<String, dynamic>))
              .where((e) => e.isActive)
              .toList() ??
          [],
    );
  }

  // Keep backward compat for AdminRequestsCubit
  List<AdminRequest> get adminRequests => allRequests;
  List<AdminRequest> get departmentUsersRequests => [];
  List<AdminDepartmentUser> get departmentUsers => employees
      .map(
        (e) => AdminDepartmentUser(
          id: e.id,
          todayAttendanceTime: null,
          todayDepartureTime: null,
        ),
      )
      .toList();
}

class AdminEmployee {
  final String id;
  final String? nationalId;
  final String? firstNameAr;
  final String? middleNameAr;
  final String? lastNameAr;
  final String? firstNameEn;
  final String? lastNameEn;
  final String? email;
  final String? phoneNumber;
  final String? employeeCode;
  final String? jobTitleName;
  final String? departmentName;
  final String? imageUrl;
  final bool isActive;
  final bool isMale;
  final String? startDate;
  final String? employmentModeName;

  AdminEmployee({
    required this.id,
    this.nationalId,
    this.firstNameAr,
    this.middleNameAr,
    this.lastNameAr,
    this.firstNameEn,
    this.lastNameEn,
    this.email,
    this.phoneNumber,
    this.employeeCode,
    this.jobTitleName,
    this.departmentName,
    this.imageUrl,
    this.isActive = true,
    this.isMale = true,
    this.startDate,
    this.employmentModeName,
  });

  String get fullNameAr {
    final parts = [
      firstNameAr,
      middleNameAr,
      lastNameAr,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? 'موظف' : parts.join(' ');
  }

  factory AdminEmployee.fromJson(Map<String, dynamic> json) {
    return AdminEmployee(
      id: json['id'] as String? ?? '',
      nationalId: json['nationalId'] as String?,
      firstNameAr: json['firstNameAr'] as String?,
      middleNameAr: json['middleNameAr'] as String?,
      lastNameAr: json['lastNameAr'] as String?,
      firstNameEn: json['firstNameEn'] as String?,
      lastNameEn: json['lastNameEn'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      employeeCode: json['employeeCode'] as String?,
      jobTitleName: json['jobTitleName'] as String?,
      departmentName: json['departmentName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isMale: json['isMale'] as bool? ?? true,
      startDate: json['startDate'] as String?,
      employmentModeName: json['employmentModeName'] as String?,
    );
  }
}

class AdminDepartmentUser {
  final String id;
  final String? todayAttendanceTime;
  final String? todayDepartureTime;

  AdminDepartmentUser({
    required this.id,
    this.todayAttendanceTime,
    this.todayDepartureTime,
  });

  factory AdminDepartmentUser.fromJson(Map<String, dynamic> json) {
    return AdminDepartmentUser(
      id: json['id'] as String? ?? '',
      todayAttendanceTime: json['todayAttendanceTime'] as String?,
      todayDepartureTime: json['todayDepartureTime'] as String?,
    );
  }
}

class AdminRequest {
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

  AdminRequest({
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

  factory AdminRequest.fromJson(Map<String, dynamic> json) {
    return AdminRequest(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      status: json['status'] as String? ?? '',
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
