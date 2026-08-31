import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../models/attendance_record_model.dart';
import '../../../core/utils/app_exception.dart';
import '../repository/sa_attendance_repository.dart';
import 'sa_attendance_state.dart';

class SAAttendanceCubit extends Cubit<SAAttendanceState> {
  final SAAttendanceRepository _repository;
  final Dio? _dio;

  /// Maps employee name (lowercase) -> departmentId
  final Map<String, int?> _employeeDeptMap = {};

  SAAttendanceCubit(this._repository, {Dio? dio})
      : _dio = dio,
        super(SAAttendanceState.initial());

  String _formatApiDate(DateTime date) {
    return DateFormat('MM-dd-yyyy').format(date);
  }

  Future<void> loadDepartments() async {
    try {
      if (_dio == null) return;

      // 1) Load departments list for the dropdown
      final departments = <DepartmentOption>[];
      var currentPage = 1;
      var totalPages = 1;

      do {
        final response = await _dio.get(
          '/api/Department',
          queryParameters: {'pageNumber': currentPage, 'pageSize': 50},
        );

        final data = _asMap(response.data);
        final items = (data['items'] as List<dynamic>? ?? const [])
            .map((item) =>
                DepartmentOption.fromJson(item as Map<String, dynamic>))
            .toList();

        departments.addAll(items);
        totalPages = data['totalPages'] as int? ?? 1;
        currentPage++;
      } while (currentPage <= totalPages);

      // 2) Load ALL employees (paginated) to build name -> departmentId map
      await _loadEmployeeDepartmentMap();

      emit(state.copyWith(departments: departments));
    } catch (_) {
      // Departments load failed silently – dropdown will be empty.
    }
  }

