import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/features/attendance/models/daily_attendance_record.dart';
import '../../../core/utils/app_exception.dart';
import '../models/department_option.dart';
import '../models/employee.dart';
import '../models/employees_page_response.dart';
import '../models/employee_upsert_request.dart';
import '../models/employee_payslip.dart';
import '../models/job_title_option.dart';
import '../models/salary_calculation.dart';
import '../repository/employees_repository.dart';
import 'employees_state.dart';

class EmployeesCubit extends Cubit<EmployeesState> {
  final EmployeesRepository _repository;

  EmployeesCubit(this._repository) : super(const EmployeesState());

  Future<EmployeesPageResponse> _fetchEmployeesPage({
    required int pageNumber,
    required int pageSize,
    String? search,
    int? departmentId,
    int? branchId,
    int? jobId,
    bool? isActive,
  }) {
    return _repository.getEmployees(
      pageNumber: pageNumber,
      pageSize: pageSize,
      search: search,
      departmentId: departmentId,
      branchId: branchId,
      jobId: jobId,
      isActive: isActive,
    );
  }

  Future<void> loadInitialData() async {
    emit(
      state.copyWith(isLoading: true, isFiltersLoading: true, clearError: true),
    );

    try {
      final results = await Future.wait<dynamic>([
        _repository.getDepartments(pageSize: 10),
        _repository.getJobTitles(),
        _repository.getEmployees(
          pageNumber: 1,
          pageSize: state.pageSize,
          isActive: true,
        ),
      ]);

      final departments = results[0] as List<DepartmentOption>;
      final jobTitles = results[1] as List<JobTitleOption>;
      final employeesPage = results[2] as EmployeesPageResponse;

      emit(
        state.copyWith(
          departments: departments,
          jobTitles: jobTitles,
          employees: employeesPage.items,
          pageNumber: employeesPage.pageNumber,
          pageSize: employeesPage.pageSize,
          totalCount: employeesPage.totalCount,
          totalPages: employeesPage.totalPages,
          isLoading: false,
          isFiltersLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isFiltersLoading: false,
          error: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> getAllEmployees({bool showLoader = true}) async {
    if (showLoader) {
      emit(state.copyWith(isLoading: true, clearError: true));
    } else {
      emit(state.copyWith(clearError: true));
    }

    try {
      final response = await _fetchEmployeesPage(
        pageNumber: 1,
        pageSize: state.pageSize,
        search: state.searchQuery,
        departmentId: state.selectedDepartmentId,
        jobId: state.selectedJobId,
        isActive: state.selectedIsActive,
      );

      emit(
        state.copyWith(
          employees: response.items,
          pageNumber: response.pageNumber,
          pageSize: response.pageSize,
          totalCount: response.totalCount,
          totalPages: response.totalPages,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> loadMoreEmployees() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = state.pageNumber + 1;
      final response = await _fetchEmployeesPage(
        pageNumber: nextPage,
        pageSize: state.pageSize,
        search: state.searchQuery,
        departmentId: state.selectedDepartmentId,
        jobId: state.selectedJobId,
        isActive: state.selectedIsActive,
      );

      emit(
        state.copyWith(
          employees: [...state.employees, ...response.items],
          pageNumber: response.pageNumber,
          pageSize: response.pageSize,
          totalCount: response.totalCount,
          totalPages: response.totalPages,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          error: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> updateSearchQuery(String query) async {
    emit(state.copyWith(searchQuery: query.trim()));
    await getAllEmployees(showLoader: true);
  }

  Future<void> applyFilters({
    int? departmentId,
    bool clearDepartment = false,
    int? jobId,
    bool clearJob = false,
    bool? isActive,
    bool clearIsActive = false,
  }) async {
    final nextState = state.copyWith(
      selectedDepartmentId: departmentId,
      clearSelectedDepartmentId: clearDepartment,
      selectedJobId: jobId,
      clearSelectedJobId: clearJob,
      selectedIsActive: isActive,
      clearSelectedIsActive: clearIsActive,
    );

    emit(nextState.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _fetchEmployeesPage(
        pageNumber: 1,
        pageSize: nextState.pageSize,
        search: nextState.searchQuery,
        departmentId: nextState.selectedDepartmentId,
        jobId: nextState.selectedJobId,
        isActive: nextState.selectedIsActive,
      );

      emit(
        nextState.copyWith(
          employees: response.items,
          pageNumber: response.pageNumber,
          pageSize: response.pageSize,
          totalCount: response.totalCount,
          totalPages: response.totalPages,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        nextState.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> clearFilters() async {
    emit(
      state.copyWith(
        clearSelectedDepartmentId: true,
        clearSelectedJobId: true,
        clearSelectedIsActive: true,
      ),
    );
    await getAllEmployees(showLoader: true);
  }

  Future<void> refresh() async {
    await getAllEmployees(showLoader: false);
  }

  Future<void> updateEmployeeSecurityClearance(
    String employeeId,
    String? securityClearance,
  ) async {
    final updatedEmployees = state.employees.map((employee) {
      if (employee.id == employeeId) {
        return employee.copyWith(securityClearance: securityClearance);
      }
      return employee;
    }).toList();

    emit(state.copyWith(employees: updatedEmployees));
  }

  Future<void> updateEmployee(Employee updatedEmployee) async {
    final updatedEmployees = state.employees.map((employee) {
      if (employee.id == updatedEmployee.id) {
        return updatedEmployee;
      }
      return employee;
    }).toList();

    emit(state.copyWith(employees: updatedEmployees));
  }

  Employee? getEmployeeById(String employeeId) {
    try {
      return state.employees.firstWhere(
        (employee) => employee.id == employeeId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<DailyAttendanceRecord>> getEmployeeAttendanceRecords(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month - 1, 1);
    final end = endDate ?? now;

    final records = <DailyAttendanceRecord>[];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final date = start.add(Duration(days: i));
      if (date.isAfter(now)) break;

      AttendanceStatus status;
      DateTime? checkIn;
      DateTime? checkOut;
      double? hours;

      if (i % 10 == 0) {
        status = AttendanceStatus.leave;
      } else if (i % 12 == 0) {
        status = AttendanceStatus.late;
        checkIn = DateTime(date.year, date.month, date.day, 10, 30);
        checkOut = DateTime(date.year, date.month, date.day, 18, 0);
        hours = 7.5;
      } else if (i % 7 == 0) {
        status = AttendanceStatus.absent;
      } else {
        status = AttendanceStatus.present;
        checkIn = DateTime(date.year, date.month, date.day, 9, 0);
        checkOut = DateTime(date.year, date.month, date.day, 17, 0);
        hours = 8.0;
      }

      records.add(
        DailyAttendanceRecord(
          id: '${employeeId}_${date.millisecondsSinceEpoch}',
          date: date,
          checkInTime: checkIn,
          checkOutTime: checkOut,
          status: status,
          workHours: hours,
        ),
      );
    }

    return records;
  }

  Future<void> addEmployee(Employee employee) async {
    final exists = state.employees.any((e) => e.id == employee.id);
    final updatedEmployees = exists
        ? state.employees
              .map((e) => e.id == employee.id ? employee : e)
              .toList()
        : [employee, ...state.employees];

    emit(
      state.copyWith(
        employees: updatedEmployees,
        totalCount: exists ? state.totalCount : state.totalCount + 1,
      ),
    );
  }

  Future<Employee> getEmployeeDetails(String employeeId) {
    return _repository.getEmployeeDetails(employeeId);
  }

  Future<SalaryCalculation> calculateSalary({
    required String employeeId,
    required int month,
    required int year,
  }) {
    return _repository.calculateSalary(
      employeeId: employeeId,
      month: month,
      year: year,
    );
  }

  Future<EmployeePayslip> getPayslip({
    required String employeeId,
    required int month,
    required int year,
  }) {
    return _repository.getPayslip(
      employeeId: employeeId,
      month: month,
      year: year,
    );
  }

  Future<bool> createEmployee({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
    String? nationalId,
    String? gender,
    String? departmentName,
    String? positionName,
    DateTime? startDate,
    DateTime? birthday,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final nameParts = _splitName(fullName);
      final departmentId = _resolveDepartmentId(departmentName);
      final jobId = _resolveJobId(positionName);

      final request = EmployeeUpsertRequest(
        firstNameAr: nameParts.$1,
        middleNameAr: nameParts.$2,
        lastNameAr: nameParts.$3,
        firstNameEn: nameParts.$1,
        middleNameEn: nameParts.$2,
        lastNameEn: nameParts.$3,
        phoneNumber: phoneNumber.trim(),
        password: password.trim(),
        email: _normalize(email),
        nationalId: _normalize(nationalId),
        isMale: _parseIsMale(gender),
        departmentId: departmentId,
        jobId: jobId,
        startDate: startDate,
        birthday: birthday,
        isActive: true,
      );

      await _repository.createEmployee(request);

      final refreshed = await _fetchEmployeesPage(
        pageNumber: 1,
        pageSize: state.pageSize,
        search: state.searchQuery,
        departmentId: state.selectedDepartmentId,
        jobId: state.selectedJobId,
        isActive: state.selectedIsActive,
      );

      emit(
        state.copyWith(
          employees: refreshed.items,
          pageNumber: refreshed.pageNumber,
          pageSize: refreshed.pageSize,
          totalCount: refreshed.totalCount,
          totalPages: refreshed.totalPages,
          isLoading: false,
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.from(e).message,
        ),
      );
      return false;
    }
  }

  Future<Employee?> updateEmployeeRemote({
    required String employeeId,
    required String fullName,
    required String phoneNumber,
    String? email,
    String? nationalId,
    String? gender,
    String? departmentName,
    String? positionName,
    DateTime? startDate,
    DateTime? birthday,
    bool? isActive,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final nameParts = _splitName(fullName);
      final departmentId = _resolveDepartmentId(departmentName);
      final jobId = _resolveJobId(positionName);

      final request = EmployeeUpsertRequest(
        firstNameAr: nameParts.$1,
        middleNameAr: nameParts.$2,
        lastNameAr: nameParts.$3,
        firstNameEn: nameParts.$1,
        middleNameEn: nameParts.$2,
        lastNameEn: nameParts.$3,
        phoneNumber: phoneNumber.trim(),
        email: _normalize(email),
        nationalId: _normalize(nationalId),
        isMale: _parseIsMale(gender),
        departmentId: departmentId,
        jobId: jobId,
        startDate: startDate,
        birthday: birthday,
        isActive: isActive,
      );

      final updated = await _repository.updateEmployee(
        id: employeeId,
        request: request,
      );

      final updatedEmployees = state.employees.map((employee) {
        if (employee.id == updated.id) return updated;
        return employee;
      }).toList();

      emit(
        state.copyWith(
          employees: updatedEmployees,
          isLoading: false,
          clearError: true,
        ),
      );

      return updated;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.from(e).message,
        ),
      );
      return null;
    }
  }

  (String, String?, String?) _splitName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return ('', null, null);
    }

    final parts = normalized.split(' ');
    if (parts.length == 1) {
      return (parts[0], null, null);
    }
    if (parts.length == 2) {
      return (parts[0], null, parts[1]);
    }
    return (
      parts.first,
      parts.sublist(1, parts.length - 1).join(' '),
      parts.last,
    );
  }

  int? _resolveDepartmentId(String? departmentName) {
    final query = _normalize(departmentName)?.toLowerCase();
    if (query == null) return null;

    for (final item in state.departments) {
      if (item.name.trim().toLowerCase() == query) {
        return item.id;
      }
    }
    return null;
  }

  int? _resolveJobId(String? positionName) {
    final query = _normalize(positionName)?.toLowerCase();
    if (query == null) return null;

    for (final job in state.jobTitles) {
      if (job.displayName.trim().toLowerCase() == query ||
          job.name.trim().toLowerCase() == query) {
        return job.id;
      }
    }
    return null;
  }

  bool? _parseIsMale(String? gender) {
    final value = _normalize(gender)?.toLowerCase();
    if (value == null) return null;

    if (value.contains('ذكر') || value.contains('male') || value == 'm') {
      return true;
    }
    if (value.contains('انث') ||
        value.contains('أنث') ||
        value.contains('female') ||
        value == 'f') {
      return false;
    }
    return null;
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
