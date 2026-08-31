import 'dart:convert';

import '../../../core/network/dio_client.dart';
import '../../home/models/employee_penalty.dart';
import '../models/penalty_type.dart';

class PenaltiesApiService {
  final DioClient _dioClient;

  PenaltiesApiService(this._dioClient);

  /// GET /api/EmployeePenalty/types
  Future<List<PenaltyType>> getPenaltyTypes() async {
    final response = await _dioClient.dio.get('/api/EmployeePenalty/types');
    final list = _asList(response.data)
        .map((e) => PenaltyType.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// GET /api/EmployeePenalty/{userId}
  Future<List<EmployeePenalty>> getPenaltiesByUser(String userId) async {
    final response =
        await _dioClient.dio.get('/api/EmployeePenalty/$userId');
    final list = _asList(response.data)
        .map((e) => EmployeePenalty.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// POST /api/EmployeePenalty
  Future<EmployeePenalty> createPenalty({
    required String userId,
    required int penaltyType,
    required int days,
    required double amount,
    required String penaltyDate,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      'userId': userId,
      'penaltyType': penaltyType,
      'days': days,
      'amount': amount,
      'penaltyDate': penaltyDate,
      'reason': reason,
    };
    final response = await _dioClient.dio.post(
      '/api/EmployeePenalty',
      data: jsonEncode(payload),
    );
    return EmployeePenalty.fromJson(_asMap(response.data));
  }

  /// PUT /api/EmployeePenalty/{id}
  Future<EmployeePenalty> updatePenalty({
    required int id,
    required int penaltyType,
    required int days,
    required double amount,
    required String penaltyDate,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      'penaltyType': penaltyType,
      'days': days,
      'amount': amount,
      'penaltyDate': penaltyDate,
      'reason': reason,
    };
    final response = await _dioClient.dio.put(
      '/api/EmployeePenalty/$id',
      data: jsonEncode(payload),
    );
    return EmployeePenalty.fromJson(_asMap(response.data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Invalid response format');
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) return decoded;
    }
    return const [];
  }
}
