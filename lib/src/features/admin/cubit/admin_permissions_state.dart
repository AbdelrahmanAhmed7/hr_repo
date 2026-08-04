import '../models/department_permission.dart';

class AdminPermissionsState {
  final List<DepartmentPermission> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isUpdating;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int allCount;

  // Stable counts (fetched once without status filter, never reset by tab changes)
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  // Active filters
  final String? statusFilter;
  final String? userIdFilter;
  final String? dateFromFilter;
  final String? dateToFilter;
  final String? searchFilter;

  const AdminPermissionsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isUpdating = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.allCount = 0,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.statusFilter,
    this.userIdFilter,
    this.dateFromFilter,
    this.dateToFilter,
    this.searchFilter,
  });

  bool get hasNextPage => currentPage < totalPages;

  AdminPermissionsState copyWith({
    List<DepartmentPermission>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isUpdating,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    int? allCount,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
    String? statusFilter,
    String? userIdFilter,
    String? dateFromFilter,
    String? dateToFilter,
    String? searchFilter,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) {
    return AdminPermissionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      allCount: allCount ?? this.allCount,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      userIdFilter: userIdFilter ?? this.userIdFilter,
      dateFromFilter: dateFromFilter ?? this.dateFromFilter,
      dateToFilter: dateToFilter ?? this.dateToFilter,
      searchFilter: searchFilter ?? this.searchFilter,
    );
  }
}
