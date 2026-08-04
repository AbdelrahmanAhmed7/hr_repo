import '../api/super_admin_dashboard_api.dart';
import '../models/super_admin_dashboard_response.dart';

class SuperAdminDashboardService {
  final SuperAdminDashboardApi _api;

  SuperAdminDashboardService(this._api);

  Future<SuperAdminDashboardResponse> getSuperAdminDashboard() async {
    return await _api.getSuperAdminDashboard();
  }
}
