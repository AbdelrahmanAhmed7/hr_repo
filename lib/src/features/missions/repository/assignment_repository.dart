import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/assignment_api_service.dart';
import '../models/mission.dart';
import '../../../core/network/models/message_response.dart';

/// Repository layer for Assignment feature
/// Handles business logic and data conversion (AssignmentResponse → Mission)
class AssignmentRepository {
  final AssignmentApiService _assignmentApiService;

  AssignmentRepository({
    required AssignmentApiService assignmentApiService,
  }) : _assignmentApiService = assignmentApiService;

  /// Get current user's assignments
  Future<List<Mission>> getMyAssignments() async {
    try {
      final responses = await _assignmentApiService.getMyAssignments();
      return responses.map((r) => Mission.fromAssignmentResponse(r)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Get all assignments (HR only)
  Future<List<Mission>> getAllAssignments() async {
    try {
      final responses = await _assignmentApiService.getAllAssignments();
      return responses.map((r) => Mission.fromAssignmentResponse(r)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Create new assignment
  Future<Mission> createAssignment({
    required String where,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime, // HH:mm:ss format
    required String endTime, // HH:mm:ss format
    required String reason,
  }) async {
    try {
      // Format dates as YYYY-MM-DD
      final startDateStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await _assignmentApiService.createAssignment(
        where: where,
        startDate: startDateStr,
        endDate: endDateStr,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );

      return Mission.fromAssignmentResponse(response);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Update assignment status (HR only)
  Future<Mission> updateAssignmentStatus({
    required int id,
    required int status, // 1 = Pending, 2 = Approved, 3 = Rejected
    String? rejectionReason,
    required Mission currentMission, // Current mission to update
  }) async {
    try {
      final response = await _assignmentApiService.updateStatus(
        id: id,
        status: status,
        rejectionReason: rejectionReason,
      );

      // Map status string to enum
      MissionStatus newStatus;
      final statusLower = response.status.toLowerCase();
      if (statusLower == 'approved') {
        newStatus = MissionStatus.approved;
      } else if (statusLower == 'rejected') {
        newStatus = MissionStatus.rejected;
      } else {
        newStatus = MissionStatus.pending;
      }

      return currentMission.copyWith(
        status: newStatus,
        rejectionReason: response.rejectionReason,
      );
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> setAssignmentStatus({
    required int id,
    required int status,
    String? rejectionReason,
  }) async {
    try {
      await _assignmentApiService.updateStatus(
        id: id,
        status: status,
        rejectionReason: rejectionReason,
      );
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<MessageResponse> remindAssignment({required int id}) async {
    try {
      return await _assignmentApiService.remind(id: id);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(dynamic e) {
    String errorMessage = 'حدث خطأ غير متوقع';
    
    if (e is DioException) {
      try {
        if (e.response?.data != null) {
          final data = e.response!.data;
          Map<String, dynamic> responseData;
          
          if (data is Map) {
            responseData = Map<String, dynamic>.from(data);
          } else if (data is String) {
            responseData = jsonDecode(data);
          } else {
            responseData = {};
          }
          
          // 1. Check for specific validation errors map
          if (responseData.containsKey('errors') && responseData['errors'] is Map) {
            final errors = responseData['errors'] as Map;
            final errorMessages = <String>[];
            
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.addAll(value.map((item) => item.toString()));
              } else {
                errorMessages.add(value.toString());
              }
            });
            
            if (errorMessages.isNotEmpty) {
              errorMessage = errorMessages.join('\n');
            }
          } 
          // 2. Check for "title" field (common in RFC 7807 problem details)
          else if (responseData.containsKey('title') && responseData['title'] != null) {
            errorMessage = responseData['title'].toString();
          }
          // 3. Check for "message" field
          else if (responseData.containsKey('message') && responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من الإنترنت';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'غير مصرح لك بالقيام بهذه العملية';
        }
      } catch (parseError) {
        debugPrint('Error parsing API response: $parseError');
      }
    } else if (e is String) {
      errorMessage = e;
    }
    
    return errorMessage;
  }
}
