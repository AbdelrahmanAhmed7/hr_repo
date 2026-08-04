import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/leave_type_model.dart';

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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (leaveTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر نوع الإجازة',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...leaveTypes.map((leaveType) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTypeCard(
                context,
                type: leaveType,
                title: leaveType.nameAr,
                description: _getDescriptionForLeaveType(leaveType.name),
                icon: _getIconForLeaveType(leaveType.name),
              ),
            );
          }),
        ],
      ),
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
      child: Container(
        padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
