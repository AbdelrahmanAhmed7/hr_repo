// NOTE: /api/tasks/lookups (and the granular endpoints) return items in the
// shape {"id": <int>, "value": "<English name>"}. "id" is the numeric value
// we send to the backend; "value" is the display string.
class LookupItem {
  final int value;
  final String name;

  const LookupItem({required this.value, required this.name});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    final rawValue = json['id'] ?? json['value'];
    int value = 0;
    if (rawValue is int) {
      value = rawValue;
    } else if (rawValue is num) {
      value = rawValue.toInt();
    } else {
      value = int.tryParse('$rawValue') ?? 0;
    }
    final nameValue = json['value'];
    final name = nameValue is String
        ? nameValue
        : '${json['name'] ?? json['label'] ?? json['text'] ?? ''}';
    return LookupItem(value: value, name: name);
  }
}

/// All enum dropdowns in one response from GET /api/tasks/lookups.
class TaskLookups {
  final List<LookupItem> priorities;
  final List<LookupItem> taskTypes;
  final List<LookupItem> statuses;
  final List<LookupItem> monthlyModes;
  final List<LookupItem> daysOfWeek;

  const TaskLookups({
    this.priorities = const [],
    this.taskTypes = const [],
    this.statuses = const [],
    this.monthlyModes = const [],
    this.daysOfWeek = const [],
  });

  static List<LookupItem> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(LookupItem.fromJson)
        .toList();
  }

  static List<LookupItem> _pick(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json[k] is List) return _parseList(json[k]);
    }
    return const [];
  }

  factory TaskLookups.fromJson(Map<String, dynamic> json) {
    return TaskLookups(
      priorities: _pick(json, ['priorities', 'Priorities']),
      taskTypes: _pick(json, ['taskTypes', 'TaskTypes']),
      statuses: _pick(json, ['statuses', 'Statuses']),
      monthlyModes: _pick(json, ['monthlyModes', 'MonthlyModes']),
      daysOfWeek: _pick(json, ['daysOfWeek', 'DaysOfWeek']),
    );
  }
}

/// Employee entry from GET /api/tasks/assignable-employees.
/// Use [id] as assignedToUserId when creating/updating a task.
class AssignableEmployee {
  final String id;
  final String fullName;

  const AssignableEmployee({required this.id, required this.fullName});

  factory AssignableEmployee.fromJson(Map<String, dynamic> json) {
    return AssignableEmployee(
      id: '${json['id'] ?? ''}',
      fullName: '${json['fullName'] ?? json['name'] ?? ''}',
    );
  }
}
