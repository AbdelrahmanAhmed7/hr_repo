import 'package:dio/dio.dart';

import '../api/models/create_overtime_request.dart';
import '../api/models/overtime_response.dart';
import '../api/models/overtime_status_item.dart';
import '../api/models/update_overtime_status_request.dart';
import '../api/models/update_overtime_status_response.dart';
import '../api/overtime_api.dart';

class OvertimeApiService {
  final OvertimeApi _overtimeApi;

  OvertimeApiService(this._overtimeApi);

  Future<OvertimeResponse> createOvertime({
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    try {
      final request = CreateOvertimeRequest(
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      return await _overtimeApi.createOvertime(request);
    } on DioException {
      rethrow;
    }
  }

  Future<List<OvertimeResponse>> getMyOvertimeRequests() async {
    try {
      return await _overtimeApi.getMyOvertimeRequests();
    } on DioException {
      rethrow;
    }
  }

  Future<List<OvertimeStatusItem>> getStatuses() async {
    try {
      return await _overtimeApi.getStatuses();
    } on DioException {
      rethrow;
    }
  }

  Future<UpdateOvertimeStatusResponse> updateStatus({
    required int id,
    required int status,
    String? rejectionReason,
  }) async {
    try {
      final request = UpdateOvertimeStatusRequest(
        status: status,
        rejectionReason: rejectionReason,
      );
      return await _overtimeApi.updateStatus(id, request);
    } on DioException {
      rethrow;
    }
  }
}
