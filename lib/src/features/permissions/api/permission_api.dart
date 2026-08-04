import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import '../../../core/network/models/message_response.dart';

import 'models/permission_request.dart';
import 'models/permission_response.dart';
import 'models/update_permission_status_request.dart';
import 'models/update_permission_status_response.dart';

part 'permission_api.g.dart';

@RestApi()
abstract class PermissionApi {
  factory PermissionApi(Dio dio, {String baseUrl}) = _PermissionApi;

  @POST('/api/Permission')
  Future<PermissionResponse> createPermission(@Body() PermissionRequest body);

  @GET('/api/Permission/my')
  Future<List<PermissionResponse>> getMyPermissions();

  @GET('/api/Permission/all')
  Future<List<PermissionResponse>> getAllPermissions();

  @PUT('/api/Permission/{id}/status')
  Future<UpdatePermissionStatusResponse> updateStatus(
    @Path('id') int id,
    @Body() UpdatePermissionStatusRequest body,
  );

  @POST('/api/Permission/{id}/remind')
  Future<MessageResponse> remind(@Path('id') int id);
}