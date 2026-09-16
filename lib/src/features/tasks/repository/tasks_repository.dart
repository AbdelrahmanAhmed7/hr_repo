import '../models/task.dart';
import '../models/task_filters.dart';
import '../models/task_interactions.dart';
import '../models/task_lookups.dart';
import '../models/task_page.dart';
import '../services/tasks_api_service.dart';

/// Thin repository over [TasksApiService] (error mapping happens in cubits
/// via AppException, matching the leaves convention).
class TasksRepository {
  final TasksApiService _service;
  TasksRepository({required TasksApiService service}) : _service = service;

  Future<TaskPage> getTasks({
    int pageNumber = 1,
    int pageSize = 20,
    TaskFilters? filters,
  }) => _service.getTasks(
    pageNumber: pageNumber,
    pageSize: pageSize,
    filters: filters,
  );

  Future<TaskPage> getMyTasks({
    int pageNumber = 1,
    int pageSize = 20,
    TaskFilters? filters,
  }) => _service.getMyTasks(
    pageNumber: pageNumber,
    pageSize: pageSize,
    filters: filters,
  );

  Future<TaskModel> getTask(int id) => _service.getTask(id);

  Future<TaskModel> createTask(TaskUpsertRequest request) =>
      _service.createTask(request);

  Future<TaskModel> updateTask(int id, TaskUpsertRequest request) =>
      _service.updateTask(id, request);

  Future<void> startTask(int id) => _service.startTask(id);

  Future<void> updateProgress(int id, int progress) =>
      _service.updateProgress(id, progress);

  Future<void> submitTask(int id) => _service.submitTask(id);

  Future<void> approveTask(int id) => _service.approveTask(id);

  Future<void> rejectTask(int id, String reason) =>
      _service.rejectTask(id, reason);

  Future<void> pauseRecurrence(int id) => _service.pauseRecurrence(id);

  Future<void> resumeRecurrence(int id) => _service.resumeRecurrence(id);

  Future<void> stopRecurrence(int id) => _service.stopRecurrence(id);

  Future<List<TaskComment>> getComments(int id) => _service.getComments(id);

  Future<void> addComment(int id, String comment) =>
      _service.addComment(id, comment);

  Future<List<TaskAttachment>> getAttachments(int id) =>
      _service.getAttachments(id);

  Future<void> addAttachment(int taskId, TaskAttachment attachment) =>
      _service.addAttachment(attachment, taskId);

  Future<List<TaskHistoryEntry>> getHistory(int id) =>
      _service.getHistory(id);

  Future<TaskLookups> getLookups() => _service.getLookups();

  Future<List<AssignableEmployee>> getAssignableEmployees() =>
      _service.getAssignableEmployees();
}
