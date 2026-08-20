import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/app_exception.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/custom_text_field.dart';
import '../../../shared/components/custom_toast.dart';
import '../../../shared/mixins/keyboard_dismiss_mixin.dart';
import '../../permissions/repository/permission_repository.dart';
import '../services/requests_refresh_service.dart';

class CreateExitPermissionBottomSheet extends StatefulWidget {
  const CreateExitPermissionBottomSheet({super.key});

  @override
  State<CreateExitPermissionBottomSheet> createState() =>
      _CreateExitPermissionBottomSheetState();
}

class _CreateExitPermissionBottomSheetState
    extends State<CreateExitPermissionBottomSheet> with KeyboardDismissMixin {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _reasonFocus = FocusNode();
  DateTime? _selectedDate;
  String? _selectedTimeSlot; // 'morning' or 'afternoon' or 'custom'
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  // Validation errors
  String? _reasonError;
  bool _showValidationErrors = false;

  // Calculate duration helper
  String _calculateDuration() {
    if (_startTime == null || _endTime == null) return '';
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final diff = endMinutes - startMinutes;
    if (diff <= 0) return '';
    final hours = diff ~/ 60;
    final minutes = diff % 60;
    if (minutes > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }
    return '$hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
  }

  // Predefined time slots
  static const Map<String, Map<String, TimeOfDay>> _timeSlots = {
    'morning_2h': {
      'start': TimeOfDay(hour: 9, minute: 0),
      'end': TimeOfDay(hour: 11, minute: 0),
    },
    'morning_1h': {
      'start': TimeOfDay(hour: 9, minute: 0),
      'end': TimeOfDay(hour: 10, minute: 0),
    },
    'afternoon_2h': {
      'start': TimeOfDay(hour: 15, minute: 0),
      'end': TimeOfDay(hour: 17, minute: 0),
    },
    'afternoon_1h': {
      'start': TimeOfDay(hour: 16, minute: 0),
      'end': TimeOfDay(hour: 17, minute: 0),
    },
  };

  // Quick reason suggestions
  static const List<String> _quickReasons = [
    'مهمة شخصية',
    'موعد طبي',
    'إجراءات حكومية',
    'ظرف عائلي',
  ];

  @override
  void initState() {
    super.initState();
    // Do not set default date to force selection or make it clearer
    // Actually, setting to today is fine, but I'll make sure the validation is clear.
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _reasonFocus.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _selectTimeSlot(String slotKey) {
    final slot = _timeSlots[slotKey];
    if (slot != null) {
      setState(() {
        _selectedTimeSlot = slotKey;
        _startTime = slot['start'];
        _endTime = slot['end'];
      });
    }
  }

  void _selectCustomTime() {
    setState(() {
      _selectedTimeSlot = 'custom';
      _startTime = null;
      _endTime = null;
    });
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
      builder: AppTheme.getDatePickerThemeBuilder(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _selectStartTime() async {
    FocusScope.of(context).unfocus();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: AppTheme.getTimePickerThemeBuilder(),
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Reset end time if it's before start time
        if (_endTime != null && _isTimeBefore(_endTime!, picked)) {
          _endTime = null;
        }
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _selectEndTime() async {
    FocusScope.of(context).unfocus();

    if (_startTime == null) {
      CustomToast.showError('اختر وقت البداية أولاً');
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime!,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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

    if (picked != null) {
      if (!mounted) return;
      if (_isTimeBefore(picked, _startTime!)) {
        CustomToast.showError(
          'وقت النهاية يجب أن يكون بعد وقت البداية'
        );
        return;
      }
      setState(() {
        _endTime = picked;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  bool _isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    final int minutes1 = time1.hour * 60 + time1.minute;
    final int minutes2 = time2.hour * 60 + time2.minute;
    return minutes1 < minutes2;
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'اختر الوقت';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'اختر التاريخ';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'اليوم - ${date.day}/${date.month}/${date.year}';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'غداً - ${date.day}/${date.month}/${date.year}';
    } else if (selectedDay == today.add(const Duration(days: 2))) {
      return 'بعد غد - ${date.day}/${date.month}/${date.year}';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildQuickDateButton(String label, VoidCallback onTap) {
    // Check if this date is selected
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    
    bool isSelected = false;
    if (_selectedDate != null) {
      final selected = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      if (label == 'اليوم' && selected == today) {
        isSelected = true;
      } else if (label == 'غداً' && selected == tomorrow) {
        isSelected = true;
      } else if (label == 'بعد غد' && selected == dayAfterTomorrow) {
        isSelected = true;
      }
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primaryTint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.primary.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(String slotKey, String timeRange, String duration, IconData icon) {
    final isSelected = _selectedTimeSlot == slotKey;
    final hasError = _showValidationErrors && _selectedTimeSlot == null;
    
    return InkWell(
      onTap: () {
        _selectTimeSlot(slotKey);
        if (_showValidationErrors) {
          setState(() {});
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : (hasError ? AppColors.error : AppColors.border),
            width: isSelected || hasError ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              timeRange,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validate() {
    setState(() {
      _showValidationErrors = true;
      final reason = _reasonController.text.trim();
      if (reason.isEmpty) {
        _reasonError = 'برجاء كتابة سبب الإذن';
      } else if (reason.length < 5) {
        _reasonError = 'السبب يجب أن يكون 5 أحرف على الأقل';
      } else {
        _reasonError = null;
      }
    });

    String? error;
    if (_selectedDate == null) {
      error = 'برجاء اختيار تاريخ الإذن';
    } else if (_selectedTimeSlot == null) {
      error = 'برجاء اختيار الفترة الزمنية (صباحية، مسائية، أو مخصص)';
    } else if (_startTime == null) {
      error = 'برجاء اختيار وقت بداية الإذن';
    } else if (_endTime == null) {
      error = 'برجاء اختيار وقت نهاية الإذن';
    } else if (_isTimeBefore(_endTime!, _startTime!)) {
      error = 'وقت النهاية يجب أن يكون بعد وقت البداية';
    } else if (_reasonError != null) {
      error = _reasonError;
    }

    if (error != null) {
      CustomToast.showError(error);
      return false;
    }
    return true;
  }

  Future<void> _submitPermission() async {
    if (!_validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final repository = getIt<PermissionRepository>();
      
      // Format time as HH:mm:ss
      final startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
      final endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

      await repository.createPermission(
        date: _selectedDate!,
        startTime: startTimeStr,
        endTime: endTimeStr,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      
      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('نجاح'),
            ],
          ),
          content: const Text('تم تسجيل إذن الخروج بنجاح'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      
      if (!mounted) return;
      getIt<RequestsRefreshService>().notify();
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      
      // Extract error message
      String errorMessage = 'حدث خطأ أثناء إنشاء الإذن';
      if (e is Exception) {
        errorMessage = AppException.from(e).message;
      }
      
      debugPrint('Permission Creation Error: $errorMessage');
      
      // Show error dialog above bottom sheet
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('خطأ'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
              child: Row(
                children: [
                  Text(
                    'طلب إذن',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(* مطلوب)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date Picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التاريخ *',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: TextStyle(
                                    color: _selectedDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Quick date selection
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickDateButton('اليوم', () {
                              setState(() {
                                _selectedDate = DateTime.now();
                              });
                            }),
                            _buildQuickDateButton('غداً', () {
                              setState(() {
                                _selectedDate = DateTime.now().add(const Duration(days: 1));
                              });
                            }),
                            _buildQuickDateButton('بعد غد', () {
                              setState(() {
                                _selectedDate = DateTime.now().add(const Duration(days: 2));
                              });
                            }),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Time Slot Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر الفترة الزمنية *',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Morning slots
                        Text(
                          'الفترة الصباحية',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeSlotCard(
                                'morning_2h',
                                '9:00 - 11:00',
                                'ساعتين',
                                Icons.wb_sunny_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimeSlotCard(
                                'morning_1h',
                                '9:00 - 10:00',
                                'ساعة واحدة',
                                Icons.wb_sunny_outlined,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Afternoon slots
                        Text(
                          'الفترة المسائية',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeSlotCard(
                                'afternoon_2h',
                                '3:00 - 5:00',
                                'ساعتين',
                                Icons.wb_twilight_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimeSlotCard(
                                'afternoon_1h',
                                '4:00 - 5:00',
                                'ساعة واحدة',
                                Icons.wb_twilight_outlined,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Custom time option
                        InkWell(
                          onTap: () {
                            _selectCustomTime();
                            if (_showValidationErrors) {
                              setState(() {});
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _selectedTimeSlot == 'custom'
                                  ? AppColors.primaryTint
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTimeSlot == 'custom'
                                    ? AppColors.primary
                                    : (_showValidationErrors && _selectedTimeSlot == null 
                                        ? AppColors.error 
                                        : AppColors.border),
                                width: _selectedTimeSlot == 'custom' || (_showValidationErrors && _selectedTimeSlot == null) ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  color: _selectedTimeSlot == 'custom'
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'وقت مخصص',
                                    style: TextStyle(
                                      color: _selectedTimeSlot == 'custom'
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: _selectedTimeSlot == 'custom'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (_selectedTimeSlot == 'custom')
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Show custom time pickers if custom is selected
                        if (_selectedTimeSlot == 'custom') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'من',
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: _selectStartTime,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundSecondary,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.access_time_outlined,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTime(_startTime),
                                              style: TextStyle(
                                                color: _startTime != null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إلى',
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: _selectEndTime,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundSecondary,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.access_time_outlined,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTime(_endTime),
                                              style: TextStyle(
                                                color: _endTime != null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Duration display
                        if (_startTime != null && _endTime != null && _calculateDuration().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.successTint,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'المدة: ${_calculateDuration()}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reason with quick suggestions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: 'سبب الإذن *',
                          placeholder: 'اكتب سبب الإذن (مطلوب)',
                          prefixIcon: Icons.description_outlined,
                          keyboardType: TextInputType.text,
                          maxLines: 2,
                          maxLength: 250,
                          controller: _reasonController,
                          focusNode: _reasonFocus,
                          textInputAction: TextInputAction.done,
                          errorText: _showValidationErrors ? _reasonError : null,
                          onChanged: (_) {
                            if (_showValidationErrors) {
                              setState(() {
                                final reason = _reasonController.text.trim();
                                if (reason.isEmpty) {
                                  _reasonError = 'برجاء كتابة سبب الإذن';
                                } else if (reason.length < 5) {
                                  _reasonError = 'السبب يجب أن يكون 5 أحرف على الأقل';
                                } else {
                                  _reasonError = null;
                                }
                              });
                            }
                          },
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Quick reason suggestions
                        Text(
                          'أسباب شائعة:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickReasons.map((reason) {
                            final isSelected = _reasonController.text == reason;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _reasonController.text = reason;
                                  if (_showValidationErrors) {
                                    _reasonError = null;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryTint
                                      : AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    Text(
                                      reason,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 16.0,
                bottom: 24.0 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.border.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: 'إرسال',
                onPressed: _isLoading ? null : _submitPermission,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
