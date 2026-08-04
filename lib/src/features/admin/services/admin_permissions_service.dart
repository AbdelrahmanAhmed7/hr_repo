import 'dart:convert';
import '../../../core/network/dio_client.dart';
import '../models/department_permissions_response.dart';

class AdminPermissionsService {
  final DioClient _dioClient;

  AdminPermissionsService(this._dioClient);

  Future<DepartmentPermissionsResponse> getDepartmentPermissions({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
    };

    final response = await _dioClient.dio.get(
      '/api/AdminDashboard/department-permissions',
      queryParameters: queryParams,
    );

    final data = response.data is String
        ? jsonDecode(response.data)
        : response.data as Map<String, dynamic>;

    return DepartmentPermissionsResponse.fromJson(data);
  }

  Future<void> updatePermissionStatus({
    required int id,
    required int status, // 2 = Approved, 3 = Rejected
    String? rejectionReason,
  }) async {
    await _dioClient.dio.put(
      '/api/Permission/$id/status',
      data: {
        'status': status,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      },
    );
  }
}
