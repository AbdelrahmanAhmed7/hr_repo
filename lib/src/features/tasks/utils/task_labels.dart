import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Arabic labels + colors for task enums (used as fallback/enrichment
/// alongside backend lookup names).
class TaskLabels {
  const TaskLabels._();

  static String statusText(int status) {
    switch (status) {
      case 0:
        return 'معلقة';
      case 1:
        return 'جارية';
      case 2:
        return 'بانتظار الاعتماد';
      case 3:
        return 'مكتملة';
      case 4:
        return 'مرفوضة';
      case 5:
        return 'ملغاة';
      case 6:
        return 'متأخرة';
      default:
        return 'غير معروفة';
    }
  }

  static Color statusColor(int status) {
    switch (status) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.info;
      case 2:
        return const Color(0xFF8B5CF6);
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.error;
      case 5:
        return AppColors.textTertiary;
      case 6:
        return const Color(0xFFE65100);
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData statusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.pending_outlined;
      case 1:
        return Icons.play_circle_outline_rounded;
      case 2:
        return Icons.mark_email_unread_outlined;
      case 3:
        return Icons.check_circle_outline_rounded;
      case 4:
        return Icons.cancel_outlined;
      case 5:
        return Icons.block_rounded;
      case 6:
        return Icons.warning_amber_outlined;
      default:
        return Icons.task_outlined;
    }
  }

  static String taskTypeText(int type) {
    switch (type) {
      case 0:
        return 'لمرة واحدة';
      case 1:
        return 'يومية';
      case 2:
        return 'أسبوعية';
      case 3:
        return 'شهرية';
      case 4:
        return 'سنوية';
      default:
        return 'مهمة';
    }
  }

  static IconData taskTypeIcon(int type) {
    switch (type) {
      case 0:
        return Icons.task_outlined;
      case 1:
        return Icons.today_outlined;
      case 2:
        return Icons.calendar_view_week_outlined;
      case 3:
        return Icons.calendar_month_outlined;
      case 4:
        return Icons.event_repeat_outlined;
      default:
        return Icons.task_outlined;
    }
  }

  static String dayOfWeekText(int day) {
    switch (day) {
      case 0:
        return 'الأحد';
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      default:
        return 'يوم $day';
    }
  }

  static String monthlyModeText(int mode) {
    switch (mode) {
      case 0:
        return 'يوم من الشهر';
      case 1:
        return 'أول يوم';
      case 2:
        return 'آخر يوم';
      case 3:
        return 'أول يوم عمل';
      case 4:
        return 'آخر يوم عمل';
      default:
        return 'وضع $mode';
    }
  }

  static String monthText(int month) {
    const months = [
      '',
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
    if (month < 1 || month > 12) return 'شهر $month';
    return months[month];
  }

  static String priorityText(int priority, [String? lookupName]) {
    if (lookupName != null && lookupName.trim().isNotEmpty) {
      return lookupName.trim();
    }
    switch (priority) {
      case 0:
        return 'منخفضة';
      case 1:
        return 'متوسطة';
      case 2:
        return 'عالية';
      case 3:
        return 'عاجلة';
      default:
        return 'أولوية $priority';
    }
  }

  /// Arabic translation of the backend enum names returned by
  /// /api/tasks/lookups (e.g. "Urgent", "Weekly", "Sunday", "LastWeekday").
  static const Map<String, String> _kApiToArabic = {
    // Priorities
    'Low': 'منخفضة',
    'Medium': 'متوسطة',
    'High': 'عالية',
    'Urgent': 'عاجلة',
    // Task types
    'OneTime': 'لمرة واحدة',
    'Daily': 'يومية',
    'Weekly': 'أسبوعية',
    'Monthly': 'شهرية',
    'Yearly': 'سنوية',
    'Custom': 'مخصصة',
    // Monthly modes
    'DayOfMonth': 'يوم من الشهر',
    'FirstDay': 'أول يوم',
    'LastDay': 'آخر يوم',
    'FirstWeekday': 'أول يوم عمل',
    'LastWeekday': 'آخر يوم عمل',
    // Days of week
    'Sunday': 'الأحد',
    'Monday': 'الاثنين',
    'Tuesday': 'الثلاثاء',
    'Wednesday': 'الأربعاء',
    'Thursday': 'الخميس',
    'Friday': 'الجمعة',
    'Saturday': 'السبت',
  };

  /// Returns the Arabic label for a backend lookup [apiValue], falling back
  /// to the raw English [apiValue] and finally to [fallback].
  static String lookupLabel(String apiValue, String fallback) {
    final ar = _kApiToArabic[apiValue];
    if (ar != null) return ar;
    if (apiValue.trim().isNotEmpty) return apiValue.trim();
    return fallback;
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String formatTimeOfDay(String hhmmss) {
    final parts = hhmmss.split(':');
    if (parts.length < 2) return hhmmss;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final suffix = h < 12 ? 'ص' : 'م';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }
}
