import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Helper class for showing date pickers with consistent theming
class DatePickerHelper {
  /// Show a date picker with consistent theming
  static Future<DateTime?> showDatePickerDialog({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    String? cancelText,
    String? confirmText,
    Locale? locale,
  }) async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      helpText: helpText ?? 'اختر التاريخ',
      cancelText: cancelText ?? 'إلغاء',
      confirmText: confirmText ?? 'تأكيد',
      locale: locale ?? const Locale('ar', 'EG'),
      builder: AppTheme.getDatePickerThemeBuilder(),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }

    return picked;
  }

  /// Show a date picker for birth date selection
  static Future<DateTime?> showBirthDatePicker(BuildContext context) {
    return showDatePickerDialog(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ الميلاد',
    );
  }

  /// Show a date picker for hire date selection
  static Future<DateTime?> showHireDatePicker(BuildContext context) {
    return showDatePickerDialog(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ التعيين',
    );
  }

  /// Show a date picker for future dates (e.g., leave requests)
  static Future<DateTime?> showFutureDatePicker(
    BuildContext context, {
    DateTime? initialDate,
    int maxDaysFromNow = 365,
  }) {
    return showDatePickerDialog(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: maxDaysFromNow)),
    );
  }

  /// Show a date picker for past dates only
  static Future<DateTime?> showPastDatePicker(
    BuildContext context, {
    DateTime? initialDate,
    int maxDaysAgo = 365,
  }) {
    return showDatePickerDialog(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: maxDaysAgo)),
      lastDate: DateTime.now(),
    );
  }
}

