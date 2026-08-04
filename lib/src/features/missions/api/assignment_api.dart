import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import '../../../core/network/models/message_response.dart';

import 'models/assignment_request.dart';
import 'models/assignment_response.dart';
import 'models/update_status_request.dart';
import 'models/update_status_response.dart';

part 'assignment_api.g.dart';

@RestApi()
abstract class AssignmentApi {
  factory AssignmentApi(Dio dio, {String baseUrl}) = _AssignmentApi;

  @POST('/api/Assignment')
  Future<AssignmentResponse> createAssignment(@Body() AssignmentRequest body);

  @PUT('/api/Assignment/{id}/status')
  Future<UpdateStatusResponse> updateStatus(
    @Path('id') int id,
    @Body() UpdateStatusRequest body,
  );

  @GET('/api/Assignment/my')
  Future<List<AssignmentResponse>> getMyAssignments();

  @GET('/api/Assignment/all')
  Future<List<AssignmentResponse>> getAllAssignments();

  @POST('/api/Assignment/{id}/remind')
  Future<MessageResponse> remind(@Path('id') int id);
}
