import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/create_overtime_request.dart';
import 'models/overtime_response.dart';
import 'models/overtime_status_item.dart';
import 'models/update_overtime_status_request.dart';
import 'models/update_overtime_status_response.dart';

part 'overtime_api.g.dart';

@RestApi()
abstract class OvertimeApi {
  factory OvertimeApi(Dio dio, {String baseUrl}) = _OvertimeApi;

  @POST('/api/Overtime')
  Future<OvertimeResponse> createOvertime(@Body() CreateOvertimeRequest body);

  @GET('/api/Overtime/my')
  Future<List<OvertimeResponse>> getMyOvertimeRequests();

  @GET('/api/Overtime/statuses')
  Future<List<OvertimeStatusItem>> getStatuses();

  @PUT('/api/Overtime/{id}/status')
  Future<UpdateOvertimeStatusResponse> updateStatus(
    @Path('id') int id,
    @Body() UpdateOvertimeStatusRequest body,
  );
}
