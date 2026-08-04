import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/home_api_response.dart';

part 'home_api.g.dart';

@RestApi()
abstract class HomeApi {
  factory HomeApi(Dio dio, {String baseUrl}) = _HomeApi;

  @GET('/api/Home')
  Future<HomeApiResponse> getHomeData();

  @GET('/api/Home/viewall')
  Future<List<HomeRequestItem>> getAllRequests({@Query('month') int? month});

  @GET('/api/Home/viewallpending')
  Future<List<HomeRequestItem>> getPendingRequests({@Query('month') int? month});

  @GET('/api/Home/viewallaccepted')
  Future<List<HomeRequestItem>> getAcceptedRequests({@Query('month') int? month});

  @GET('/api/Home/viewallrejected')
  Future<List<HomeRequestItem>> getRejectedRequests({@Query('month') int? month});

  // Personal requests endpoints (current user only)
  @GET('/api/Leave/my')
  Future<List<HomeRequestItem>> getMyLeaves();

  @GET('/api/Permission/my')
  Future<List<HomeRequestItem>> getMyPermissions();

  @GET('/api/Assignment/my')
  Future<List<HomeRequestItem>> getMyAssignments();

  @GET('/api/Overtime/my')
  Future<List<HomeRequestItem>> getMyOvertime();
}
