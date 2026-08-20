import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_exception.dart';
import '../models/department_leave.dart';
import '../repository/admin_leaves_repository.dart';
import 'admin_leaves_state.dart';

class AdminLeavesCubit extends Cubit<AdminLeavesState> {
  final AdminLeavesRepository _repository;
  AdminLeavesCubit(this._repository) : super(const AdminLeavesState());

  Future<void> loadLeaves({bool refresh = false}) async {
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
      final response = await _repository.getDepartmentLeaves(
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
          : await _repository.getDepartmentLeaves(
              pageNumber: 1,
              pageSize: 1,
              userId: state.userIdFilter,
              dateFrom: state.dateFromFilter,
              dateTo: state.dateToFilter,
              search: state.searchFilter,
            );
      if (isClosed) return;
      final pendingResp = await _repository.getDepartmentLeaves(
        pageNumber: 1,
        pageSize: 1,
        status: 'Pending',
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;
      final approvedResp = await _repository.getDepartmentLeaves(
        pageNumber: 1,
        pageSize: 1,
        status: 'Approved',
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;
      final rejectedResp = await _repository.getDepartmentLeaves(
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
      emit(state.copyWith(isLoading: false, error: AppException.from(e).message));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNextPage || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final response = await _repository.getDepartmentLeaves(
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
      emit(state.copyWith(isLoadingMore: false, error: AppException.from(e).message));
    }
  }

  void setStatusFilter(String? status) {
    if (state.statusFilter == status) return;
    emit(
      state.copyWith(statusFilter: status, clearStatusFilter: status == null),
    );
    loadLeaves(refresh: true);
  }

  void setUserIdFilter(String? userId) {
    emit(state.copyWith(userIdFilter: userId));
    loadLeaves(refresh: true);
  }

  Future<void> loadLeavesForUser(String userId) async {
    emit(AdminLeavesState(userIdFilter: userId));
    await loadLeaves(refresh: true);
  }

  void setDateFilter({String? dateFrom, String? dateTo}) {
    emit(state.copyWith(dateFromFilter: dateFrom, dateToFilter: dateTo));
    loadLeaves(refresh: true);
  }

  void setSearch(String? search) {
    emit(state.copyWith(searchFilter: search));
    loadLeaves(refresh: true);
  }

  void clearFilters() {
    emit(const AdminLeavesState());
    loadLeaves(refresh: true);
  }

  Future<bool> approveLeave(int id) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _repository.approveLeave(id);
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
      emit(state.copyWith(isUpdating: false, error: AppException.from(e).message));
      return false;
    }
  }

  Future<bool> rejectLeave(int id, {String? rejectionReason}) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _repository.rejectLeave(id, rejectionReason: rejectionReason);
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
      emit(state.copyWith(isUpdating: false, error: AppException.from(e).message));
      return false;
    }
  }

  void _updateStatus(int id, String newStatus, {String? rejectionReason}) {
    final updated = state.items.map((item) {
      if (item.id != id) return item;
      return DepartmentLeave(
        id: item.id,
        userId: item.userId,
        employeeNameAr: item.employeeNameAr,
        employeeNameEn: item.employeeNameEn,
        startDate: item.startDate,
        endDate: item.endDate,
        reason: item.reason,
        createdAt: item.createdAt,
        status: newStatus,
        rejectionReason: rejectionReason ?? item.rejectionReason,
        leaveType: item.leaveType,
        medicalReportUrl: item.medicalReportUrl,
      );
    }).toList();
    emit(state.copyWith(items: updated));
  }
}
