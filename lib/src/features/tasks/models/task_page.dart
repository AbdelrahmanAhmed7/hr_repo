import 'task.dart';

/// Paginated response from GET /api/tasks:
/// { items, pageNumber, pageSize, totalCount, totalPages }.
class TaskPage {
  final List<TaskModel> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const TaskPage({
    required this.items,
    this.pageNumber = 1,
    this.pageSize = 0,
    this.totalCount = 0,
    this.totalPages = 0,
  });

  factory TaskPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['data'] ?? json['tasks'];
    return TaskPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(TaskModel.fromJson)
                .toList()
          : const [],
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}
