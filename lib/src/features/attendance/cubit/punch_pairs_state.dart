import '../models/punch_pair.dart';

enum PunchPairsStatus { initial, loading, success, error }

class EmployeeOption {
  final String userId;
  final String name;

  const EmployeeOption({required this.userId, required this.name});
}

class PunchPairsState {
  final PunchPairsStatus status;
  final List<PunchPair> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  // Filters
  final String? selectedUserId;
  final String? selectedEmployeeName;
  final DateTime? fromDate;
  final DateTime? toDate;

  // Employee options for dropdown
  final List<EmployeeOption> employeeOptions;
  final bool isLoadingEmployees;

  final String? errorMessage;

  const PunchPairsState({
    this.status = PunchPairsStatus.initial,
    this.items = const [],
    this.pageNumber = 1,
    this.pageSize = 15,
    this.totalCount = 0,
    this.totalPages = 1,
    this.selectedUserId,
    this.selectedEmployeeName,
    this.fromDate,
    this.toDate,
    this.employeeOptions = const [],
    this.isLoadingEmployees = false,
    this.errorMessage,
  });

  factory PunchPairsState.initial() => const PunchPairsState();

  PunchPairsState copyWith({
    PunchPairsStatus? status,
    List<PunchPair>? items,
    int? pageNumber,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    String? selectedUserId,
    String? selectedEmployeeName,
    DateTime? fromDate,
    DateTime? toDate,
    List<EmployeeOption>? employeeOptions,
    bool? isLoadingEmployees,
    String? errorMessage,
    bool clearUserId = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearError = false,
  }) {
    return PunchPairsState(
      status: status ?? this.status,
      items: items ?? this.items,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      selectedUserId: clearUserId
          ? null
          : (selectedUserId ?? this.selectedUserId),
      selectedEmployeeName: clearUserId
          ? null
          : (selectedEmployeeName ?? this.selectedEmployeeName),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      employeeOptions: employeeOptions ?? this.employeeOptions,
      isLoadingEmployees: isLoadingEmployees ?? this.isLoadingEmployees,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasFilters =>
      selectedUserId != null || fromDate != null || toDate != null;
}
