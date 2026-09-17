/// Filter parameters for GET /api/tasks. Every field maps 1:1 to a query
/// parameter; null fields are omitted from the request.
class TaskFilters {
  final String? employeeId;
  final int? departmentId;
  final String? managerId;
  final int? status;
  final int? priority;
  final int? taskType;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;
  final DateTime? createdDateFrom;
  final DateTime? createdDateTo;

  const TaskFilters({
    this.employeeId,
    this.departmentId,
    this.managerId,
    this.status,
    this.priority,
    this.taskType,
    this.startDateFrom,
    this.startDateTo,
    this.dueDateFrom,
    this.dueDateTo,
    this.createdDateFrom,
    this.createdDateTo,
  });

  bool get isEmpty =>
      employeeId == null &&
      departmentId == null &&
      managerId == null &&
      status == null &&
      priority == null &&
      taskType == null &&
      startDateFrom == null &&
      startDateTo == null &&
      dueDateFrom == null &&
      dueDateTo == null &&
      createdDateFrom == null &&
      createdDateTo == null;

  static const Object _sentinel = Object();

  TaskFilters copyWith({
    Object? employeeId = _sentinel,
    Object? departmentId = _sentinel,
    Object? managerId = _sentinel,
    Object? status = _sentinel,
    Object? priority = _sentinel,
    Object? taskType = _sentinel,
    Object? startDateFrom = _sentinel,
    Object? startDateTo = _sentinel,
    Object? dueDateFrom = _sentinel,
    Object? dueDateTo = _sentinel,
    Object? createdDateFrom = _sentinel,
    Object? createdDateTo = _sentinel,
  }) {
    return TaskFilters(
      employeeId: identical(employeeId, _sentinel)
          ? this.employeeId
          : employeeId as String?,
      departmentId: identical(departmentId, _sentinel)
          ? this.departmentId
          : departmentId as int?,
      managerId: identical(managerId, _sentinel)
          ? this.managerId
          : managerId as String?,
      status: identical(status, _sentinel) ? this.status : status as int?,
      priority: identical(priority, _sentinel)
          ? this.priority
          : priority as int?,
      taskType: identical(taskType, _sentinel)
          ? this.taskType
          : taskType as int?,
      startDateFrom: identical(startDateFrom, _sentinel)
          ? this.startDateFrom
          : startDateFrom as DateTime?,
      startDateTo: identical(startDateTo, _sentinel)
          ? this.startDateTo
          : startDateTo as DateTime?,
      dueDateFrom: identical(dueDateFrom, _sentinel)
          ? this.dueDateFrom
          : dueDateFrom as DateTime?,
      dueDateTo: identical(dueDateTo, _sentinel)
          ? this.dueDateTo
          : dueDateTo as DateTime?,
      createdDateFrom: identical(createdDateFrom, _sentinel)
          ? this.createdDateFrom
          : createdDateFrom as DateTime?,
      createdDateTo: identical(createdDateTo, _sentinel)
          ? this.createdDateTo
          : createdDateTo as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFilters &&
          other.employeeId == employeeId &&
          other.departmentId == departmentId &&
          other.managerId == managerId &&
          other.status == status &&
          other.priority == priority &&
          other.taskType == taskType &&
          other.startDateFrom == startDateFrom &&
          other.startDateTo == startDateTo &&
          other.dueDateFrom == dueDateFrom &&
          other.dueDateTo == dueDateTo &&
          other.createdDateFrom == createdDateFrom &&
          other.createdDateTo == createdDateTo;

  @override
  int get hashCode => Object.hash(
    employeeId,
    departmentId,
    managerId,
    status,
    priority,
    taskType,
    startDateFrom,
    startDateTo,
    dueDateFrom,
    dueDateTo,
    createdDateFrom,
    createdDateTo,
  );
}
