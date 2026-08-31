import 'package:dio/dio.dart';

import 'models/department_requests_response.dart';

class DepartmentRequestsService {
  final Dio _dio;

  DepartmentRequestsService(this._dio);

  /// GET /api/DepartmentRequests?month=&year=&pageNumber=&pageSize=
  ///
  /// Fetches ALL pages and merges the department lists, so the caller
  /// always receives every department regardless of server page size.
  Future<List<DepartmentRequestsItem>> getDepartmentRequests({
    int? month,
    int? year,
  }) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;

    final all = <DepartmentRequestsItem>[];
    var pageNumber = 1;
    var totalPages = 1;

    while (pageNumber <= totalPages) {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/DepartmentRequests',
        queryParameters: {
          ...params,
          'pageNumber': pageNumber,
          'pageSize': 50,
        },
      );

      final page = DepartmentRequestsResponse.fromJson(response.data ?? {});
      all.addAll(page.items);

      totalPages = page.totalPages > 0 ? page.totalPages : pageNumber;
      if (page.items.isEmpty) break;
      pageNumber++;
    }

    return all;
  }
}
