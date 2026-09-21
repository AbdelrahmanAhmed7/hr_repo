import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/leave_type_model.dart';

/// Leave-type picker rendered as a compact wrap of chips.
///
/// Meant to be embedded in the parent scroll view — this widget does not own
/// its own scrolling or a page headline.
class LeaveTypeSelector extends StatelessWidget {
  final int? selectedTypeId;
  final List<LeaveTypeModel> leaveTypes;
  final bool isLoading;
  final Function(LeaveTypeModel) onTypeSelected;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const LeaveTypeSelector({
    super.key,
    required this.selectedTypeId,
    required this.leaveTypes,
    this.isLoading = false,
    required this.onTypeSelected,
    this.onRetry,
    this.errorMessage,
  });

  IconData _getIconForLeaveType(String type) {
    switch (type.toLowerCase()) {
      case 'annual':
        return Icons.calendar_today_rounded;
      case 'casual':
        return Icons.event_available_rounded;
      case 'sick':
        return Icons.medical_services_rounded;
      case 'maternity':
        return Icons.pregnant_woman_rounded;
      case 'paternity':
        return Icons.family_restroom_rounded;
      case 'hajj':
        return Icons.mosque_rounded;
      case 'exam':
        return Icons.school_rounded;
      case 'paid':
        return Icons.paid_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  String _getDescriptionForLeaveType(String type) {
    switch (type.toLowerCase()) {
      case 'annual':
        return 'للإجازات السنوية المقررة';
      case 'casual':
        return 'للأمور الشخصية العارضة (يوم واحد)';
      case 'sick':
        return 'للمرض ويحتاج إلى إرفاق تقرير طبي';
      case 'maternity':
        return 'إجازة الوضع (90 يوم)';
      case 'paternity':
        return 'إجازة الأبوة (يوم واحد)';
      case 'hajj':
        return 'إجازة الحج (15 يوم)';
      case 'exam':
        return 'إجازة الامتحانات';
      case 'paid':
        return 'إجازة مدفوعة الأجر';
      default:
        return 'إجازة';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (leaveTypes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage?.trim().isNotEmpty == true
                    ? (errorMessage!)
                    : 'لا توجد أنواع إجازات متاحة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final selectedDescription = leaveTypes
        .where((t) => t.id == selectedTypeId)
        .map((t) => _getDescriptionForLeaveType(t.name))
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in leaveTypes) _buildTypeChip(context, type),
          ],
        ),
        if (selectedDescription != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDescription,
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
      ],
    );
  }

  Widget _buildTypeChip(BuildContext context, LeaveTypeModel type) {
    final isSelected = selectedTypeId == type.id;

    return InkWell(
      onTap: () => onTypeSelected(type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForLeaveType(type.name),
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                type.nameAr,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}