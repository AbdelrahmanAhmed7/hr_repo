class EmployeePenalty {
  final int id;
  final String userId;
  final int penaltyType;
  final int days;
  final double amount;
  final DateTime? penaltyDate;
  final String reason;
  final DateTime? createdAt;
  final String createdBy;
  final bool isApplied;
  final int? appliedMonth;
  final int? appliedYear;

  const EmployeePenalty({
    required this.id,
    required this.userId,
    required this.penaltyType,
    required this.days,
    required this.amount,
    required this.penaltyDate,
    required this.reason,
    required this.createdAt,
    required this.createdBy,
    required this.isApplied,
    required this.appliedMonth,
    required this.appliedYear,
  });

  factory EmployeePenalty.fromJson(Map<String, dynamic> json) {
    return EmployeePenalty(
      id: _toInt(json['id']),
      userId: (json['userId'] ?? '').toString(),
      penaltyType: _toInt(json['penaltyType']),
      days: _toInt(json['days']),
      amount: _toDouble(json['amount']),
      penaltyDate: _toDate(json['penaltyDate']),
      reason: (json['reason'] ?? '').toString(),
      createdAt: _toDate(json['createdAt']),
      createdBy: (json['createdBy'] ?? '').toString(),
      isApplied: json['isApplied'] == true,
      appliedMonth: _toNullableInt(json['appliedMonth']),
      appliedYear: _toNullableInt(json['appliedYear']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
