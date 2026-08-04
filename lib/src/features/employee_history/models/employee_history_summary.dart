class EmployeeHistorySummary {
  final String employeeId;
  final String employeeName;
  final int totalEvents;
  final int jobChanges;
  final int salaryChanges;
  final int transfers;
  final int promotions;
  final int contractEvents;
  final int disciplinaryActions;
  final DateTime? lastEventDate;

  const EmployeeHistorySummary({
    required this.employeeId,
    required this.employeeName,
    required this.totalEvents,
    required this.jobChanges,
    required this.salaryChanges,
    required this.transfers,
    required this.promotions,
    required this.contractEvents,
    required this.disciplinaryActions,
    required this.lastEventDate,
  });

  factory EmployeeHistorySummary.fromJson(Map<String, dynamic> json) {
    return EmployeeHistorySummary(
      employeeId: (json['employeeId'] ?? '').toString(),
      employeeName: (json['employeeName'] ?? '').toString(),
      totalEvents: _toInt(json['totalEvents']),
      jobChanges: _toInt(json['jobChanges']),
      salaryChanges: _toInt(json['salaryChanges']),
      transfers: _toInt(json['transfers']),
      promotions: _toInt(json['promotions']),
      contractEvents: _toInt(json['contractEvents']),
      disciplinaryActions: _toInt(json['disciplinaryActions']),
      lastEventDate: _toDateTime(json['lastEventDate']),
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
