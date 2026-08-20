import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../hr/repository/employees_repository.dart';
import '../../data/models/punch_pair_model.dart';
import '../../data/models/punch_summary_model.dart';
import '../../repository/sa_attendance_repository.dart';
import 'punch_state.dart';

class PunchCubit extends Cubit<PunchState> {
  final SAAttendanceRepository _repository;
  final EmployeesRepository _employeesRepository;

  /// Maps userId -> departmentId for client-side department filtering
  final Map<String, int?> _userDeptMap = {};

  PunchCubit(this._repository, this._employeesRepository)
      : super(PunchState(
          fromDate: DateTime.now(),
          toDate: DateTime.now(),
        )) {
    loadDepartmentsAndEmployees();
    loadSummary();
  }

  Future<void> loadDepartmentsAndEmployees() async {
    emit(state.copyWithNullables(isLoadingEmployees: true));
    try {
      final departments = await _employeesRepository.getDepartments(
        pageSize: 50,
      );

      // Load employees (paginated) for dropdown + build user->dept map
      var page = 1;
      const pageSize = 100;
      int totalPages = 1;
      final options = <EmployeeOption>[];

      do {
        final response = await _employeesRepository.getEmployees(
          pageNumber: page,
          pageSize: pageSize,
          isActive: true,
        );
        totalPages = response.totalPages;
        for (final emp in response.items) {
          options.add(EmployeeOption(userId: emp.id, name: emp.fullName));
          _userDeptMap[emp.id] = emp.departmentId;
        }
        page++;
      } while (page <= totalPages && options.length < 500);

      options.sort((a, b) => a.name.compareTo(b.name));

      emit(state.copyWithNullables(
        departments: departments,
        employeeOptions: options,
        isLoadingEmployees: false,
      ));
    } catch (_) {
      emit(state.copyWithNullables(isLoadingEmployees: false));
    }
  }

  void selectEmployee(String? userId, String? name) {
    emit(state.copyWithNullables(
      selectedUserId: () => userId,
      selectedEmployeeName: () => name,
      expandedUserId: () => null,
      pairsCache: {},
    ));
    loadSummary(refresh: true);
  }

  void applyDepartmentFilter(int? departmentId) {
    emit(state.copyWithNullables(
      selectedDepartmentId: () => departmentId,
      expandedUserId: () => null,
      pairsCache: {},
    ));
    loadSummary(refresh: true);
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}-${d.year}';

  // ─── Summary ──────────────────────────────────────────────────────────────

  Future<void> loadSummary({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWithNullables(
        summaryCurrentPage: 1,
        summaryItems: [],
        filteredSummaryItems: [],
      ));
    }

    if (state.summaryCurrentPage == 1) {
      emit(state.copyWithNullables(summaryStatus: PunchStatus.loading));
    }

