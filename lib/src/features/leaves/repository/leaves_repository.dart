import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/leave_request_model.dart';
import '../models/leave_submission_model.dart';
import '../models/leave_type_model.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_with_balance_response.dart';
import '../services/leaves_api_service.dart';
import '../../../core/network/models/message_response.dart';

class LeavesRepository {
  final LeavesApiService _leavesApiService;

  List<LeaveRequestModel>? _cachedLeaves;
  DateTime? _lastLeavesFetchTime;

  LeaveBalanceModel? _cachedBalance;
  DateTime? _lastBalanceFetchTime;

  List<LeaveTypeModel>? _cachedTypes;
  DateTime? _lastTypesFetchTime;

  LeavesRepository({required LeavesApiService leavesApiService})
    : _leavesApiService = leavesApiService;

  Future<List<LeaveRequestModel>> getMyLeaves({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedLeaves != null &&
        _lastLeavesFetchTime != null &&
        now.difference(_lastLeavesFetchTime!).inMinutes < 15) {
      return _cachedLeaves!;
    }
    try {
      _cachedLeaves = await _leavesApiService.getMyLeaves();
      _lastLeavesFetchTime = now;
      return _cachedLeaves!;
    } catch (e) {
      if (_cachedLeaves != null) return _cachedLeaves!;
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<LeaveBalanceModel> getMyLeaveBalance({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedBalance != null &&
        _lastBalanceFetchTime != null &&
        now.difference(_lastBalanceFetchTime!).inMinutes < 15) {
      return _cachedBalance!;
    }
    try {
      _cachedBalance = await _leavesApiService.getMyLeaveBalance();
      _lastBalanceFetchTime = now;
      return _cachedBalance!;
    } catch (e) {
      if (_cachedBalance != null) return _cachedBalance!;
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<LeaveWithBalanceResponse> getMyLeavesWithBalance({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedLeaves != null &&
        _cachedBalance != null &&
        _lastLeavesFetchTime != null &&
        _lastBalanceFetchTime != null &&
        now.difference(_lastLeavesFetchTime!).inMinutes < 15 &&
        now.difference(_lastBalanceFetchTime!).inMinutes < 15) {
      return LeaveWithBalanceResponse(
        balance: _cachedBalance!,
        leaves: _cachedLeaves!,
      );
    }

    // Try the combined endpoint first; fall back to two separate calls if it fails.
    try {
      final res = await _leavesApiService.getMyLeavesWithBalance();
      _cachedLeaves = res.leaves;
      _cachedBalance = res.balance;
      _lastLeavesFetchTime = now;
      _lastBalanceFetchTime = now;
      return res;
    } catch (_) {
      // with-balance endpoint failed (e.g. server-side DB issue) — use separate calls.
      try {
        final results = await Future.wait([
          _leavesApiService.getMyLeaves(),
          _leavesApiService.getMyLeaveBalance(),
        ]);
        final leaves = results[0] as List<LeaveRequestModel>;
        final balance = results[1] as LeaveBalanceModel;
        _cachedLeaves = leaves;
        _cachedBalance = balance;
        _lastLeavesFetchTime = now;
        _lastBalanceFetchTime = now;
        return LeaveWithBalanceResponse(balance: balance, leaves: leaves);
      } catch (e2) {
        if (_cachedLeaves != null && _cachedBalance != null) {
          return LeaveWithBalanceResponse(
            balance: _cachedBalance!,
            leaves: _cachedLeaves!,
          );
        }
        throw Exception(_extractErrorMessage(e2));
      }
    }
  }

  Future<List<LeaveTypeModel>> getLeaveTypes({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedTypes != null &&
        _lastTypesFetchTime != null &&
        now.difference(_lastTypesFetchTime!).inMinutes < 60) {
      return _cachedTypes!;
    }
    try {
      _cachedTypes = await _leavesApiService.getLeaveTypes();
      _lastTypesFetchTime = now;
      return _cachedTypes!;
    } catch (e) {
      if (_cachedTypes != null) return _cachedTypes!;
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> submitLeave(
    LeaveSubmissionModel submission, {
        required int leaveTypeId,
        File? medicalReport,
      }) async {
    try {
      await _leavesApiService.submitLeave(
        submission: submission,
        leaveTypeId: leaveTypeId,
        medicalReport: medicalReport,
      );
      clearCache();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> setLeaveStatus({
    required int id,
    required int status,
    String? rejectionReason,
  }) async {
    try {
      await _leavesApiService.updateStatus(
        id: id,
        status: status,
        rejectionReason: rejectionReason,
      );
      clearCache();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<MessageResponse> remindLeave({required int id}) async {
    try {
      return await _leavesApiService.remind(id: id);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  void clearCache() {
    _cachedLeaves = null;
    _lastLeavesFetchTime = null;
    _cachedBalance = null;
    _lastBalanceFetchTime = null;
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
          if (responseData.containsKey('errors') &&
              responseData['errors'] is Map) {
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
          else if (responseData.containsKey('title') &&
              responseData['title'] != null) {
            errorMessage = responseData['title'].toString();
          }
          // 3. Check for "message" field
          else if (responseData.containsKey('message') &&
              responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من الإنترنت';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'جلسة العمل انتهت، يرجى تسجيل الدخول مرة أخرى';
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
