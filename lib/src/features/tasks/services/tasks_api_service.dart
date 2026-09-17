import 'dart:convert';

import '../../../core/network/dio_client.dart';
import '../models/task.dart';
import '../models/task_filters.dart';
import '../models/task_interactions.dart';
import '../models/task_lookups.dart';
import '../models/task_page.dart';

/// Direct-Dio service for /api/tasks* (same style as AdminLeavesService).
class TasksApiService {
  final DioClient _dioClient;
  TasksApiService(this._dioClient);

  List<Map<String, dynamic>> _asMaps(dynamic data) {
    final decoded = data is String ? jsonDecode(data) : data;
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map<String, dynamic>) {
      for (final key in ['items', 'data', 'tasks', 'result']) {
        if (decoded[key] is List) {
          return (decoded[key] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    final decoded = data is String ? jsonDecode(data) : data;
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  /// Formats a [DateTime] for the query string (yyyy-MM-ddTHH:mm:ss, local).
  static String _toIsoDateTime(DateTime? date) {
    if (date == null) return '';
    final l = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}T${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }

  static String _date(DateTime? d) => d == null ? '' : _toIsoDateTime(d);

  /// Fetches tasks with full server-side filtering + pagination.
  Future<TaskPage> getTasks({
    int pageNumber = 1,
    int pageSize = 20,
    TaskFilters? filters,
  }) async {
    final f = filters ?? const TaskFilters();
    final response = await _dioClient.dio.get(
      '/api/tasks',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        // Dio omits empty/null query values when encoding the URL.
        'employeeId': f.employeeId,
        'departmentId': f.departmentId,
        'managerId': f.managerId,
        'status': f.status,
        'priority': f.priority,
        'taskType': f.taskType,
        'startDateFrom': _date(f.startDateFrom),
        'startDateTo': _date(f.startDateTo),
        'dueDateFrom': _date(f.dueDateFrom),
        'dueDateTo': _date(f.dueDateTo),
        'createdDateFrom': _date(f.createdDateFrom),
        'createdDateTo': _date(f.createdDateTo),
      },
    );
    return TaskPage.fromJson(_asMap(response.data));
  }

  /// Fetches the signed-in user's tasks with pagination + same filters
  /// (status/priority/taskType/date ranges — employee/manager scopes don't
  /// apply to "my tasks").
  Future<TaskPage> getMyTasks({
    int pageNumber = 1,
    int pageSize = 20,
    TaskFilters? filters,
  }) async {
    final f = filters ?? const TaskFilters();
    final response = await _dioClient.dio.get(
      '/api/tasks/my-tasks',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'status': f.status,
        'priority': f.priority,
        'taskType': f.taskType,
        'startDateFrom': _date(f.startDateFrom),
        'startDateTo': _date(f.startDateTo),
        'dueDateFrom': _date(f.dueDateFrom),
        'dueDateTo': _date(f.dueDateTo),
        'createdDateFrom': _date(f.createdDateFrom),
        'createdDateTo': _date(f.createdDateTo),
      },
    );
    return TaskPage.fromJson(_asMap(response.data));
  }

  Future<TaskModel> getTask(int id) async {
    final response = await _dioClient.dio.get('/api/tasks/$id');
    return TaskModel.fromJson(_asMap(response.data));
  }

  Future<TaskModel> createTask(TaskUpsertRequest request) async {
    final response = await _dioClient.dio.post(
      '/api/tasks',
      data: request.toJson(),
    );
    final map = _asMap(response.data);
    if (map.isEmpty) {
      // Some endpoints return only the id or nothing on create.
      final id = response.data is int
          ? response.data as int
          : int.tryParse('${response.data}') ?? 0;
      return TaskModel(id: id, title: request.title);
    }
    return TaskModel.fromJson(map);
  }

  Future<TaskModel> updateTask(int id, TaskUpsertRequest request) async {
    final response = await _dioClient.dio.put(
      '/api/tasks/$id',
      data: request.toJson(),
    );
    final map = _asMap(response.data);
    if (map.isEmpty) return TaskModel(id: id, title: request.title);
    return TaskModel.fromJson(map);
  }

  // ── Employee actions ──────────────────────────────────────────────

  Future<void> startTask(int id) async {
    await _dioClient.dio.post('/api/tasks/$id/start');
  }

  Future<void> updateProgress(int id, int progressPercentage) async {
    await _dioClient.dio.put(
      '/api/tasks/$id/progress',
      data: {'progressPercentage': progressPercentage.clamp(0, 100)},
    );
  }

  Future<void> submitTask(int id) async {
    await _dioClient.dio.post('/api/tasks/$id/submit');
  }

  // ── Manager actions ───────────────────────────────────────────────

  Future<void> approveTask(int id) async {
    await _dioClient.dio.post('/api/tasks/$id/approve');
  }

  Future<void> rejectTask(int id, String rejectionReason) async {
    await _dioClient.dio.post(
      '/api/tasks/$id/reject',
      data: {'rejectionReason': rejectionReason},
    );
  }

  // ── Recurrence management ─────────────────────────────────────────

  Future<void> pauseRecurrence(int id) async {
    await _dioClient.dio.post('/api/tasks/$id/pause-recurrence');
  }

  Future<void> resumeRecurrence(int id) async {
    await _dioClient.dio.post('/api/tasks/$id/resume-recurrence');
  }

  Future<void> stopRecurrence(int id) async {
    await _dioClient.dio.post('/api/tasks/$id/stop-recurrence');
  }

  // ── Comments / attachments / history ──────────────────────────────

  Future<List<TaskComment>> getComments(int id) async {
    final response = await _dioClient.dio.get('/api/tasks/$id/comments');
    return _asMaps(response.data).map(TaskComment.fromJson).toList();
  }

  Future<void> addComment(int id, String comment) async {
    await _dioClient.dio.post(
      '/api/tasks/$id/comments',
      data: {'comment': comment},
    );
  }

  Future<List<TaskAttachment>> getAttachments(int id) async {
    final response = await _dioClient.dio.get('/api/tasks/$id/attachments');
    return _asMaps(response.data).map(TaskAttachment.fromJson).toList();
  }

  Future<void> addAttachment(TaskAttachment attachment, int taskId) async {
    await _dioClient.dio.post(
      '/api/tasks/$taskId/attachments',
      data: attachment.toJson(),
    );
  }

  // ── Dropdowns ─────────────────────────────────────────────────────

  Future<TaskLookups> getLookups() async {
    final response = await _dioClient.dio.get('/api/tasks/lookups');
    return TaskLookups.fromJson(_asMap(response.data));
  }

  Future<List<AssignableEmployee>> getAssignableEmployees() async {
    final response = await _dioClient.dio.get(
      '/api/tasks/assignable-employees',
    );
    return _asMaps(response.data).map(AssignableEmployee.fromJson).toList();
  }
}
