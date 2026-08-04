class EmployeeBonus {
  final int id;
  final String userId;
  final double amount;
  final DateTime? bonusDate;
  final String reason;
  final DateTime? createdAt;
  final String createdBy;

  const EmployeeBonus({
    required this.id,
    required this.userId,
    required this.amount,
    required this.bonusDate,
    required this.reason,
    required this.createdAt,
    required this.createdBy,
  });

  factory EmployeeBonus.fromJson(Map<String, dynamic> json) {
    return EmployeeBonus(
      id: _toInt(json['id']),
      userId: (json['userId'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      bonusDate: _toDate(json['bonusDate']),
      reason: (json['reason'] ?? '').toString(),
      createdAt: _toDate(json['createdAt']),
      createdBy: (json['createdBy'] ?? '').toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
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
