class PayrollPeriod {
  final DateTime start; // inclusive
  final DateTime end; // inclusive

  const PayrollPeriod({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollPeriod &&
          runtimeType == other.runtimeType &&
          start.year == other.start.year &&
          start.month == other.start.month &&
          start.day == other.start.day &&
          end.year == other.end.year &&
          end.month == other.end.month &&
          end.day == other.end.day;

  @override
  int get hashCode =>
      Object.hash(start.year, start.month, start.day, end.year, end.month, end.day);
}
