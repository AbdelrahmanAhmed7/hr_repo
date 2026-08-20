import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_picker_helper.dart';
import '../../../../shared/components/custom_button.dart';
import '../../../../shared/components/custom_text_field.dart';
import '../../data/models/meeting_model.dart';
import '../cubit/meetings_cubit.dart';
import '../cubit/meetings_state.dart';
import 'department_selector.dart';

class MeetingFormSheet extends StatefulWidget {
  final MeetingsCubit cubit;
  final MeetingModel? meeting;

  const MeetingFormSheet({
    super.key,
    required this.cubit,
    this.meeting,
  });

  @override
  State<MeetingFormSheet> createState() => _MeetingFormSheetState();
}

class _MeetingFormSheetState extends State<MeetingFormSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  final Set<int> _selectedDepartmentIds = {};
  bool _showValidation = false;

  bool get _isEditing => widget.meeting != null;

  @override
  void initState() {
    super.initState();
    widget.cubit.resetActionStatus();

    final meeting = widget.meeting;
    if (meeting != null) {
      _titleController.text = meeting.title;
      _messageController.text = meeting.message;

      final date = DateTime.tryParse(meeting.meetingDate);
      if (date != null) _selectedDate = date;
      _selectedTime = _parseTime(meeting.meetingTime);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime date) =>
      DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      builder: AppTheme.getDatePickerThemeBuilder(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await TimePickerHelper.showTimePickerDialog(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  bool _validate() {
    setState(() => _showValidation = true);
    if (_titleController.text.trim().isEmpty) return false;
    if (_messageController.text.trim().isEmpty) return false;
    if (_selectedTime == null) return false;
    if (!_isEditing && _selectedDepartmentIds.isEmpty) return false;
    return true;
  }

  void _submit() {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();

    final cubit = context.read<MeetingsCubit>();
    if (_isEditing) {
      cubit.updateMeeting(
        id: widget.meeting!.id,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        meetingDate: _selectedDate,
        meetingTime: _selectedTime!,
      );
    } else {
      cubit.createMeeting(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        meetingDate: _selectedDate,
        meetingTime: _selectedTime!,
        departmentIds: _selectedDepartmentIds.toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetingsCubit, MeetingsState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == MeetingsActionStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<MeetingsCubit, MeetingsState>(
        builder: (context, state) {
          final isSubmitting =
              state.actionStatus == MeetingsActionStatus.submitting;
          final actionError =
              state.actionStatus == MeetingsActionStatus.failure &&
                      (state.actionErrorMessage?.trim().isNotEmpty ?? false)
                  ? state.actionErrorMessage
                  : null;

          return SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
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
                                _isEditing ? 'تعديل الاجتماع' : 'اجتماع جديد',
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
                                _isEditing
                                    ? 'قم بتحديث بيانات الاجتماع'
                                    : 'حدد العنوان والموعد والأقسام المستهدفة',
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
                          CustomTextField(
                            label: 'عنوان الاجتماع *',
                            placeholder: 'مثال: اجتماع الإدارة الشهري',
                            prefixIcon: Icons.title_rounded,
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            errorText: _showValidation &&
                                    _titleController.text.trim().isEmpty
                                ? 'العنوان مطلوب'
                                : null,
                            onChanged: (_) {
                              if (_showValidation) setState(() {});
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'تفاصيل الاجتماع *',
                            placeholder: 'اكتب تفاصيل الاجتماع وتوجيهاته',
                            prefixIcon: Icons.notes_rounded,
                            controller: _messageController,
                            maxLines: 4,
                            maxLength: 500,
                            errorText: _showValidation &&
                                    _messageController.text.trim().isEmpty
                                ? 'التفاصيل مطلوبة'
                                : null,
                            onChanged: (_) {
                              if (_showValidation) setState(() {});
                            },
                          ),
                          const SizedBox(height: 14),
                          _PickerField(
                            label: 'التاريخ *',
                            text: _formatDate(_selectedDate),
                            icon: Icons.calendar_today_rounded,
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 14),
                          _PickerField(
                            label: 'الوقت *',
                            text: TimePickerHelper.formatTime(_selectedTime),
                            icon: Icons.schedule_rounded,
                            hasError: _showValidation && _selectedTime == null,
                            onTap: _selectTime,
                          ),
                          if (_showValidation && _selectedTime == null) ...[
                            const SizedBox(height: 6),
                            _InlineError(message: 'الوقت مطلوب'),
                          ],
                          if (!_isEditing) ...[
                            const SizedBox(height: 20),
                            DepartmentSelector(
                              departments: state.departments,
                              selectedIds: _selectedDepartmentIds,
                              isLoading: state.departmentsStatus ==
                                  DepartmentsStatus.loading,
                              onToggle: (id) {
                                setState(() {
                                  if (!_selectedDepartmentIds.add(id)) {
                                    _selectedDepartmentIds.remove(id);
                                  }
                                });
                              },
                            ),
                            if (_showValidation &&
                                _selectedDepartmentIds.isEmpty) ...[
                              const SizedBox(height: 6),
                              _InlineError(message: 'اختر قسمًا واحدًا على الأقل'),
                            ],
                          ],
                          if (actionError != null) ...[
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
                                actionError,
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
                      text: _isEditing ? 'حفظ التعديلات' : 'إنشاء الاجتماع',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
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
              color: AppColors.backgroundSecondary,
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
                      color: text == 'اختر الوقت'
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

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: AppColors.error,
        ),
        const SizedBox(width: 6),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.error,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}