    try {
      final response = await _repository.getPunchSummary(
        userId: state.selectedUserId,
        from: _formatDate(state.fromDate),
        to: _formatDate(state.toDate),
        page: state.summaryCurrentPage,
        pageSize: 20,
      );

      final merged = [...state.summaryItems, ...response.items];
      emit(state.copyWithNullables(
        summaryStatus: PunchStatus.success,
        summaryItems: merged,
        filteredSummaryItems: _applyFilters(merged),
        summaryCurrentPage: response.pageNumber + 1,
        summaryTotalPages: response.totalPages,
      ));
    } catch (e) {
      emit(state.copyWithNullables(
        summaryStatus: PunchStatus.error,
        errorMessage: () => e.toString(),
      ));
    }
  }

  Future<void> loadMoreSummary() async {
    if (state.isLoadingMoreSummary) return;
    if (state.summaryCurrentPage > state.summaryTotalPages) return;

    emit(state.copyWithNullables(isLoadingMoreSummary: true));
    await loadSummary();
    emit(state.copyWithNullables(isLoadingMoreSummary: false));
  }

  // ─── Expand / Inline Pairs ────────────────────────────────────────────────

  Future<void> toggleExpand(String userId) async {
    // Collapse
    if (state.expandedUserId == userId) {
      emit(state.copyWithNullables(expandedUserId: () => null));
      return;
    }

    // Expand
    emit(state.copyWithNullables(expandedUserId: () => userId));

    // Lazy load if not cached
    if (!state.pairsCache.containsKey(userId)) {
      await _fetchPairsForUser(userId);
    }
  }

  Future<void> _fetchPairsForUser(String userId) async {
    emit(state.copyWithNullables(pairsLoadingUserId: () => userId));

    try {
      final response = await _repository.getPunchPairs(
        userId: userId,
        from: _formatDate(state.fromDate),
        to: _formatDate(state.toDate),
        page: 1,
        pageSize: 50,
      );

      final updated = Map<String, List<PunchPairModel>>.from(state.pairsCache);
      updated[userId] = response.items;

      emit(state.copyWithNullables(
        pairsCache: updated,
        pairsLoadingUserId: () => null,
      ));
    } catch (_) {
      // Store empty list so UI can show "لا يوجد بيانات"
      final updated = Map<String, List<PunchPairModel>>.from(state.pairsCache);
      updated[userId] = [];
      emit(state.copyWithNullables(
        pairsCache: updated,
        pairsLoadingUserId: () => null,
      ));
    }
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  void searchEmployees(String query) {
    emit(state.copyWithNullables(
      searchQuery: query,
      filteredSummaryItems: _applyFilters(state.summaryItems),
    ));
  }

  List<PunchSummaryModel> _applyFilters(List<PunchSummaryModel> items) {
    var result = List<PunchSummaryModel>.from(items);

    // Client-side name search
    if (state.searchQuery.trim().isNotEmpty) {
      result = result
          .where((e) => e.employeeName.contains(state.searchQuery.trim()))
          .toList();
    }

    // Department filter (client-side via user map)
    if (state.selectedDepartmentId != null && _userDeptMap.isNotEmpty) {
      result = result
          .where((e) =>
              _userDeptMap[e.userId] == state.selectedDepartmentId)
          .toList();
    }

    return result;
  }

  // ─── Date Navigation ──────────────────────────────────────────────────────

  void goToPreviousDay() {
    final newFrom = state.fromDate.subtract(const Duration(days: 1));
    final newTo = state.toDate.subtract(const Duration(days: 1));
    emit(state.copyWithNullables(
      fromDate: newFrom,
      toDate: newTo,
      expandedUserId: () => null,
      pairsCache: {},
    ));
    loadSummary(refresh: true);
  }

  void goToNextDay() {
    if (state.isToday) return;
    final newFrom = state.fromDate.add(const Duration(days: 1));
    final newTo = state.toDate.add(const Duration(days: 1));
    emit(state.copyWithNullables(
      fromDate: newFrom,
      toDate: newTo,
      expandedUserId: () => null,
      pairsCache: {},
    ));
    loadSummary(refresh: true);
  }

  void goToToday() {
    final now = DateTime.now();
    emit(state.copyWithNullables(
      fromDate: now,
      toDate: now,
      expandedUserId: () => null,
      pairsCache: {},
    ));
    loadSummary(refresh: true);
  }

  void applyDateFilter({required DateTime from, required DateTime to}) {
    emit(state.copyWithNullables(
      fromDate: from,
      toDate: to,
      expandedUserId: () => null,
      pairsCache: {},
    ));
    loadSummary(refresh: true);
  }

  // ─── Filter Helpers ───────────────────────────────────────────────────────

  void clearEmployeeFilter() {
    emit(state.copyWithNullables(
      selectedUserId: () => null,
      selectedEmployeeName: () => null,
    ));
    loadSummary(refresh: true);
  }

  void clearFilters() {
    final now = DateTime.now();
    emit(state.copyWithNullables(
      selectedUserId: () => null,
      selectedEmployeeName: () => null,
      selectedDepartmentId: () => null,
      fromDate: now,
      toDate: now,
      expandedUserId: () => null,
      pairsCache: {},
      searchQuery: '',
    ));
    loadSummary(refresh: true);
  }
}
