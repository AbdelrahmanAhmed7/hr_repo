class EmployeeHistoryResponse {
  final String employeeName;
  final List<EmployeeHistoryEvent> history;
  final int totalCount;

  const EmployeeHistoryResponse({
    required this.employeeName,
    required this.history,
    required this.totalCount,
  });

  factory EmployeeHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'];
    final historyList = rawHistory is List
        ? rawHistory
            .whereType<Map>()
            .map(
              (item) => EmployeeHistoryEvent.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <EmployeeHistoryEvent>[];

    return EmployeeHistoryResponse(
      employeeName: (json['employeeName'] ?? '').toString(),
      history: historyList,
      totalCount: _toInt(json['totalCount']),
    );
  }
}

class EmployeeHistoryEvent {
  final int id;
  final String eventType;
  final String description;
  final List<EmployeeHistoryChange> changes;
  final DateTime? date;
  final String doneBy;
  final String? reason;
  final String? notes;

  const EmployeeHistoryEvent({
    required this.id,
    required this.eventType,
    required this.description,
    required this.changes,
    required this.date,
    required this.doneBy,
    required this.reason,
    required this.notes,
  });

  factory EmployeeHistoryEvent.fromJson(Map<String, dynamic> json) {
    final rawChanges = json['changes'];
    final changesList = rawChanges is List
        ? rawChanges
            .whereType<Map>()
            .map(
              (item) => EmployeeHistoryChange.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <EmployeeHistoryChange>[];

    return EmployeeHistoryEvent(
      id: _toInt(json['id']),
      eventType: (json['eventType'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      changes: changesList,
      date: _toDateTime(json['date']),
      doneBy: (json['doneBy'] ?? '').toString(),
      reason: _toNullableString(json['reason']),
      notes: _toNullableString(json['notes']),
    );
  }
}

class EmployeeHistoryChange {
  final String property;
  final String? from;
  final String? to;

  const EmployeeHistoryChange({
    required this.property,
    required this.from,
    required this.to,
  });

  factory EmployeeHistoryChange.fromJson(Map<String, dynamic> json) {
    return EmployeeHistoryChange(
      property: (json['property'] ?? '').toString(),
      from: _toNullableString(json['from']),
      to: _toNullableString(json['to']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') {
    return null;
  }
  return text;
}
