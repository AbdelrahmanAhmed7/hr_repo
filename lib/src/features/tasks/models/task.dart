/// A single task record from GET /api/tasks*, with response-only
/// [departmentId]/[departmentName] used for display/filtering.
class TaskModel {
  final int id;
  final String title;
  final String? description;
  final String? assignedToUserId;
  final String? assignedEmployeeName;
  final String? createdByUserId;
  final String? createdByName;
  final int? departmentId;
  final String? departmentName;
  final int priority;
  final int status;
  final int taskType;
  final int? parentTaskId;
  final DateTime? startDate;
  final DateTime? dueDate;
  final double? estimatedHours;
  final int progressPercentage;
  final DateTime? completedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TaskRecurrence? recurrence;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.assignedToUserId,
    this.assignedEmployeeName,
    this.createdByUserId,
    this.createdByName,
    this.departmentId,
    this.departmentName,
    this.priority = 0,
    this.status = 0,
    this.taskType = 0,
    this.parentTaskId,
    this.startDate,
    this.dueDate,
    this.estimatedHours,
    this.progressPercentage = 0,
    this.completedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.recurrence,
  });

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  static double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static DateTime? _asDateOrNull(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = '$v'.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String? _asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: _asInt(json['id']),
      title: '${json['title'] ?? ''}',
      description: _asStringOrNull(json['description']),
      assignedToUserId: _asStringOrNull(json['assignedToUserId']),
      assignedEmployeeName: _asStringOrNull(json['assignedEmployeeName']),
      createdByUserId: _asStringOrNull(json['createdByUserId']),
      createdByName: _asStringOrNull(json['createdByName']),
      departmentId: _asIntOrNull(json['departmentId']),
      departmentName: _asStringOrNull(json['departmentName']),
      priority: _asInt(json['priority']),
      status: _asInt(json['status']),
      taskType: _asInt(json['taskType']),
      parentTaskId: _asIntOrNull(json['parentTaskId']),
      startDate: _asDateOrNull(json['startDate']),
      dueDate: _asDateOrNull(json['dueDate']),
      estimatedHours: _asDoubleOrNull(json['estimatedHours']),
      progressPercentage: _asInt(json['progressPercentage']).clamp(0, 100),
      completedAt: _asDateOrNull(json['completedAt']),
      rejectionReason: _asStringOrNull(json['rejectionReason']),
      createdAt: _asDateOrNull(json['createdAt']),
      updatedAt: _asDateOrNull(json['updatedAt']),
      recurrence: json['recurrence'] is Map<String, dynamic>
          ? TaskRecurrence.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
    );
  }

  /// A recurring series root (no parent) with a non-one-time type.
  bool get isRecurringSeries => parentTaskId == null && taskType != 0;

  /// An occurrence generated from a recurring series.
  bool get isOccurrence => parentTaskId != null;

  bool get isCompleted => status == 3;

  bool get isOverdue =>
      status == 6 ||
      (dueDate != null &&
          !isCompleted &&
          status != 5 &&
          dueDate!.isBefore(DateTime.now()));
}

/// Recurrence payload for create/update when taskType != one-time (0).
/// Only non-null fields are serialized.
class TaskRecurrence {
  final int recurrenceType;
  final int interval;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? dailyOccurrencesPerDay;
  final List<String> dueTimes;
  final List<int> daysOfWeek;
  final int? dayOfMonth;
  final int? monthlyMode;
  final int? monthOfYear;

  const TaskRecurrence({
    required this.recurrenceType,
    this.interval = 1,
    this.startDate,
    this.endDate,
    this.dailyOccurrencesPerDay,
    this.dueTimes = const [],
    this.daysOfWeek = const [],
    this.dayOfMonth,
    this.monthlyMode,
    this.monthOfYear,
  });

  factory TaskRecurrence.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, [int f = 0]) {
      if (v == null) return f;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? f;
    }

    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse('$v');
    }

    List<String> asStringList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => '$e').toList();
    }

    List<int> asIntList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => asInt(e)).toList();
    }

    int? asIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    return TaskRecurrence(
      recurrenceType: asInt(json['recurrenceType']),
      interval: asInt(json['interval'], 1),
      startDate: asDate(json['startDate']),
      endDate: asDate(json['endDate']),
      dailyOccurrencesPerDay: asIntOrNull(json['dailyOccurrencesPerDay']),
      dueTimes: asStringList(json['dueTimes']),
      daysOfWeek: asIntList(json['daysOfWeek']),
      dayOfMonth: asIntOrNull(json['dayOfMonth']),
      monthlyMode: asIntOrNull(json['monthlyMode']),
      monthOfYear: asIntOrNull(json['monthOfYear']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recurrenceType': recurrenceType,
      'interval': interval,
      if (startDate != null) 'startDate': startDate!.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
      if (dailyOccurrencesPerDay != null)
        'dailyOccurrencesPerDay': dailyOccurrencesPerDay,
      if (dueTimes.isNotEmpty) 'dueTimes': dueTimes,
      if (daysOfWeek.isNotEmpty) 'daysOfWeek': daysOfWeek,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      if (monthlyMode != null) 'monthlyMode': monthlyMode,
      if (monthOfYear != null) 'monthOfYear': monthOfYear,
    };
  }
}

/// Payload for POST /api/tasks and PUT /api/tasks/{id}.
/// Never includes departmentId/category — backend resolves department
/// from [assignedToUserId].
class TaskUpsertRequest {
  final String title;
  final String? description;
  final String assignedToUserId;
  final int priority;
  final int taskType;
  final DateTime startDate;
  final DateTime dueDate;
  final double? estimatedHours;
  final TaskRecurrence? recurrence;

  const TaskUpsertRequest({
    required this.title,
    this.description,
    required this.assignedToUserId,
    required this.priority,
    required this.taskType,
    required this.startDate,
    required this.dueDate,
    this.estimatedHours,
    this.recurrence,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'assignedToUserId': assignedToUserId,
      'priority': priority,
      'taskType': taskType,
      'startDate': startDate.toUtc().toIso8601String(),
      'dueDate': dueDate.toUtc().toIso8601String(),
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
      if (recurrence != null) 'recurrence': recurrence!.toJson(),
    };
  }
}
