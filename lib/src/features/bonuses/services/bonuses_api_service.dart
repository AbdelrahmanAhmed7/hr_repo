import 'dart:convert';

import '../../../core/network/dio_client.dart';
import '../models/employee_bonus.dart';

class BonusesApiService {
  final DioClient _dioClient;

  BonusesApiService(this._dioClient);

  /// GET /api/EmployeeBonus/{userId}
  Future<List<EmployeeBonus>> getBonusesByUser(String userId) async {
    final response = await _dioClient.dio.get('/api/EmployeeBonus/$userId');
    final list = _asList(response.data)
        .map((e) => EmployeeBonus.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// POST /api/EmployeeBonus
  Future<EmployeeBonus> createBonus({
    required String userId,
    required double amount,
    required String bonusDate,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      'userId': userId,
      'amount': amount,
      'bonusDate': bonusDate,
      'reason': reason,
    };
    final response = await _dioClient.dio.post(
      '/api/EmployeeBonus',
      data: jsonEncode(payload),
    );
    return EmployeeBonus.fromJson(_asMap(response.data));
  }

  /// PUT /api/EmployeeBonus/{id}
  Future<EmployeeBonus> updateBonus({
    required int id,
    required double amount,
    required String bonusDate,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount,
      'bonusDate': bonusDate,
      'reason': reason,
    };
    final response = await _dioClient.dio.put(
      '/api/EmployeeBonus/$id',
      data: jsonEncode(payload),
    );
    return EmployeeBonus.fromJson(_asMap(response.data));
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
