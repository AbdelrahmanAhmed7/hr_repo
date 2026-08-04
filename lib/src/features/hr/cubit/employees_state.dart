import '../models/department_option.dart';
import '../models/employee.dart';
import '../models/job_title_option.dart';

const Object _employeesStateUnset = Object();

class EmployeesState {
  final List<Employee> employees;
  final List<DepartmentOption> departments;
  final List<JobTitleOption> jobTitles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isFiltersLoading;
  final String? error;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final String searchQuery;
  final int? selectedDepartmentId;
  final int? selectedJobId;
  final bool? selectedIsActive;

  const EmployeesState({
    this.employees = const [],
    this.departments = const [],
    this.jobTitles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isFiltersLoading = false,
    this.error,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.totalCount = 0,
    this.totalPages = 1,
    this.searchQuery = '',
    this.selectedDepartmentId,
    this.selectedJobId,
    this.selectedIsActive = true, // default: show only active employees
  });

  bool get hasMore => pageNumber < totalPages;

  EmployeesState copyWith({
    List<Employee>? employees,
    List<DepartmentOption>? departments,
    List<JobTitleOption>? jobTitles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isFiltersLoading,
    String? error,
    bool clearError = false,
    int? pageNumber,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    String? searchQuery,
    Object? selectedDepartmentId = _employeesStateUnset,
    bool clearSelectedDepartmentId = false,
    Object? selectedJobId = _employeesStateUnset,
    bool clearSelectedJobId = false,
    Object? selectedIsActive = _employeesStateUnset,
    bool clearSelectedIsActive = false,
  }) {
    return EmployeesState(
      employees: employees ?? this.employees,
      departments: departments ?? this.departments,
      jobTitles: jobTitles ?? this.jobTitles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFiltersLoading: isFiltersLoading ?? this.isFiltersLoading,
      error: clearError ? null : (error ?? this.error),
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDepartmentId: clearSelectedDepartmentId
          ? null
          : identical(selectedDepartmentId, _employeesStateUnset)
          ? this.selectedDepartmentId
          : selectedDepartmentId as int?,
      selectedJobId: clearSelectedJobId
          ? null
          : identical(selectedJobId, _employeesStateUnset)
          ? this.selectedJobId
          : selectedJobId as int?,
      selectedIsActive: clearSelectedIsActive
          ? null
          : identical(selectedIsActive, _employeesStateUnset)
          ? this.selectedIsActive
          : selectedIsActive as bool?,
    );
  }
}
