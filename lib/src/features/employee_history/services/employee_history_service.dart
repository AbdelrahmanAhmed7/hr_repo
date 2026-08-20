import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_exception.dart';
import '../models/employee_history_response.dart';
import '../models/employee_history_summary.dart';

class EmployeeHistoryService {
  final Dio _dio;

  EmployeeHistoryService(DioClient dioClient) : _dio = dioClient.dio;

  Future<EmployeeHistorySummary> getMySummary() async {
    try {
      final response = await _dio.get('/api/EmployeeHistory/my-summary');
      return EmployeeHistorySummary.fromJson(_normalizeMap(response.data));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception(AppException.from(e).message);
    }
  }

  Future<EmployeeHistoryResponse> getMyHistory({
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/EmployeeHistory/my-history',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      return EmployeeHistoryResponse.fromJson(_normalizeMap(response.data));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception(AppException.from(e).message);
    }
  }

  Map<String, dynamic> _normalizeMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  String _extractErrorMessage(DioException e) {
    String errorMessage = 'حدث خطأ أثناء تحميل السجل الوظيفي';

    try {
      final responseData = _normalizeMap(e.response?.data);
      if (responseData['title'] != null) {
        return responseData['title'].toString();
      }
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
      if (e.response?.statusCode == 403) {
        return 'ليس لديك صلاحية للوصول إلى السجل الوظيفي';
      }
      if (e.message != null && e.message!.trim().isNotEmpty) {
        return e.message!;
      }
    } catch (parseError) {
      if (kDebugMode) {
        print('EmployeeHistoryService parse error: $parseError');
      }
    }

    return errorMessage;
  }
}
