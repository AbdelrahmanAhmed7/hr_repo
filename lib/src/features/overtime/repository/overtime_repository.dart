import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../api/models/overtime_status_item.dart';
import '../api/models/overtime_response.dart';
import '../models/overtime_request.dart';
import '../services/overtime_api_service.dart';

class OvertimeRepository {
  final OvertimeApiService _overtimeApiService;

  OvertimeRepository({
    required OvertimeApiService overtimeApiService,
  }) : _overtimeApiService = overtimeApiService;

  Future<List<OvertimeRequest>> getMyOvertimeRequests() async {
    try {
      final responses = await _overtimeApiService.getMyOvertimeRequests();
      return responses.map(_mapResponseToDomain).toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'حدث خطأ أثناء تحميل طلبات العمل الإضافي'));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OvertimeStatusItem>> getStatuses() async {
    try {
      return await _overtimeApiService.getStatuses();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'حدث خطأ أثناء تحميل حالات الطلب'));
    } catch (e) {
      rethrow;
    }
  }

  Future<OvertimeRequest> createOvertime({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _overtimeApiService.createOvertime(
        date: dateStr,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );

      return _mapResponseToDomain(response);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'حدث خطأ أثناء إنشاء طلب العمل الإضافي'));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setOvertimeStatus({
    required int id,
    required int status,
    String? rejectionReason,
  }) async {
    try {
      await _overtimeApiService.updateStatus(
        id: id,
        status: status,
        rejectionReason: rejectionReason,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ ØªØ­Ø¯ÙŠØ« Ø·Ù„Ø¨ Ø§Ù„Ø¹Ù…Ù„ Ø§Ù„Ø¥Ø¶Ø§ÙÙŠ'),
      );
    } catch (e) {
      rethrow;
    }
  }

  OvertimeRequest _mapResponseToDomain(OvertimeResponse response) {
    final dateParts = response.date.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    return OvertimeRequest(
      id: response.id.toString(),
      userId: response.userId,
      date: date,
      startTime: _parseTime(response.startTime),
      endTime: _parseTime(response.endTime),
      totalHours: response.totalHours,
      hourlyRate: response.hourlyRate,
      amount: response.amount,
      reason: response.reason,
      createdAt: DateTime.parse(response.createdAt),
      status: _parseStatus(response.status),
      rejectionReason: response.rejectionReason,
    );
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  OvertimeRequestStatus _parseStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'approved') return OvertimeRequestStatus.approved;
    if (normalized == 'rejected') return OvertimeRequestStatus.rejected;
    return OvertimeRequestStatus.pending;
  }

  String _extractErrorMessage(DioException e, String fallback) {
    var errorMessage = fallback;

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

        if (responseData.containsKey('errors') && responseData['errors'] is Map) {
          final errors = responseData['errors'] as Map;
          final messages = <String>[];
          errors.forEach((_, value) {
            if (value is List) {
              messages.addAll(value.map((item) => item.toString()));
            } else {
              messages.add(value.toString());
            }
          });
          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }

        if (responseData['detail'] != null &&
            responseData['detail'].toString().trim().isNotEmpty) {
          return responseData['detail'].toString();
        }

        if (responseData['title'] != null &&
            responseData['title'].toString().trim().isNotEmpty) {
          return responseData['title'].toString();
        }

        if (responseData['message'] != null &&
            responseData['message'].toString().trim().isNotEmpty) {
          return responseData['message'].toString();
        }
      }

      if (e.response?.statusCode == 401) {
        return 'غير مصرح لك بالوصول';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
      }
    } catch (_) {
      return errorMessage;
    }

    return errorMessage;
  }
}
