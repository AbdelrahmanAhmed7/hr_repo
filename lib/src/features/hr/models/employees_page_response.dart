import 'employee.dart';

class EmployeesPageResponse {
  final List<Employee> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const EmployeesPageResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory EmployeesPageResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((item) => Employee.fromUsersApiJson(item as Map<String, dynamic>))
        .toList();

    return EmployeesPageResponse(
      items: items,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? items.length,
      totalCount: json['totalCount'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
