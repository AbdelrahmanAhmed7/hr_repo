import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Helper class for showing time pickers with consistent theming
class TimePickerHelper {
  /// Show a time picker with consistent theming
  static Future<TimeOfDay?> showTimePickerDialog({
    required BuildContext context,
    TimeOfDay? initialTime,
  }) async {
    FocusScope.of(context).unfocus();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: AppTheme.getTimePickerThemeBuilder(),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }

    return picked;
  }

  /// Show a start time picker
  static Future<TimeOfDay?> showStartTimePicker(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) {
    return showTimePickerDialog(
      context: context,
      initialTime: initialTime,
    );
  }

  /// Show an end time picker with validation
  static Future<TimeOfDay?> showEndTimePicker({
    required BuildContext context,
    required TimeOfDay startTime,
    TimeOfDay? initialTime,
    Function(String)? onValidationError,
  }) async {
    if (initialTime != null && _isTimeBefore(initialTime, startTime)) {
      initialTime = startTime;
    }

    final picked = await showTimePickerDialog(
      context: context,
      initialTime: initialTime ?? startTime,
    );

    if (picked != null && _isTimeBefore(picked, startTime)) {
      if (onValidationError != null) {
        onValidationError('وقت النهاية يجب أن يكون بعد وقت البداية');
      }
      return null;
    }

    return picked;
  }

  /// Check if time1 is before time2
  static bool _isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour < time2.hour) return true;
    if (time1.hour > time2.hour) return false;
    return time1.minute < time2.minute;
  }

  /// Format TimeOfDay to string (HH:MM)
  static String formatTime(TimeOfDay? time) {
    if (time == null) return 'اختر الوقت';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Format TimeOfDay to 12-hour format string
  static String formatTime12Hour(TimeOfDay? time) {
    if (time == null) return 'اختر الوقت';
    
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    final minute = time.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute $period';
  }
}

