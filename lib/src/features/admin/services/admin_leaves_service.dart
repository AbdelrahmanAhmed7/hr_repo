import 'dart:convert';
import '../../../core/network/dio_client.dart';
import '../models/department_leaves_response.dart';

class AdminLeavesService {
  final DioClient _dioClient;
  AdminLeavesService(this._dioClient);

  Future<DepartmentLeavesResponse> getDepartmentLeaves({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dioClient.dio.get(
      '/api/AdminDashboard/department-leaves',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
      },
    );
    final data = response.data is String
        ? jsonDecode(response.data)
        : response.data as Map<String, dynamic>;
    return DepartmentLeavesResponse.fromJson(data);
  }

  Future<void> updateLeaveStatus({
    required int id,
    required int status, // 1 = Pending, 2 = Approved, 3 = Rejected
    String? rejectionReason,
  }) async {
    await _dioClient.dio.put(
      '/api/Leave/$id/status',
      data: {
        'status': status,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      },
    );
  }
}
