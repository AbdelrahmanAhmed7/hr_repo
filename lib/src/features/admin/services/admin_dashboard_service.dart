import '../api/admin_dashboard_api.dart';
import '../models/admin_dashboard_response.dart';

class AdminDashboardService {
  final AdminDashboardApi _api;

  AdminDashboardService(this._api);

  Future<AdminDashboardResponse> getAdminDashboard() async {
    return await _api.getAdminDashboard();
  }
}
