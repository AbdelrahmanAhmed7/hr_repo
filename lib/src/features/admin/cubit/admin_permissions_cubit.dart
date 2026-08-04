import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/department_permission.dart';
import '../repository/admin_permissions_repository.dart';
import 'admin_permissions_state.dart';

class AdminPermissionsCubit extends Cubit<AdminPermissionsState> {
  final AdminPermissionsRepository _repository;

  AdminPermissionsCubit(this._repository)
    : super(const AdminPermissionsState());

  /// Initial load — also fetches stable per-status counts
  Future<void> loadPermissions({bool refresh = false}) async {
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
      final response = await _repository.getDepartmentPermissions(
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
          : await _repository.getDepartmentPermissions(
              pageNumber: 1,
              pageSize: 1,
              userId: state.userIdFilter,
              dateFrom: state.dateFromFilter,
              dateTo: state.dateToFilter,
              search: state.searchFilter,
            );
      if (isClosed) return;
      final pendingResp = await _repository.getDepartmentPermissions(
        pageNumber: 1,
        pageSize: 1,
        status: 'Pending',
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;
      final approvedResp = await _repository.getDepartmentPermissions(
        pageNumber: 1,
        pageSize: 1,
        status: 'Approved',
        userId: state.userIdFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchFilter,
      );
      if (isClosed) return;
      final rejectedResp = await _repository.getDepartmentPermissions(
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
      final response = await _repository.getDepartmentPermissions(
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
    loadPermissions(refresh: true);
  }

  void setUserIdFilter(String? userId) {
    emit(state.copyWith(userIdFilter: userId));
    loadPermissions(refresh: true);
  }

  /// Load permissions filtered by a specific employee userId
  Future<void> loadPermissionsForUser(String userId) async {
    emit(AdminPermissionsState(userIdFilter: userId));
    await loadPermissions(refresh: true);
  }

  void setDateFilter({String? dateFrom, String? dateTo}) {
    emit(state.copyWith(dateFromFilter: dateFrom, dateToFilter: dateTo));
    loadPermissions(refresh: true);
  }

  void setSearch(String? search) {
    emit(state.copyWith(searchFilter: search));
    loadPermissions(refresh: true);
  }

  void clearFilters() {
    emit(const AdminPermissionsState());
    loadPermissions(refresh: true);
  }

  Future<bool> approvePermission(int id) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _repository.approvePermission(id);
      _updateItemStatus(id, 'Approved');
      // Update stable counts
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

  Future<bool> rejectPermission(int id, {String? rejectionReason}) async {
    emit(state.copyWith(isUpdating: true, clearError: true));
    try {
      await _repository.rejectPermission(id, rejectionReason: rejectionReason);
      _updateItemStatus(id, 'Rejected', rejectionReason: rejectionReason);
      // Update stable counts
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

  void _updateItemStatus(int id, String newStatus, {String? rejectionReason}) {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return DepartmentPermission(
          id: item.id,
          userId: item.userId,
          employeeNameAr: item.employeeNameAr,
          employeeNameEn: item.employeeNameEn,
          date: item.date,
          startTime: item.startTime,
          endTime: item.endTime,
          reason: item.reason,
          createdAt: item.createdAt,
          status: newStatus,
          rejectionReason: rejectionReason ?? item.rejectionReason,
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updated));
  }
}
