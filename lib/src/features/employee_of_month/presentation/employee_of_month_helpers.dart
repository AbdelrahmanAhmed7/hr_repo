/// Shared date helpers for the Employee of the Month feature.
library;

const List<String> _kArabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'إبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String employeeOfMonthMonthName(int month) =>
    _kArabicMonths[(month - 1).clamp(0, 11)];

/// Previous month, handling January → December of the previous year.
({int month, int year}) employeeOfMonthPrevMonth(DateTime now) {
  if (now.month == 1) return (month: 12, year: now.year - 1);
  return (month: now.month - 1, year: now.year);
}