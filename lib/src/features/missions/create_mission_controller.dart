import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/components/custom_toast.dart';
import 'cubit/assignment_cubit.dart';

class CreateMissionController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final destinationController = TextEditingController();
  final reasonController = TextEditingController();
  final destinationFocus = FocusNode();
  final reasonFocus = FocusNode();

  DateTime? selectedDate;
  DateTime? endDate;
  bool isMultiDay = false;
  String? selectedTimeSlot;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isSubmitting = false;

  static const Map<String, Map<String, TimeOfDay>> timeSlots = {
    'full_day': {
      'start': TimeOfDay(hour: 0, minute: 0),
      'end': TimeOfDay(hour: 23, minute: 59),
    },
    'morning': {
      'start': TimeOfDay(hour: 9, minute: 0),
      'end': TimeOfDay(hour: 13, minute: 0),
    },
    'afternoon': {
      'start': TimeOfDay(hour: 13, minute: 0),
      'end': TimeOfDay(hour: 17, minute: 0),
    },
  };

  static const List<String> quickDestinations = [
    'مستشفى',
    'عميل',
    'فرع آخر',
    'بنك',
  ];

  void initialize() {
    selectedDate = DateTime.now();
    endDate = DateTime.now();
  }

  @override
  void dispose() {
    destinationFocus.dispose();
    reasonFocus.dispose();
    destinationController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  String calculateDuration() {
    if (selectedDate == null || endDate == null || startTime == null || endTime == null) {
      return '';
    }

    final startDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      startTime!.hour,
      startTime!.minute,
    );

    final endDateTime = DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
      endTime!.hour,
      endTime!.minute,
    );

    final diff = endDateTime.difference(startDateTime);
    if (diff.isNegative || diff.inMinutes == 0) return '';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days ${days == 1 ? 'يوم' : 'أيام'}');
    if (hours > 0) parts.add('$hours ${hours == 1 ? 'ساعة' : 'ساعات'}');
    if (minutes > 0) parts.add('$minutes دقيقة');

    return parts.join(' و ');
  }

  bool isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    final minutes1 = time1.hour * 60 + time1.minute;
    final minutes2 = time2.hour * 60 + time2.minute;
    return minutes1 < minutes2;
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'اختر التاريخ';
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return 'اختر الوقت';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool isQuickDateSelected(String label) {
    if (selectedDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final selected = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);

    if (label == 'اليوم') return selected == today;
    if (label == 'غداً') return selected == tomorrow;
    if (label == 'بعد غد') return selected == dayAfterTomorrow;
    return false;
  }

  void selectQuickDate(int daysFromToday) {
    selectedDate = DateTime.now().add(Duration(days: daysFromToday));
    endDate = selectedDate;
    notifyListeners();
  }

  void toggleMultiDay(bool value) {
    isMultiDay = value;
    if (!value) {
      endDate = selectedDate;
    } else {
      selectTimeSlot('full_day');
      return;
    }
    notifyListeners();
  }

  void setDestination(String value) {
    destinationController.text = value;
    notifyListeners();
  }

  void selectTimeSlot(String slotKey) {
    final slot = timeSlots[slotKey];
    if (slot == null) return;

    selectedTimeSlot = slotKey;
    startTime = slot['start'];
    endTime = slot['end'];
    notifyListeners();
  }

  void selectCustomTime() {
    selectedTimeSlot = 'custom';
    if (startTime == null || endTime == null) {
      startTime = null;
      endTime = null;
    }
    notifyListeners();
  }

  Future<void> pickStartDate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'EG'),
      builder: AppTheme.getDatePickerThemeBuilder(),
    );

    if (picked != null) {
      selectedDate = picked;
      if (!isMultiDay) {
        endDate = picked;
      } else if (endDate != null && endDate!.isBefore(picked)) {
        endDate = picked;
      }
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (selectedDate == null) {
      CustomToast.showError('اختر تاريخ البداية أولاً');
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? selectedDate!,
      firstDate: selectedDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'EG'),
      builder: AppTheme.getDatePickerThemeBuilder(),
    );

    if (picked != null) {
      endDate = picked;
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> pickStartTime(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
      builder: AppTheme.getTimePickerThemeBuilder(),
    );

    if (picked != null) {
      startTime = picked;
      if (endTime != null && isTimeBefore(endTime!, picked)) {
        endTime = null;
      }
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> pickEndTime(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (startTime == null) {
      CustomToast.showError('اختر وقت البداية أولاً');
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: endTime ?? startTime!,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!context.mounted) return;

    if (picked != null) {
      if (isTimeBefore(picked, startTime!)) {
        CustomToast.showError('وقت النهاية يجب أن يكون بعد وقت البداية');
        return;
      }
      endTime = picked;
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> submitMission(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      CustomToast.showError('اختر تاريخ البداية');
      return;
    }

    if (isMultiDay && endDate == null) {
      CustomToast.showError('اختر تاريخ النهاية');
      return;
    }

    if (isMultiDay && endDate!.isBefore(selectedDate!)) {
      CustomToast.showError(
        'تاريخ النهاية يجب أن يكون بعد تاريخ البداية',
      );
      return;
    }

    if (selectedTimeSlot == null) {
      CustomToast.showError('اختر الفترة الزمنية');
      return;
    }

    if (startTime == null || endTime == null) {
      CustomToast.showError('اختر وقت البداية والنهاية');
      return;
    }

    final startDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      startTime!.hour,
      startTime!.minute,
    );

    final endDateTime = DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
      endTime!.hour,
      endTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      CustomToast.showError(
        isMultiDay
            ? 'وقت النهاية في اليوم الأخير يجب أن يكون بعد وقت البداية في اليوم الأول'
            : 'وقت النهاية يجب أن يكون بعد وقت البداية',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    isSubmitting = true;
    notifyListeners();

    final assignmentCubit = context.read<AssignmentCubit>();
    final success = await assignmentCubit.createAssignment(
      where: destinationController.text.trim(),
      startDate: selectedDate!,
      endDate: endDate ?? selectedDate!,
      startTime: startTime!,
      endTime: endTime!,
      reason: reasonController.text.trim(),
    );

    if (!context.mounted) return;

    isSubmitting = false;
    notifyListeners();

    if (success) {
      CustomToast.showSuccess('تم تسجيل المأمورية بنجاح');

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } else {
      final error = assignmentCubit.state.error ??
          'حدث خطأ أثناء إنشاء المأمورية';
      CustomToast.showError(error);
    }
  }
}
