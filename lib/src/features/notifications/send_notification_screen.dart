import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_text_field.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/searchable_dropdown_field.dart';
import 'cubit/send_notification_cubit.dart';
import 'cubit/send_notification_state.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    context.read<SendNotificationCubit>().loadTargets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    setState(() => _showValidation = true);

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    final cubit = context.read<SendNotificationCubit>();
    if (cubit.state.target == SendNotificationTarget.department &&
        cubit.state.selectedDepartmentId == null) {
      return;
    }
    if (cubit.state.target == SendNotificationTarget.user &&
        cubit.state.selectedEmployeeId == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    cubit.send(title: title, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('إرسال إشعار'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<SendNotificationCubit, SendNotificationState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == SendNotificationStatus.success) {
            CustomToast.showSuccess('تم إرسال الإشعار بنجاح');
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final isSending = state.status == SendNotificationStatus.loading;
          final errorMessage =
              state.status == SendNotificationStatus.failure &&
                  (state.errorMessage?.trim().isNotEmpty ?? false)
              ? state.errorMessage
              : null;

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'عنوان الإشعار *',
                    placeholder: 'مثال: إعلان عن اجتماع الفريق',
                    prefixIcon: Icons.title_rounded,
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    errorText:
                        _showValidation && _titleController.text.trim().isEmpty
                        ? 'العنوان مطلوب'
                        : null,
                    onChanged: (_) {
                      if (_showValidation) setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'نص الإشعار *',
                    placeholder: 'اكتب رسالة الإشعار التي ستصل للمستهدفين',
                    prefixIcon: Icons.notes_rounded,
                    controller: _messageController,
                    maxLines: 5,
                    maxLength: 500,
                    errorText:
                        _showValidation &&
                            _messageController.text.trim().isEmpty
                        ? 'نص الإشعار مطلوب'
                        : null,
                    onChanged: (_) {
                      if (_showValidation) setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'استهداف الإشعار',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TargetCard(
                          icon: Icons.groups_rounded,
                          label: 'كل الموظفين',
                          selected: state.target == SendNotificationTarget.all,
                          onTap: () => context
                              .read<SendNotificationCubit>()
                              .setTarget(SendNotificationTarget.all),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TargetCard(
                          icon: Icons.apartment_rounded,
                          label: 'قسم محدد',
                          selected:
                              state.target == SendNotificationTarget.department,
                          onTap: () => context
                              .read<SendNotificationCubit>()
                              .setTarget(SendNotificationTarget.department),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TargetCard(
                          icon: Icons.person_rounded,
                          label: 'موظف محدد',
                          selected: state.target == SendNotificationTarget.user,
                          onTap: () => context
                              .read<SendNotificationCubit>()
                              .setTarget(SendNotificationTarget.user),
                        ),
                      ),
                    ],
                  ),
                  if (state.target == SendNotificationTarget.department) ...[
                    const SizedBox(height: 20),
                    _Label(text: 'القسم المستهدف *'),
                    const SizedBox(height: 8),
                    _buildDepartmentField(state),
                    if (_showValidation &&
                        state.selectedDepartmentId == null) ...[
                      const SizedBox(height: 6),
                      _InlineError(message: 'اختر القسم المستهدف'),
                    ],
                  ],
                  if (state.target == SendNotificationTarget.user) ...[
                    const SizedBox(height: 20),
                    _Label(text: 'الموظف المستهدف *'),
                    const SizedBox(height: 8),
                    _buildEmployeeField(state),
                    if (_showValidation &&
                        state.selectedEmployeeId == null) ...[
                      const SizedBox(height: 6),
                      _InlineError(message: 'اختر الموظف المستهدف'),
                    ],
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 20),
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
                        errorMessage,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'إرسال الإشعار',
                    isLoading: isSending,
                    onPressed: isSending ? null : _send,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDepartmentField(SendNotificationState state) {
    if (state.departmentsStatus == TargetsStatus.loading) {
      return const _LoadingField();
    }
    if (state.departmentsStatus == TargetsStatus.failure ||
        state.departments.isEmpty) {
      return _FieldStateBox(
        message: 'تعذر تحميل الأقسام',
        onRetry: () => context.read<SendNotificationCubit>().loadTargets(),
      );
    }

    return SearchableDropdownField<int>(
      value: state.selectedDepartmentId,
      hintText: 'اختر القسم',
      searchHintText: 'ابحث عن قسم',
      isDense: true,
      items: state.departments
          .map(
            (dept) =>
                SearchableDropdownItem<int?>(value: dept.id, label: dept.name),
          )
          .toList(),
      onChanged: (id) =>
          context.read<SendNotificationCubit>().selectDepartment(id),
    );
  }

  Widget _buildEmployeeField(SendNotificationState state) {
    if (state.employeesStatus == TargetsStatus.loading) {
      return const _LoadingField();
    }
    if (state.employeesStatus == TargetsStatus.failure ||
        state.employees.isEmpty) {
      return _FieldStateBox(
        message: 'تعذر تحميل الموظفين',
        onRetry: () => context.read<SendNotificationCubit>().loadTargets(),
      );
    }

    return SearchableDropdownField<String>(
      value: state.selectedEmployeeId,
      hintText: 'اختر الموظف',
      searchHintText: 'ابحث عن موظف',
      isDense: true,
      items: state.employees
          .map(
            (recipient) => SearchableDropdownItem<String?>(
              value: recipient.id,
              label: recipient.name,
            ),
          )
          .toList(),
      onChanged: (id) =>
          context.read<SendNotificationCubit>().selectEmployee(id),
    );
  }
}

// ─── Target card ──────────────────────────────────────────────────────────────

class _TargetCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TargetCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small helpers ───────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;

  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('جاري التحميل...'),
        ],
      ),
    );
  }
}

class _FieldStateBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FieldStateBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
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
