import '../models/department_requests_response.dart';

enum DepartmentRequestsStatus { initial, loading, success, error }

class DepartmentRequestsState {
  final DepartmentRequestsStatus status;
  final List<DepartmentRequestsItem> departments;
  final int selectedMonth; // 0 = all months
  final int selectedYear;
  final String? errorMessage;

  /// Client-side filters (no reload needed).
  final DeptRequestStatus? statusFilter; // null = all
  final String searchQuery;

  /// Key of the request currently being updated, e.g. "leave_1458".
  final String? updatingRequestKey;

  const DepartmentRequestsState({
    this.status = DepartmentRequestsStatus.initial,
    this.departments = const [],
    this.selectedMonth = 0,
    required this.selectedYear,
    this.errorMessage,
    this.statusFilter,
    this.searchQuery = '',
    this.updatingRequestKey,
  });

  int get totalRequests =>
      departments.fold<int>(0, (sum, dept) => sum + dept.totalRequests);

  bool get hasActiveFilters =>
      statusFilter != null || searchQuery.trim().isNotEmpty;

  /// Departments with [searchQuery] and [statusFilter] applied client-side.
  /// Departments/employees left with no visible requests are dropped.
  List<DepartmentRequestsItem> get visibleDepartments {
    final query = searchQuery.trim().toLowerCase();
    final visible = <DepartmentRequestsItem>[];
    for (final dept in departments) {
      var employees = dept.employees;
      if (query.isNotEmpty) {
        final deptMatches =
            dept.departmentName.toLowerCase().contains(query);
        employees = employees
            .where(
              (e) =>
                  deptMatches ||
                  e.employeeName.toLowerCase().contains(query),
            )
            .toList();
      }
      var total = 0;
      final visibleEmployees = <DepartmentEmployee>[];
      for (final employee in employees) {
        final leaves = _matching(employee.leaves);
        final permissions = _matching(employee.permissions);
        final assignments = _matching(employee.assignments);
        final count = leaves.length + permissions.length + assignments.length;
        if (count == 0) continue;
        total += count;
        visibleEmployees.add(
          DepartmentEmployee(
            userId: employee.userId,
            employeeName: employee.employeeName,
            jobTitle: employee.jobTitle,
            leaves: leaves,
            permissions: permissions,
            assignments: assignments,
            totalRequests: count,
          ),
        );
      }
      if (visibleEmployees.isEmpty) continue;
      visible.add(
        DepartmentRequestsItem(
          departmentId: dept.departmentId,
          departmentName: dept.departmentName,
          employees: visibleEmployees,
          totalRequests: total,
        ),
      );
    }
    return visible;
  }

  int get visibleTotalRequests => visibleDepartments.fold<int>(
        0,
        (sum, dept) => sum + dept.totalRequests,
      );

  List<T> _matching<T extends DeptRequestBase>(List<T> requests) {
    final filter = statusFilter;
    if (filter == null) return requests;
    return requests.where((r) => r.status == filter).toList();
  }

  DepartmentRequestsState copyWith({
    DepartmentRequestsStatus? status,
    List<DepartmentRequestsItem>? departments,
    int? selectedMonth,
    int? selectedYear,
    String? errorMessage,
    DeptRequestStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    String? updatingRequestKey,
    bool clearUpdatingKey = false,
  }) {
    return DepartmentRequestsState(
      status: status ?? this.status,
      departments: departments ?? this.departments,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      errorMessage: errorMessage,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      updatingRequestKey:
          clearUpdatingKey ? null : (updatingRequestKey ?? this.updatingRequestKey),
    );
  }
}
