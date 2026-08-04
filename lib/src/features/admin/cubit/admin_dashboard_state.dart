import '../models/admin_dashboard_response.dart';

class AdminDashboardState {
  final bool isLoading;
  final String? error;
  final AdminDashboardResponse? data;

  AdminDashboardState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    String? error,
    AdminDashboardResponse? data,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }

  factory AdminDashboardState.initial() => AdminDashboardState();
}
