import 'department_permission.dart';

class DepartmentPermissionsResponse {
  final List<DepartmentPermission> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  DepartmentPermissionsResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory DepartmentPermissionsResponse.fromJson(Map<String, dynamic> json) {
    return DepartmentPermissionsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  DepartmentPermission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  bool get hasNextPage => pageNumber < totalPages;
}