  Future<void> _loadEmployeeDepartmentMap() async {
    if (_dio == null) return;
    try {
      var currentPage = 1;
      var totalPages = 1;

      do {
        final response = await _dio.get(
          '/api/Auth/users',
          queryParameters: {
            'pageNumber': currentPage,
            'pageSize': 100,
          },
        );

        final data = _asMap(response.data);
        final items = data['items'] as List<dynamic>? ?? const [];

        for (final item in items) {
          final map = item as Map<String, dynamic>;
          final firstName = (map['firstNameAr'] as String?)?.trim() ?? '';
          final middleName = (map['middleNameAr'] as String?)?.trim() ?? '';
          final lastName = (map['lastNameAr'] as String?)?.trim() ?? '';
          final fullName = '$firstName $middleName $lastName'.trim();
          final departmentId = map['departmentId'] as int?;

          if (fullName.isNotEmpty) {
            _employeeDeptMap[fullName.toLowerCase()] = departmentId;
          }
        }

        totalPages = data['totalPages'] as int? ?? 1;
        currentPage++;
      } while (currentPage <= totalPages);
    } catch (_) {
      // Employee map load failed silently.
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<void> loadAttendance({DateTime? date}) async {
    final targetDate = date ?? state.selectedDate;

    emit(state.copyWith(status: SAAttendanceStatus.loading));

    try {
      final response = await _repository.getAllAttendance(
        startDate: _formatApiDate(targetDate),
        endDate: _formatApiDate(targetDate),
        pageNumber: 1,
        pageSize: 500,
      );

      emit(
        state.copyWith(
          status: SAAttendanceStatus.success,
          records: response.attendances,
          totalEmployees: response.totalEmployees,
          employeesWithAttendance: response.employeesWithAttendance,
          employeesWithDeparture: response.employeesWithDeparture,
          attendancePercentage: response.attendancePercentage,
          selectedDate: targetDate,
          clearStartDate: true,
          clearEndDate: true,
        ),
      );

      _applyFilterAndSearch();
    } catch (e) {
      emit(
        state.copyWith(
          status: SAAttendanceStatus.error,
          errorMessage: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> loadAttendanceWithRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(state.copyWith(status: SAAttendanceStatus.loading));

    try {
      final response = await _repository.getAllAttendance(
        startDate: _formatApiDate(startDate),
        endDate: _formatApiDate(endDate),
        pageNumber: 1,
        pageSize: 500,
      );

      emit(
        state.copyWith(
          status: SAAttendanceStatus.success,
          records: response.attendances,
          totalEmployees: response.totalEmployees,
          employeesWithAttendance: response.employeesWithAttendance,
          employeesWithDeparture: response.employeesWithDeparture,
          attendancePercentage: response.attendancePercentage,
          selectedDate: startDate,
          startDate: startDate,
          endDate: endDate,
        ),
      );

      _applyFilterAndSearch();
    } catch (e) {
      emit(
        state.copyWith(
          status: SAAttendanceStatus.error,
          errorMessage: AppException.from(e).message,
        ),
      );
    }
  }

  Future<void> changeDate(DateTime newDate) async {
    await loadAttendance(date: newDate);
  }

  Future<void> goToPreviousDay() async {
    final prev = state.selectedDate.subtract(const Duration(days: 1));
    await changeDate(prev);
  }

  Future<void> goToNextDay() async {
    final next = state.selectedDate.add(const Duration(days: 1));
    await changeDate(next);
  }

  Future<void> goToToday() async {
    await changeDate(DateTime.now());
  }

  void applyFilter(AttendanceFilter filter) {
    emit(state.copyWith(activeFilter: filter));
    _applyFilterAndSearch();
  }

  void applySearch(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilterAndSearch();
  }

  void applyDeviceTypeFilter(int? deviceType) {
    emit(state.copyWith(
      deviceTypeFilter: deviceType,
      clearDeviceTypeFilter: deviceType == null,
    ));
    _applyFilterAndSearch();
  }

  void applyDepartmentFilter(int? departmentId) {
    emit(state.copyWith(
      selectedDepartmentId: departmentId,
      clearDepartmentId: departmentId == null,
    ));
    _applyFilterAndSearch();
  }

  void clearAllFilters() {
    emit(state.copyWith(
      activeFilter: AttendanceFilter.all,
      searchQuery: '',
      clearDeviceTypeFilter: true,
      clearDepartmentId: true,
    ));
    _applyFilterAndSearch();
  }

  void toggleExpand(String employeeName) {
    final newExpanded =
        state.expandedEmployeeId == employeeName ? null : employeeName;
    emit(state.copyWith(expandedEmployeeId: newExpanded));
  }

  void _applyFilterAndSearch() {
    List<AttendanceRecordModel> filtered = List.of(state.records);

    // 1) Attendance status filter
    switch (state.activeFilter) {
      case AttendanceFilter.all:
        break;
      case AttendanceFilter.present:
        filtered = filtered.where((r) => r.isStillPresent).toList();
        break;
      case AttendanceFilter.absent:
        filtered = filtered.where((r) => r.isAbsent).toList();
        break;
    }

    // 2) Device type filter
    if (state.deviceTypeFilter != null) {
      filtered = filtered
          .where((r) => r.deviceType == state.deviceTypeFilter)
          .toList();
    }

    // 3) Department filter (client-side via employee map)
    if (state.selectedDepartmentId != null && _employeeDeptMap.isNotEmpty) {
      filtered = filtered.where((r) {
        final deptId = _employeeDeptMap[r.employeeName.toLowerCase()];
        return deptId == state.selectedDepartmentId;
      }).toList();
    }

    // 4) Search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered
          .where((r) => r.employeeName.toLowerCase().contains(query))
          .toList();
    }

    // Recompute stats from filtered data
    final total = filtered.length;
    final withAttendance = filtered.where((r) => !r.isAbsent).length;
    final withDeparture = filtered.where((r) => r.hasDeparted).length;
    final percentage = total > 0 ? (withAttendance / total) * 100.0 : 0.0;

    emit(state.copyWith(
      filteredRecords: filtered,
      totalEmployees: total,
      employeesWithAttendance: withAttendance,
      employeesWithDeparture: withDeparture,
      attendancePercentage: percentage,
    ));
  }

  Future<void> exportPdf() async {
    emit(state.copyWith(isExportingPdf: true));

    try {
      final now = DateTime.now();
      await _repository.downloadMonthlyPdf(
        month: now.month,
        year: now.year,
      );

      emit(state.copyWith(isExportingPdf: false));
    } catch (e) {
      emit(
        state.copyWith(
          isExportingPdf: false,
          errorMessage: AppException.from(e).message,
        ),
      );
    }
  }
}
