import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/permission_api_service.dart';
import '../models/permission_request.dart' as domain;
import '../api/models/permission_response.dart';
import '../../../core/network/models/message_response.dart';

/// Repository layer for Permission feature
/// Handles business logic and data conversion (PermissionResponse → PermissionRequest)
class PermissionRepository {
  final PermissionApiService _permissionApiService;

  PermissionRepository({
    required PermissionApiService permissionApiService,
  }) : _permissionApiService = permissionApiService;

  /// Get current user's permissions
  Future<List<domain.PermissionRequest>> getMyPermissions() async {
    try {
      final responses = await _permissionApiService.getMyPermissions();
      return responses.map((r) => _mapResponseToDomain(r)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('غير مصرح لك بالوصول');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      }
      throw Exception('حدث خطأ أثناء تحميل الإذونات');
    } catch (e) {
      rethrow;
    }
  }

  /// Get all permissions (HR only)
  Future<List<domain.PermissionRequest>> getAllPermissions() async {
    try {
      final responses = await _permissionApiService.getAllPermissions();
      return responses.map((r) => _mapResponseToDomain(r)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('غير مصرح لك بالوصول');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('هذه الصفحة متاحة فقط لموظفي HR');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      }
      throw Exception('حدث خطأ أثناء تحميل الإذونات');
    } catch (e) {
      rethrow;
    }
  }

  /// Create new permission request
  Future<domain.PermissionRequest> createPermission({
    required DateTime date,
    required String startTime, // HH:mm:ss format
    required String endTime, // HH:mm:ss format
    required String reason, // Required
  }) async {
    try {
      // Format date as YYYY-MM-DD
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _permissionApiService.createPermission(
        date: dateStr,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );

      return _mapResponseToDomain(response);
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ أثناء إنشاء الإذن';
      
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
                errorMessages.addAll(value.map((e) => e.toString()));
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
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'غير مصرح لك بإنشاء إذن';
        }
      } catch (parseError) {
        debugPrint('Error parsing API response: $parseError');
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  /// Update permission status (HR only)
  Future<domain.PermissionRequest> updatePermissionStatus({
    required int id,
    required int status, // 1 = Pending, 2 = Approved, 3 = Rejected
    String? rejectionReason,
    required domain.PermissionRequest currentPermission,
  }) async {
    try {
      final response = await _permissionApiService.updateStatus(
        id: id,
        status: status,
        rejectionReason: rejectionReason,
      );

      // Map status from response to PermissionStatus enum
      domain.PermissionStatus newStatus;
      final statusLower = response.status.toLowerCase();
      if (statusLower == 'approved') {
        newStatus = domain.PermissionStatus.approved;
      } else if (statusLower == 'rejected') {
        newStatus = domain.PermissionStatus.rejected;
      } else {
        newStatus = domain.PermissionStatus.pending;
      }

      // Return updated permission
      return domain.PermissionRequest(
        id: id.toString(),
        date: currentPermission.date,
        startTime: currentPermission.startTime,
        endTime: currentPermission.endTime,
        reason: currentPermission.reason,
        status: newStatus,
        submittedDate: currentPermission.submittedDate,
        rejectionReason: response.rejectionReason,
      );
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ أثناء تحديث حالة الإذن';
      
      try {
        if (e.response?.data != null) {
          Map<String, dynamic> data;
          if (e.response!.data is Map) {
            data = Map<String, dynamic>.from(e.response!.data);
          } else if (e.response!.data is String) {
            data = jsonDecode(e.response!.data);
          } else {
            data = {};
          }
          
          errorMessage = data['title'] ?? data['message'] ?? errorMessage;
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'البيانات المدخلة غير صحيحة';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'غير مصرح لك بتحديث حالة الإذن';
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'هذه العملية متاحة فقط لموظفي HR';
        }
      } catch (_) {}
      
      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setPermissionStatus({
    required int id,
    required int status,
    String? rejectionReason,
  }) async {
    try {
      await _permissionApiService.updateStatus(
        id: id,
        status: status,
        rejectionReason: rejectionReason,
      );
    } on DioException catch (e) {
      throw Exception(_extractSimpleErrorMessage(e));
    } catch (e) {
      rethrow;
    }
  }

  Future<MessageResponse> remindPermission({required int id}) async {
    try {
      return await _permissionApiService.remind(id: id);
    } on DioException catch (e) {
      throw Exception(_extractSimpleErrorMessage(e));
    } catch (e) {
      rethrow;
    }
  }

  /// Map API response to domain model
  domain.PermissionRequest _mapResponseToDomain(PermissionResponse response) {
    // Parse date string (YYYY-MM-DD) to DateTime
    final dateParts = response.date.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    // Parse time strings (HH:mm:ss) to TimeOfDay
    final startTimeParts = response.startTime.split(':');
    final startTime = TimeOfDay(
      hour: int.parse(startTimeParts[0]),
      minute: int.parse(startTimeParts[1]),
    );

    final endTimeParts = response.endTime.split(':');
    final endTime = TimeOfDay(
      hour: int.parse(endTimeParts[0]),
      minute: int.parse(endTimeParts[1]),
    );

    // Parse createdAt string to DateTime
    final createdAt = DateTime.parse(response.createdAt);

    // Map status string to enum
    // Status can be: "Pending", "Approved", "Rejected", "0", "1", "2"
    domain.PermissionStatus status;
    final statusLower = response.status.toLowerCase();
    if (statusLower == 'approved' || statusLower == '2') {
      status = domain.PermissionStatus.approved;
    } else if (statusLower == 'rejected' || statusLower == '3') {
      status = domain.PermissionStatus.rejected;
    } else {
      status = domain.PermissionStatus.pending;
    }

    return domain.PermissionRequest(
      id: response.id.toString(),
      date: date,
      startTime: startTime,
      endTime: endTime,
      reason: response.reason,
      status: status,
      submittedDate: createdAt,
      rejectionReason: response.rejectionReason,
    );
  }

  String _extractSimpleErrorMessage(DioException e) {
    try {
      if (e.response?.data is Map) {
        final data = Map<String, dynamic>.from(e.response!.data);
        return (data['title'] ?? data['message'] ?? 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ ØªØ­Ø¯ÙŠØ« Ø­Ø§Ù„Ø© Ø§Ù„Ø¥Ø°Ù†')
            .toString();
      }
      if (e.response?.data is String) {
        final data = jsonDecode(e.response!.data) as Map<String, dynamic>;
        return (data['title'] ?? data['message'] ?? 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ ØªØ­Ø¯ÙŠØ« Ø­Ø§Ù„Ø© Ø§Ù„Ø¥Ø°Ù†')
            .toString();
      }
    } catch (_) {}
    return 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ ØªØ­Ø¯ÙŠØ« Ø­Ø§Ù„Ø© Ø§Ù„Ø¥Ø°Ù†';
  }
}
