import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_text_field.dart';
import 'leave_attachment_picker.dart';

class LeaveReasonField extends StatelessWidget {
  final TextEditingController controller;
  final String? leaveType;
  final String? attachmentPath;
  final Function(String?) onPickAttachment;
  final VoidCallback onRemoveAttachment;

  const LeaveReasonField({
    super.key,
    required this.controller,
    this.leaveType,
    this.attachmentPath,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final isSickLeave = leaveType?.toLowerCase() == 'sick';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'سبب الإجازة',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          CustomTextField(
            label: 'السبب *',
            placeholder: 'اكتب سبب الإجازة (5 أحرف على الأقل)',
            prefixIcon: Icons.description_outlined,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
            maxLength: 250,
            controller: controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
          ),
          
          if (isSickLeave) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يجب إرفاق تقرير طبي للإجازات المرضية',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Text(
                isSickLeave ? 'التقرير الطبي *' : 'مرفق (اختياري)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (isSickLeave) ...[
                const SizedBox(width: 4),
                Text(
                  '(مطلوب للإجازة المرضية)',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.error,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          LeaveAttachmentPicker(
            attachmentPath: attachmentPath,
            onAttachmentSelected: onPickAttachment,
            onAttachmentRemoved: onRemoveAttachment,
          ),
        ],
      ),
    );
  }
}