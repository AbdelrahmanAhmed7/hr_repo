import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/super_admin_dashboard_response.dart';

part 'super_admin_dashboard_api.g.dart';

@RestApi()
abstract class SuperAdminDashboardApi {
  factory SuperAdminDashboardApi(Dio dio, {String baseUrl}) = _SuperAdminDashboardApi;

  @GET('/api/SuperAdminDashboard')
  Future<SuperAdminDashboardResponse> getSuperAdminDashboard();
}
