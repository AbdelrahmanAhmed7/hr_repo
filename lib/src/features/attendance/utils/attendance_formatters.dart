const List<String> kArDays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> kArMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatTime(DateTime? t) => t == null
    ? '-'
    : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String getArDayName(int weekday) => kArDays[weekday - 1];

String formatWorkHours(double? hours, {bool short = false}) {
  if (hours == null) return '--';
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  if (h == 0 && m == 0) return short ? '0 د' : '0 دقيقة';
  if (h == 0) return short ? '$m د' : '$m دقيقة';
  if (m == 0) return short ? '$h س' : '$h ساعة';
  return short ? '$h س و $m د' : '$h ساعة و $m دقيقة';
}
