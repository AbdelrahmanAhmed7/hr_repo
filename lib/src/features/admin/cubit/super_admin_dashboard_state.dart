import '../models/super_admin_dashboard_response.dart';

class SuperAdminDashboardState {
  final bool isLoading;
  final String? error;
  final SuperAdminDashboardResponse? data;

  SuperAdminDashboardState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  SuperAdminDashboardState copyWith({
    bool? isLoading,
    String? error,
    SuperAdminDashboardResponse? data,
  }) {
    return SuperAdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }

  factory SuperAdminDashboardState.initial() => SuperAdminDashboardState();
}
