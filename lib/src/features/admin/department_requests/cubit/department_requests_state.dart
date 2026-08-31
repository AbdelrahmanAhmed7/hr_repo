import '../models/department_requests_response.dart';

enum DepartmentRequestsStatus { initial, loading, success, error }

class DepartmentRequestsState {
  final DepartmentRequestsStatus status;
  final List<DepartmentRequestsItem> departments;
  final int selectedMonth; // 0 = all months
  final int selectedYear;
  final String? errorMessage;

  /// Key of the request currently being updated, e.g. "leave_1458".
  final String? updatingRequestKey;

  const DepartmentRequestsState({
    this.status = DepartmentRequestsStatus.initial,
    this.departments = const [],
    this.selectedMonth = 0,
    required this.selectedYear,
    this.errorMessage,
    this.updatingRequestKey,
  });

  int get totalRequests =>
      departments.fold<int>(0, (sum, dept) => sum + dept.totalRequests);

  DepartmentRequestsState copyWith({
    DepartmentRequestsStatus? status,
    List<DepartmentRequestsItem>? departments,
    int? selectedMonth,
    int? selectedYear,
    String? errorMessage,
    String? updatingRequestKey,
    bool clearUpdatingKey = false,
  }) {
    return DepartmentRequestsState(
      status: status ?? this.status,
      departments: departments ?? this.departments,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      errorMessage: errorMessage,
      updatingRequestKey:
          clearUpdatingKey ? null : (updatingRequestKey ?? this.updatingRequestKey),
    );
  }
}
