import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../core/network/models/message_response.dart';
import 'models/update_leave_status_request.dart';
import 'models/update_leave_status_response.dart';
import '../models/leave_request_model.dart';
import '../models/leave_type_model.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_with_balance_response.dart';

part 'leaves_api.g.dart';

@RestApi()
abstract class LeavesApi {
  factory LeavesApi(Dio dio, {String baseUrl}) = _LeavesApi;

  @GET('/api/Leave/my')
  Future<List<LeaveRequestModel>> getMyLeaves();

  @GET('/api/Leave/my/balance')
  Future<LeaveBalanceModel> getMyLeaveBalance();

  @GET('/api/Leave/my/with-balance')
  Future<LeaveWithBalanceResponse> getMyLeavesWithBalance();

  @GET('/api/Leave/types')
  Future<List<LeaveTypeModel>> getLeaveTypes();

  @POST('/api/Leave')
  @MultiPart()
  Future<void> submitLeave(
    @Part(name: 'StartDate') String startDate,
    @Part(name: 'EndDate') String endDate,
    @Part(name: 'Reason') String reason,
    @Part(name: 'LeaveType') int leaveType,
    @Part(name: 'MedicalReport') File? medicalReport,
  );

  @PUT('/api/Leave/{id}/status')
  Future<UpdateLeaveStatusResponse> updateStatus(
    @Path('id') int id,
    @Body() UpdateLeaveStatusRequest body,
  );

  @POST('/api/Leave/{id}/remind')
  Future<MessageResponse> remind(@Path('id') int id);
}
