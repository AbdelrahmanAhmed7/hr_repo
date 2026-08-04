import 'dart:convert';

import '../../../core/network/dio_client.dart';
import '../models/employee_bonus.dart';
import '../models/employee_penalty.dart';
import '../models/home_api_response.dart';
import '../services/home_api_service.dart';

class HomeRepository {
  final HomeApiService _apiService;
  final DioClient _dioClient;

  HomeRepository(this._apiService, this._dioClient);

  Future<HomeApiResponse> getHomeData() async {
    return await _apiService.getHomeData();
  }

  Future<List<HomeRequestItem>> getAllRequests({int? month}) async {
    return await _apiService.getAllRequests(month: month);
  }

  Future<List<HomeRequestItem>> getPendingRequests({int? month}) async {
    return await _apiService.getPendingRequests(month: month);
  }

  Future<List<HomeRequestItem>> getAcceptedRequests({int? month}) async {
    return await _apiService.getAcceptedRequests(month: month);
  }

  Future<List<HomeRequestItem>> getRejectedRequests({int? month}) async {
    return await _apiService.getRejectedRequests(month: month);
  }

  // Personal requests (current user only)
  Future<List<HomeRequestItem>> getMyLeaves() async {
    return await _apiService.getMyLeaves();
  }

  Future<List<HomeRequestItem>> getMyPermissions() async {
    return await _apiService.getMyPermissions();
  }

  Future<List<HomeRequestItem>> getMyAssignments() async {
    return await _apiService.getMyAssignments();
  }

  Future<List<HomeRequestItem>> getMyOvertime() async {
    return await _apiService.getMyOvertime();
  }

  Future<List<EmployeeBonus>> getEmployeeBonuses(String employeeId) async {
    final response = await _dioClient.dio.get('/api/EmployeeBonus/$employeeId');
    final items = _normalizeList(response.data);
    return items.map(EmployeeBonus.fromJson).toList();
  }

  Future<List<EmployeePenalty>> getEmployeePenalties(String employeeId) async {
    final response = await _dioClient.dio.get('/api/EmployeePenalty/$employeeId');
    final items = _normalizeList(response.data);
    return items.map(EmployeePenalty.fromJson).toList();
  }

  List<Map<String, dynamic>> _normalizeList(dynamic data) {
    dynamic normalized = data;
    if (data is String) {
      normalized = jsonDecode(data);
    }

    if (normalized is! List) {
      return const [];
    }

    return normalized
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
