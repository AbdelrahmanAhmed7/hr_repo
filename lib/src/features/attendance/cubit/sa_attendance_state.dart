import '../models/attendance_record_model.dart';

enum SAAttendanceStatus { initial, loading, success, error }

enum AttendanceFilter { all, present, absent }

class DepartmentOption {
  final int id;
  final String name;

  const DepartmentOption({required this.id, required this.name});

  factory DepartmentOption.fromJson(Map<String, dynamic> json) {
    return DepartmentOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class SAAttendanceState {
  final SAAttendanceStatus status;
  final List<AttendanceRecordModel> records;
  final List<AttendanceRecordModel> filteredRecords;
  final int totalEmployees;
  final int employeesWithAttendance;
  final int employeesAbsent;
  final int employeesWithDeparture;
  final double attendancePercentage;
  final DateTime selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? deviceTypeFilter;
  final AttendanceFilter activeFilter;
  final String searchQuery;
  final String? expandedEmployeeId;
  final String? errorMessage;
  final bool isExportingPdf;
  final int? selectedDepartmentId;
  final List<DepartmentOption> departments;

  const SAAttendanceState({
    this.status = SAAttendanceStatus.initial,
    this.records = const [],
    this.filteredRecords = const [],
    this.totalEmployees = 0,
    this.employeesWithAttendance = 0,
    this.employeesAbsent = 0,
    this.employeesWithDeparture = 0,
    this.attendancePercentage = 0,
    required this.selectedDate,
    this.startDate,
    this.endDate,
    this.deviceTypeFilter,
    this.activeFilter = AttendanceFilter.all,
    this.searchQuery = '',
    this.expandedEmployeeId,
    this.errorMessage,
    this.isExportingPdf = false,
    this.selectedDepartmentId,
    this.departments = const [],
  });

  factory SAAttendanceState.initial() =>
      SAAttendanceState(selectedDate: DateTime.now());

  SAAttendanceState copyWith({
    SAAttendanceStatus? status,
    List<AttendanceRecordModel>? records,
    List<AttendanceRecordModel>? filteredRecords,
    int? totalEmployees,
    int? employeesWithAttendance,
    int? employeesAbsent,
    int? employeesWithDeparture,
    double? attendancePercentage,
    DateTime? selectedDate,
    DateTime? startDate,
    DateTime? endDate,
    int? deviceTypeFilter,
    AttendanceFilter? activeFilter,
    String? searchQuery,
    String? expandedEmployeeId,
    String? errorMessage,
    bool? isExportingPdf,
    int? selectedDepartmentId,
    List<DepartmentOption>? departments,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearDeviceTypeFilter = false,
    bool clearDepartmentId = false,
  }) {
    return SAAttendanceState(
      status: status ?? this.status,
      records: records ?? this.records,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      employeesWithAttendance:
          employeesWithAttendance ?? this.employeesWithAttendance,
      employeesAbsent: employeesAbsent ?? this.employeesAbsent,
      employeesWithDeparture:
          employeesWithDeparture ?? this.employeesWithDeparture,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      selectedDate: selectedDate ?? this.selectedDate,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      deviceTypeFilter: clearDeviceTypeFilter
          ? null
          : (deviceTypeFilter ?? this.deviceTypeFilter),
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      expandedEmployeeId: expandedEmployeeId,
      errorMessage: errorMessage,
      isExportingPdf: isExportingPdf ?? this.isExportingPdf,
      selectedDepartmentId: clearDepartmentId
          ? null
          : (selectedDepartmentId ?? this.selectedDepartmentId),
      departments: departments ?? this.departments,
    );
  }

  int get absentCount => employeesAbsent;

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      deviceTypeFilter != null ||
      selectedDepartmentId != null;
}
