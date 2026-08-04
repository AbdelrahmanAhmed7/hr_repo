import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/department_assignment.dart';
import '../repository/admin_assignments_repository.dart';
import 'admin_assignments_state.dart';

class AdminAssignmentsCubit extends Cubit<AdminAssignmentsState> {
  final AdminAssignmentsRepository _repository;
  AdminAssignmentsCubit(this._repository)
    : super(const AdminAssignmentsState());

  Future<void> loadAssignments({bool refresh = false}) async {
    if (state.isLoading) return;
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        items: refresh ? [] : state.items,
        currentPage: 1,
      ),
    );
    try {
      final response = await _repository.getDepartmentAssignments(
        pageNumber: 1,
        status: state.statusFilter,
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;

      final allResp = state.statusFilter == null
          ? response
          : await _repository.getDepartmentAssignments(
              pageNumber: 1,
              pageSize: 1,
              userId: state.userIdFilter,
              dateFrom: state.dateFromFilter,
              dateTo: state.dateToFilter,
              search: state.searchFilter,
            );
      if (isClosed) return;
      final pendingResp = await _repository.getDepartmentAssignments(
        pageNumber: 1,
        pageSize: 1,
        status: 'Pending',
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;
      final approvedResp = await _repository.getDepartmentAssignments(
        pageNumber: 1,
        pageSize: 1,
        status: 'Approved',
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;
      final rejectedResp = await _repository.getDepartmentAssignments(
        pageNumber: 1,
        pageSize: 1,
        status: 'Rejected',
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          items: response.items,
          currentPage: response.pageNumber,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
          allCount: allResp.totalCount,
          pendingCount: pendingResp.totalCount,
          approvedCount: approvedResp.totalCount,
          rejectedCount: rejectedResp.totalCount,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNextPage || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final response = await _repository.getDepartmentAssignments(
        pageNumber: state.currentPage + 1,
        status: state.statusFilter,
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          items: [...state.items, ...response.items],
          currentPage: response.pageNumber,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }

  void setStatusFilter(String? status) {
    if (state.statusFilter == status) return;
    emit(
      state.copyWith(statusFilter: status, clearStatusFilter: status == null),
    );
    loadAssignments(refresh: true);
  }

  void setUserIdFilter(String? userId) {
    emit(state.copyWith(userIdFilter: userId));
    loadAssignments(refresh: true);
  }

  Future<void> loadAssignmentsForUser(String userId) async {
    emit(AdminAssignmentsState(userIdFilter: userId));
    await loadAssignments(refresh: true);
  }

  void setDateFilter({String? dateFrom, String? dateTo}) {
    emit(state.copyWith(dateFromFilter: dateFrom, dateToFilter: dateTo));
    loadAssignments(refresh: true);
  }

  void setSearch(String? search) {
    emit(state.copyWith(searchFilter: search));
    loadAssignments(refresh: true);
  }

  void clearFilters() {
    emit(const AdminAssignmentsState());
    loadAssignments(refresh: true);
  }

  Future<bool> approveAssignment(int id) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _repository.approveAssignment(id);
      _updateStatus(id, 'Approved');
      emit(
        state.copyWith(
          isUpdating: false,
          pendingCount: (state.pendingCount - 1).clamp(0, 9999),
          approvedCount: state.approvedCount + 1,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(isUpdating: false, error: e.toString()));
      return false;
    }
  }

  Future<bool> rejectAssignment(int id, {String? rejectionReason}) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _repository.rejectAssignment(id, rejectionReason: rejectionReason);
      _updateStatus(id, 'Rejected', rejectionReason: rejectionReason);
      emit(
        state.copyWith(
          isUpdating: false,
          pendingCount: (state.pendingCount - 1).clamp(0, 9999),
          rejectedCount: state.rejectedCount + 1,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(isUpdating: false, error: e.toString()));
      return false;
    }
  }

  void _updateStatus(int id, String newStatus, {String? rejectionReason}) {
    final updated = state.items.map((item) {
      if (item.id != id) return item;
      return DepartmentAssignment(
        id: item.id,
        userId: item.userId,
        employeeNameAr: item.employeeNameAr,
        employeeNameEn: item.employeeNameEn,
        where: item.where,
        startDate: item.startDate,
        endDate: item.endDate,
        startTime: item.startTime,
        endTime: item.endTime,
        reason: item.reason,
        createdAt: item.createdAt,
        status: newStatus,
        rejectionReason: rejectionReason ?? item.rejectionReason,
      );
    }).toList();
    emit(state.copyWith(items: updated));
  }
}
