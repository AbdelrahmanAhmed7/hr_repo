class PayslipPeriod {
  static const int payrollSwitchDay = 5;

  const PayslipPeriod._();

  static DateTime activePeriod([DateTime? date]) {
    final current = date ?? DateTime.now();
    final monthOffset = current.day <= payrollSwitchDay ? -1 : 0;
    return DateTime(current.year, current.month + monthOffset, 1);
  }

  static int defaultMonth([DateTime? date]) => activePeriod(date).month;

  static int defaultYear([DateTime? date]) => activePeriod(date).year;

  static bool isFuturePeriod({
    required int month,
    required int year,
    DateTime? comparedTo,
  }) {
    final selectedPeriod = DateTime(year, month, 1);
    return selectedPeriod.isAfter(activePeriod(comparedTo));
  }
}
