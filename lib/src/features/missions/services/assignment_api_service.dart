import 'package:dio/dio.dart';
import '../api/assignment_api.dart';
import '../api/models/assignment_request.dart';
import '../api/models/assignment_response.dart';
import '../api/models/update_status_request.dart';
import '../api/models/update_status_response.dart';
import '../../../core/network/models/message_response.dart';

/// Service layer for Assignment API calls
/// This service handles all API communication for assignments
class AssignmentApiService {
  final AssignmentApi _assignmentApi;

  AssignmentApiService(this._assignmentApi);

  /// Create new assignment
  Future<AssignmentResponse> createAssignment({
    required String where,
    required String startDate, // YYYY-MM-DD
    required String endDate, // YYYY-MM-DD
    required String startTime, // HH:mm:ss
    required String endTime, // HH:mm:ss
    required String reason,
  }) async {
    try {
      final request = AssignmentRequest(
        where: where,
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      return await _assignmentApi.createAssignment(request);
    } on DioException {
      rethrow;
    }
  }

  /// Update assignment status
  Future<UpdateStatusResponse> updateStatus({
    required int id,
    required int status, // 1 = Pending, 2 = Approved, 3 = Rejected
    String? rejectionReason,
  }) async {
    try {
      final request = UpdateStatusRequest(
        status: status,
        rejectionReason: rejectionReason,
      );
      return await _assignmentApi.updateStatus(id, request);
    } on DioException {
      rethrow;
    }
  }

  /// Get current user's assignments
  Future<List<AssignmentResponse>> getMyAssignments() async {
    try {
      return await _assignmentApi.getMyAssignments();
    } on DioException {
      rethrow;
    }
  }

  /// Get all assignments (HR only)
  Future<List<AssignmentResponse>> getAllAssignments() async {
    try {
      return await _assignmentApi.getAllAssignments();
    } on DioException {
      rethrow;
    }
  }

  Future<MessageResponse> remind({required int id}) async {
    try {
      return await _assignmentApi.remind(id);
    } on DioException {
      rethrow;
    }
  }
}