import 'department_assignment.dart';

class DepartmentAssignmentsResponse {
  final List<DepartmentAssignment> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  DepartmentAssignmentsResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory DepartmentAssignmentsResponse.fromJson(Map<String, dynamic> json) {
    return DepartmentAssignmentsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  DepartmentAssignment.fromJson(e as Map<String, dynamic>))
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
