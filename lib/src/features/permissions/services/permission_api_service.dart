import 'package:dio/dio.dart';
import '../api/permission_api.dart';
import '../api/models/permission_request.dart';
import '../api/models/permission_response.dart';
import '../api/models/update_permission_status_request.dart';
import '../api/models/update_permission_status_response.dart';
import '../../../core/network/models/message_response.dart';

/// Service layer for Permission API calls
/// This service handles all API communication for permissions
class PermissionApiService {
  final PermissionApi _permissionApi;

  PermissionApiService(this._permissionApi);

  /// Create new permission request
  Future<PermissionResponse> createPermission({
    required String date, // YYYY-MM-DD
    required String startTime, // HH:mm:ss
    required String endTime, // HH:mm:ss
    required String reason, // Required
  }) async {
    try {
      final request = PermissionRequest(
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      return await _permissionApi.createPermission(request);
    } on DioException {
      rethrow;
    }
  }

  /// Update permission status
  Future<UpdatePermissionStatusResponse> updateStatus({
    required int id,
    required int status, // 1 = Pending, 2 = Approved, 3 = Rejected
    String? rejectionReason,
  }) async {
    try {
      final request = UpdatePermissionStatusRequest(
        status: status,
        rejectionReason: rejectionReason,
      );
      return await _permissionApi.updateStatus(id, request);
    } on DioException {
      rethrow;
    }
  }

  /// Get current user's permissions
  Future<List<PermissionResponse>> getMyPermissions() async {
    try {
      return await _permissionApi.getMyPermissions();
    } on DioException {
      rethrow;
    }
  }

  /// Get all permissions (HR only)
  Future<List<PermissionResponse>> getAllPermissions() async {
    try {
      return await _permissionApi.getAllPermissions();
    } on DioException {
      rethrow;
    }
  }

  Future<MessageResponse> remind({required int id}) async {
    try {
      return await _permissionApi.remind(id);
    } on DioException {
      rethrow;
    }
  }
}
