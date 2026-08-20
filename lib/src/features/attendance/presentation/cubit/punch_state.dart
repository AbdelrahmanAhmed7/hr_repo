import '../../../../features/hr/models/department_option.dart';
import '../../data/models/punch_summary_model.dart';
import '../../data/models/punch_pair_model.dart';

enum PunchStatus { initial, loading, success, error }

class EmployeeOption {
  final String userId;
  final String name;

  const EmployeeOption({required this.userId, required this.name});
}

class PunchState {
  final PunchStatus summaryStatus;
  final List<PunchSummaryModel> summaryItems;
  final List<PunchSummaryModel> filteredSummaryItems;
  final int summaryTotalPages;
  final int summaryCurrentPage;
  final String? selectedUserId;
  final String? selectedEmployeeName;
  final DateTime fromDate;
  final DateTime toDate;
  final String? errorMessage;
  final bool isLoadingMoreSummary;

  // Filters: employee dropdown + department
  final List<EmployeeOption> employeeOptions;
  final bool isLoadingEmployees;
  final List<DepartmentOption> departments;
  final int? selectedDepartmentId;

  // Expand / inline pairs
  final String? expandedUserId;
  final Map<String, List<PunchPairModel>> pairsCache;
  final String? pairsLoadingUserId;

  // Client-side search
  final String searchQuery;

  const PunchState({
    this.summaryStatus = PunchStatus.initial,
    this.summaryItems = const [],
    this.filteredSummaryItems = const [],
    this.summaryTotalPages = 1,
    this.summaryCurrentPage = 1,
    this.selectedUserId,
    this.selectedEmployeeName,
    required this.fromDate,
    required this.toDate,
    this.errorMessage,
    this.isLoadingMoreSummary = false,
    this.employeeOptions = const [],
    this.isLoadingEmployees = false,
    this.departments = const [],
    this.selectedDepartmentId,
    this.expandedUserId,
    this.pairsCache = const {},
    this.pairsLoadingUserId,
    this.searchQuery = '',
  });

  PunchState copyWithNullables({
    PunchStatus? summaryStatus,
    List<PunchSummaryModel>? summaryItems,
    List<PunchSummaryModel>? filteredSummaryItems,
    int? summaryTotalPages,
    int? summaryCurrentPage,
    String? Function()? selectedUserId,
    String? Function()? selectedEmployeeName,
    DateTime? fromDate,
    DateTime? toDate,
    String? Function()? errorMessage,
    bool? isLoadingMoreSummary,
    List<EmployeeOption>? employeeOptions,
    bool? isLoadingEmployees,
    List<DepartmentOption>? departments,
    int? Function()? selectedDepartmentId,
    String? Function()? expandedUserId,
    Map<String, List<PunchPairModel>>? pairsCache,
    String? Function()? pairsLoadingUserId,
    String? searchQuery,
  }) {
    return PunchState(
      summaryStatus: summaryStatus ?? this.summaryStatus,
      summaryItems: summaryItems ?? this.summaryItems,
      filteredSummaryItems: filteredSummaryItems ?? this.filteredSummaryItems,
      summaryTotalPages: summaryTotalPages ?? this.summaryTotalPages,
      summaryCurrentPage: summaryCurrentPage ?? this.summaryCurrentPage,
      selectedUserId:
          selectedUserId != null ? selectedUserId() : this.selectedUserId,
      selectedEmployeeName: selectedEmployeeName != null
          ? selectedEmployeeName()
          : this.selectedEmployeeName,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
      isLoadingMoreSummary: isLoadingMoreSummary ?? this.isLoadingMoreSummary,
      employeeOptions: employeeOptions ?? this.employeeOptions,
      isLoadingEmployees: isLoadingEmployees ?? this.isLoadingEmployees,
      departments: departments ?? this.departments,
      selectedDepartmentId: selectedDepartmentId != null
          ? selectedDepartmentId()
          : this.selectedDepartmentId,
      expandedUserId:
          expandedUserId != null ? expandedUserId() : this.expandedUserId,
      pairsCache: pairsCache ?? this.pairsCache,
      pairsLoadingUserId: pairsLoadingUserId != null
          ? pairsLoadingUserId()
          : this.pairsLoadingUserId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isToday {
    final now = DateTime.now();
    return toDate.year == now.year &&
        toDate.month == now.month &&
        toDate.day == now.day;
  }

  bool get isSingleDay =>
      fromDate.year == toDate.year &&
      fromDate.month == toDate.month &&
      fromDate.day == toDate.day;

  /// Show date range chip only when NOT viewing today as a single day
  bool get showDateChip => !isSingleDay || !isToday;

  bool get hasActiveFilters =>
      selectedEmployeeName != null || showDateChip || selectedDepartmentId != null;
}
