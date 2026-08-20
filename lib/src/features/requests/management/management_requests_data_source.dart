import 'package:dio/dio.dart';

import 'management_request.dart';

/// Fetches all pages of the management `/all` request endpoints.
class ManagementRequestsDataSource {
  final Dio _dio;

  ManagementRequestsDataSource(this._dio);

  static const int _pageSize = 200;

  Future<List<ManagementRequest>> fetchLeaves() =>
      _fetchAll('/api/Leave/all', ManagementRequestKind.leave);

  Future<List<ManagementRequest>> fetchPermissions() =>
      _fetchAll('/api/Permission/all', ManagementRequestKind.permission);

  Future<List<ManagementRequest>> fetchAssignments() =>
      _fetchAll('/api/Assignment/all', ManagementRequestKind.assignment);

  Future<List<ManagementRequest>> fetchOvertime() =>
      _fetchAll('/api/Overtime/all', ManagementRequestKind.overtime);

  Future<List<ManagementRequest>> _fetchAll(
    String path,
    ManagementRequestKind kind,
  ) async {
    final all = <ManagementRequest>[];
    var pageNumber = 1;
    var totalPages = 1;

    while (pageNumber <= totalPages) {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: {'pageNumber': pageNumber, 'pageSize': _pageSize},
      );

      final data = response.data;
      final items = _extractItems(data);
      for (final item in items) {
        all.add(ManagementRequest.fromJson(item, kind));
      }

      if (data is Map<String, dynamic>) {
        final parsedTotalPages = int.tryParse(
          data['totalPages']?.toString() ?? '',
        );
        totalPages = parsedTotalPages != null && parsedTotalPages > 0
            ? parsedTotalPages
            : pageNumber;
      } else {
        // Plain list response → no pagination metadata available.
        break;
      }

      if (items.isEmpty) break;
      pageNumber++;
    }

    return all;
  }

  static List<Map<String, dynamic>> _extractItems(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      final items = payload['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return const [];
  }
}