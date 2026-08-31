/// Response of GET /api/DepartmentRequests
class DepartmentRequestsResponse {
  final List<DepartmentRequestsItem> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const DepartmentRequestsResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory DepartmentRequestsResponse.fromJson(Map<String, dynamic> json) {
    return DepartmentRequestsResponse(
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => DepartmentRequestsItem.fromJson(
              Map<String, dynamic>.from(item)))
          .toList(),
      pageNumber: int.tryParse(json['pageNumber']?.toString() ?? '') ?? 1,
      pageSize: int.tryParse(json['pageSize']?.toString() ?? '') ?? 10,
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      totalPages: int.tryParse(json['totalPages']?.toString() ?? '') ?? 1,
    );
  }
}

/// A department with its employees' requests.
class DepartmentRequestsItem {
  final int departmentId;
  final String departmentName;
  final List<DepartmentEmployee> employees;
  final int totalRequests;

  const DepartmentRequestsItem({
    required this.departmentId,
    required this.departmentName,
    required this.employees,
    required this.totalRequests,
  });

  factory DepartmentRequestsItem.fromJson(Map<String, dynamic> json) {
    return DepartmentRequestsItem(
      departmentId:
          int.tryParse(json['departmentId']?.toString() ?? '') ?? 0,
      departmentName: json['departmentName']?.toString() ?? '',
      employees: (json['employees'] as List? ?? [])
          .whereType<Map>()
          .map((item) =>
              DepartmentEmployee.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      totalRequests:
          int.tryParse(json['totalRequests']?.toString() ?? '') ?? 0,
    );
  }

  /// Total requests of all employees inside this department.
  int get employeesTotalRequests => employees.fold(
        0,
        (sum, emp) => sum + emp.totalRequests,
      );
}

/// An employee inside a department with his grouped requests.
class DepartmentEmployee {
  final String userId;
  final String employeeName;
  final String? jobTitle;
  final List<EmployeeLeave> leaves;
  final List<EmployeePermission> permissions;
  final List<EmployeeAssignment> assignments;
  final int totalRequests;

  const DepartmentEmployee({
    required this.userId,
    required this.employeeName,
    this.jobTitle,
    required this.leaves,
    required this.permissions,
    required this.assignments,
    required this.totalRequests,
  });

  factory DepartmentEmployee.fromJson(Map<String, dynamic> json) {
    return DepartmentEmployee(
      userId: json['userId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      jobTitle: json['jobTitle']?.toString(),
      leaves: (json['leaves'] as List? ?? [])
          .whereType<Map>()
          .map((item) =>
              EmployeeLeave.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      permissions: (json['permissions'] as List? ?? [])
          .whereType<Map>()
          .map((item) =>
              EmployeePermission.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      assignments: (json['assignments'] as List? ?? [])
          .whereType<Map>()
          .map((item) =>
              EmployeeAssignment.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      totalRequests:
          int.tryParse(json['totalRequests']?.toString() ?? '') ?? 0,
    );

  }

  bool get hasRequests => totalRequests > 0;
}

// ─── Request items ───────────────────────────────────────────────────────────

enum DeptRequestStatus { pending, approved, rejected, unknown }

DeptRequestStatus parseDeptRequestStatus(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'approved':
    case 'accepted':
      return DeptRequestStatus.approved;
    case 'rejected':
      return DeptRequestStatus.rejected;
    case 'pending':
      return DeptRequestStatus.pending;
    default:
      return DeptRequestStatus.unknown;
  }
}

String? _trimTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final dt = DateTime.parse(iso);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

String? _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

abstract class DeptRequestBase {
  final int id;
  final String statusText;
  final String? reason;

  const DeptRequestBase({required this.id, required this.statusText, this.reason});

  DeptRequestStatus get status => parseDeptRequestStatus(statusText);
}

class EmployeeLeave extends DeptRequestBase {
  final String leaveType;
  final String startDate;
  final String endDate;

  const EmployeeLeave({
    required super.id,
    required super.statusText,
    super.reason,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
  });

  factory EmployeeLeave.fromJson(Map<String, dynamic> json) {
    return EmployeeLeave(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      statusText: json['status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      leaveType: json['leaveType']?.toString() ?? '',
      startDate: _formatDate(json['startDate']?.toString()) ?? '',
      endDate: _formatDate(json['endDate']?.toString()) ?? '',
    );
  }
}

class EmployeePermission extends DeptRequestBase {
  final String date;
  final String? startTime;
  final String? endTime;

  const EmployeePermission({
    required super.id,
    required super.statusText,
    super.reason,
    required this.date,
    this.startTime,
    this.endTime,
  });

  factory EmployeePermission.fromJson(Map<String, dynamic> json) {
    return EmployeePermission(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      statusText: json['status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      date: _formatDate(json['date']?.toString()) ?? '',
      startTime: _trimTime(json['startTime']?.toString()),
      endTime: _trimTime(json['endTime']?.toString()),
    );
  }
}

class EmployeeAssignment extends DeptRequestBase {
  final String where;
  final String startDate;
  final String endDate;
  final String? startTime;
  final String? endTime;

  const EmployeeAssignment({
    required super.id,
    required super.statusText,
    super.reason,
    required this.where,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
  });

  factory EmployeeAssignment.fromJson(Map<String, dynamic> json) {
    return EmployeeAssignment(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      statusText: json['status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      where: json['where']?.toString() ?? '',
      startDate: _formatDate(json['startDate']?.toString()) ?? '',
      endDate: _formatDate(json['endDate']?.toString()) ?? '',
      startTime: _trimTime(json['startTime']?.toString()),
      endTime: _trimTime(json['endTime']?.toString()),
    );
  }
}
