import 'dart:io';
import '../api/leaves_api.dart';
import '../api/models/update_leave_status_request.dart';
import '../api/models/update_leave_status_response.dart';
import '../../../core/network/models/message_response.dart';
import '../models/leave_request_model.dart';
import '../models/leave_submission_model.dart';
import '../models/leave_type_model.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_with_balance_response.dart';

class LeavesApiService {
  final LeavesApi _leavesApi;

  LeavesApiService(this._leavesApi);

  Future<List<LeaveRequestModel>> getMyLeaves() async {
    return await _leavesApi.getMyLeaves();
  }

  Future<LeaveBalanceModel> getMyLeaveBalance() async {
    return await _leavesApi.getMyLeaveBalance();
  }

  Future<LeaveWithBalanceResponse> getMyLeavesWithBalance() async {
    return await _leavesApi.getMyLeavesWithBalance();
  }

  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    return await _leavesApi.getLeaveTypes();
  }

  Future<void> submitLeave({
    required LeaveSubmissionModel submission,
    required int leaveTypeId,
    File? medicalReport,
  }) async {
    return await _leavesApi.submitLeave(
      submission.startDate,
      submission.endDate,
      submission.reason,
      leaveTypeId,
      medicalReport,
    );
  }

  Future<UpdateLeaveStatusResponse> updateStatus({
    required int id,
    required int status,
    String? rejectionReason,
  }) async {
    final request = UpdateLeaveStatusRequest(
      status: status,
      rejectionReason: rejectionReason,
    );
    return await _leavesApi.updateStatus(id, request);
  }

  Future<MessageResponse> remind({required int id}) async {
    return await _leavesApi.remind(id);
  }
}
