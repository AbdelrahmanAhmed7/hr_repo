import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/admin_dashboard_response.dart';

part 'admin_dashboard_api.g.dart';

@RestApi()
abstract class AdminDashboardApi {
  factory AdminDashboardApi(Dio dio, {String baseUrl}) = _AdminDashboardApi;

  @GET('/api/AdminDashboard')
  Future<AdminDashboardResponse> getAdminDashboard();
}