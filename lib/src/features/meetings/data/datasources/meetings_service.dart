import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/department_response_model.dart';
import '../models/meeting_response_model.dart';

part 'meetings_service.g.dart';

@RestApi()
abstract class MeetingsService {
  factory MeetingsService(Dio dio, {String baseUrl}) = _MeetingsService;

  @GET('/api/Meeting')
  Future<MeetingResponseModel> getMeetings(
    @Query('pageNumber') int pageNumber,
    @Query('pageSize') int pageSize,
  );

  @POST('/api/Meeting')
  Future<void> createMeeting(@Body() Map<String, dynamic> body);

  @PUT('/api/Meeting/{id}')
  Future<void> updateMeeting(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/Meeting/{id}')
  Future<void> deleteMeeting(@Path('id') int id);

  @GET('/api/Department')
  Future<DepartmentResponseModel> getDepartments(
    @Query('pageNumber') int pageNumber,
    @Query('pageSize') int pageSize,
  );
}