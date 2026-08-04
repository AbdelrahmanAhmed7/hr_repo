import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/custom_text_field.dart';
import '../../../shared/mixins/keyboard_dismiss_mixin.dart';
import '../cubit/overtime_cubit.dart';
import '../cubit/overtime_state.dart';

class CreateOvertimeBottomSheet extends StatefulWidget {
  const CreateOvertimeBottomSheet({super.key});

  @override
  State<CreateOvertimeBottomSheet> createState() =>
      _CreateOvertimeBottomSheetState();
}

class _CreateOvertimeBottomSheetState extends State<CreateOvertimeBottomSheet>
    with KeyboardDismissMixin {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _reasonFocus = FocusNode();

  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay? _endTime = const TimeOfDay(hour: 19, minute: 0);
  bool _showValidation = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('ar'),
      builder: AppTheme.getDatePickerThemeBuilder(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 17, minute: 0),
      builder: AppTheme.getTimePickerThemeBuilder(),
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        if (_endTime != null && !_isEndTimeAfterStart()) {
          _endTime = _addHours(picked, 2);
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    if (_startTime == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _addHours(_startTime!, 2),
      builder: AppTheme.getTimePickerThemeBuilder(),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  TimeOfDay _addHours(TimeOfDay time, int hours) {
    final totalMinutes = (time.hour * 60) + time.minute + (hours * 60);
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  void _applyQuickPreset({
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    String? reason,
  }) {
    setState(() {
      _selectedDate = date;
      _startTime = start;
      _endTime = end;
      if (reason != null && _reasonController.text.trim().isEmpty) {
        _reasonController.text = reason;
      }
    });
  }

  int? _durationInMinutes() {
    if (_startTime == null || _endTime == null) return null;

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    var endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes == startMinutes) return null;
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    return endMinutes - startMinutes;
  }

  bool _crossesMidnight() {
    if (_startTime == null || _endTime == null) return false;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    return endMinutes < startMinutes;
  }

  bool _isEndTimeAfterStart() {
    final duration = _durationInMinutes();
    return duration != null && duration > 0;
  }

  bool _validate() {
    setState(() => _showValidation = true);
    if (_selectedDate == null) return false;
    if (_startTime == null || _endTime == null) return false;
    if (!_isEndTimeAfterStart()) return false;
    if (_reasonController.text.trim().length < 5) return false;
    return true;
  }

  void _submit() {
    if (!_validate()) return;

    context.read<OvertimeCubit>().createOvertime(
          date: _selectedDate!,
          startTime: _toApiTime(_startTime!),
          endTime: _toApiTime(_endTime!),
          reason: _reasonController.text.trim(),
        );
  }

  String _toApiTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'اختر التاريخ';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'اختر الوقت';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _durationText() {
    final diff = _durationInMinutes();
    if (diff == null || diff <= 0) return '';
    final hours = diff ~/ 60;
    final minutes = diff % 60;
    if (minutes == 0) {
      return hours == 1 ? '1 ساعة' : '$hours ساعات';
    }
    if (hours == 0) {
      return '$minutes دقيقة';
    }
    return '$hours س و $minutes د';
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    return BlocListener<OvertimeCubit, OvertimeState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == OvertimeSubmissionStatus.success) {
          context.read<OvertimeCubit>().clearSubmissionState();
          Navigator.of(context).pop(true);
        }
      },
      child: SafeArea(
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
          child: BlocBuilder<OvertimeCubit, OvertimeState>(
            builder: (context, state) {
              final submissionError = state.submissionStatus ==
                      OvertimeSubmissionStatus.failure
                  ? state.submissionErrorMessage
                  : null;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب عمل إضافي',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'حدد اليوم والوقت والسبب ثم راجع الملخص قبل الإرسال.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuickPresetsSection(
                            onTodayPressed: () => _applyQuickPreset(
                              date: DateTime.now(),
                              start: const TimeOfDay(hour: 17, minute: 0),
                              end: const TimeOfDay(hour: 19, minute: 0),
                              reason: 'استكمال مهام العمل',
                            ),
                            onTomorrowPressed: () => _applyQuickPreset(
                              date: DateTime(
                                tomorrow.year,
                                tomorrow.month,
                                tomorrow.day,
                              ),
                              start: const TimeOfDay(hour: 17, minute: 0),
                              end: const TimeOfDay(hour: 20, minute: 0),
                              reason: 'ضغط عمل إضافي',
                            ),
                            onNightShiftPressed: () => _applyQuickPreset(
                              date: _selectedDate ?? DateTime.now(),
                              start: const TimeOfDay(hour: 19, minute: 0),
                              end: const TimeOfDay(hour: 22, minute: 0),
                              reason: 'تسليم مهام عاجلة',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _LiveSummaryCard(
                            selectedDate: _selectedDate,
                            startTime: _startTime,
                            endTime: _endTime,
                            durationText: _durationText(),
                            crossesMidnight: _crossesMidnight(),
                          ),
                          const SizedBox(height: 16),
                          _PickerField(
                            label: 'التاريخ *',
                            text: _formatDate(_selectedDate),
                            icon: Icons.calendar_today_rounded,
                            hasError: _showValidation && _selectedDate == null,
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _PickerField(
                                  label: 'من *',
                                  text: _formatTime(_startTime),
                                  icon: Icons.login_rounded,
                                  hasError:
                                      _showValidation && _startTime == null,
                                  onTap: _selectStartTime,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PickerField(
                                  label: 'إلى *',
                                  text: _crossesMidnight()
                                      ? '${_formatTime(_endTime)} (اليوم التالي)'
                                      : _formatTime(_endTime),
                                  icon: Icons.logout_rounded,
                                  hasError: _showValidation &&
                                      (_endTime == null ||
                                          (_startTime != null &&
                                              !_isEndTimeAfterStart())),
                                  onTap: _selectEndTime,
                                ),
                              ),
                            ],
                          ),
                          if (_showValidation &&
                              _startTime != null &&
                              _endTime != null &&
                              !_isEndTimeAfterStart()) ...[
                            const SizedBox(height: 8),
                            Text(
                              _startTime != null && _endTime != null
                                  ? 'يمكنك اختيار وقت صباحي مثل 12 أو 1 صباحًا وسيُحسب لليوم التالي.'
                                  : 'حدد وقت البداية والنهاية بشكل صحيح.',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _ReasonSuggestionChips(
                            onSelected: (text) {
                              setState(() {
                                _reasonController.text = text;
                                _reasonController.selection =
                                    TextSelection.collapsed(
                                  offset: _reasonController.text.length,
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'السبب *',
                            placeholder:
                                'اكتب سبب طلب العمل الإضافي بشكل واضح ومختصر',
                            prefixIcon: Icons.description_outlined,
                            controller: _reasonController,
                            focusNode: _reasonFocus,
                            textInputAction: TextInputAction.done,
                            maxLines: 3,
                            maxLength: 250,
                            errorText: _showValidation &&
                                    _reasonController.text.trim().length < 5
                                ? (_reasonController.text.trim().isEmpty ? 'السبب مطلوب' : 'السبب يجب أن يكون 5 أحرف على الأقل')
                                : null,
                            onChanged: (_) {
                              if (_showValidation) {
                                setState(() {});
                              }
                            },
                          ),
                          if (submissionError != null &&
                              submissionError.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorTint,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                submissionError,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      24 + MediaQuery.of(context).padding.bottom,
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
                      text: 'إرسال الطلب',
                      isLoading: state.submissionStatus ==
                          OvertimeSubmissionStatus.submitting,
                      onPressed: state.submissionStatus ==
                              OvertimeSubmissionStatus.submitting
                          ? null
                          : _submit,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickPresetsSection extends StatelessWidget {
  final VoidCallback onTodayPressed;
  final VoidCallback onTomorrowPressed;
  final VoidCallback onNightShiftPressed;

  const _QuickPresetsSection({
    required this.onTodayPressed,
    required this.onTomorrowPressed,
    required this.onNightShiftPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اقتراحات سريعة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SuggestionChip(
              label: 'اليوم 5 - 7',
              onTap: onTodayPressed,
            ),
            _SuggestionChip(
              label: 'غدًا 5 - 8',
              onTap: onTomorrowPressed,
            ),
            _SuggestionChip(
              label: 'مساء 7 - 10',
              onTap: onNightShiftPressed,
            ),
          ],
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
      ),
      backgroundColor: AppColors.primaryTint,
      side: const BorderSide(color: AppColors.primaryTint),
      onPressed: onTap,
    );
  }
}

class _LiveSummaryCard extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String durationText;
  final bool crossesMidnight;

  const _LiveSummaryCard({
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.durationText,
    required this.crossesMidnight,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الطلب',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                icon: Icons.event_rounded,
                label: _formatDate(selectedDate),
              ),
              _SummaryPill(
                icon: Icons.login_rounded,
                label: _formatTime(startTime),
              ),
              _SummaryPill(
                icon: Icons.logout_rounded,
                label: crossesMidnight
                    ? '${_formatTime(endTime)} - اليوم التالي'
                    : _formatTime(endTime),
              ),
              if (durationText.isNotEmpty)
                _SummaryPill(
                  icon: Icons.timer_outlined,
                  label: durationText,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReasonSuggestionChips extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _ReasonSuggestionChips({
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'استكمال مهام العمل',
      'تسليم عاجل',
      'ضغط عمل إضافي',
      'جرد ومراجعة',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions
          .map(
            (text) => ActionChip(
              label: Text(text),
              onPressed: () => onSelected(text),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
            ),
          )
          .toList(),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final bool hasError;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.text,
    required this.icon,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: text.contains('اختر')
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
