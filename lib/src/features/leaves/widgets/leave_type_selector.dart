import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/leave_type_model.dart';

/// Leave-type picker rendered as a compact list of cards.
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
        return 'للحالات المرضية (يتطلب إرفاق تقرير طبي) *';
      case 'maternity':
        return 'إجازة الوضع للأمهات (90 يوم)';
      case 'paternity':
        return 'إجازة الأبوة (يوم واحد) *';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final leaveType in leaveTypes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildTypeCard(
              context,
              type: leaveType,
              title: leaveType.nameAr,
              description: _getDescriptionForLeaveType(leaveType.name),
              icon: _getIconForLeaveType(leaveType.name),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required LeaveTypeModel type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedTypeId == type.id;

    return InkWell(
      onTap: () => onTypeSelected(type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}