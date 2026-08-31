import 'package:dio/dio.dart';
import '../models/department_leaves_response.dart';
import '../services/admin_leaves_service.dart';

class AdminLeavesRepository {
  final AdminLeavesService _service;
  AdminLeavesRepository(this._service);

  Future<DepartmentLeavesResponse> getDepartmentLeaves({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      return await _service.getDepartmentLeaves(
        pageNumber: pageNumber,
        pageSize: pageSize,
        search: search,
        status: status,
        userId: userId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> approveLeave(int id) async {
    try {
      await _service.updateLeaveStatus(id: id, status: 2);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> rejectLeave(int id, {String? rejectionReason}) async {
    try {
      await _service.updateLeaveStatus(
          id: id, status: 3, rejectionReason: rejectionReason);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> revertLeaveToPending(int id) async {
    try {
      await _service.updateLeaveStatus(id: id, status: 1);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    try {
      if (e.response?.data is Map) {
        final data = Map<String, dynamic>.from(e.response!.data);
        return (data['title'] ?? data['message'] ?? 'حدث خطأ').toString();
      }
    } catch (_) {}
    if (e.response?.statusCode == 401) return 'غير مصرح لك بهذه العملية';
    if (e.response?.statusCode == 403) return 'هذه العملية متاحة للمديرين فقط';
    return 'حدث خطأ، يرجى المحاولة مرة أخرى';
  }
}
