import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/hr_home_response.dart';

part 'hr_home_api.g.dart';

@RestApi()
abstract class HrHomeApi {
  factory HrHomeApi(Dio dio, {String baseUrl}) = _HrHomeApi;

  @GET('/api/Home/hr')
  Future<HrHomeResponse> getHrHomeData();
}
