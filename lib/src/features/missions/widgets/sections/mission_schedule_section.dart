import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../create_mission_controller.dart';

class MissionScheduleSection extends StatelessWidget {
  final CreateMissionController controller;

  const MissionScheduleSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'التاريخ *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                const Text(
                  'أكثر من يوم',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Switch(
                  value: controller.isMultiDay,
                  onChanged: controller.toggleMultiDay,
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!controller.isMultiDay) ...[
          InkWell(
            onTap: () => controller.pickStartDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    controller.formatDate(controller.selectedDate),
                    style: TextStyle(
                      color: controller.selectedDate == null
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickDateButton(
                label: 'اليوم',
                selected: controller.isQuickDateSelected('اليوم'),
                onTap: () => controller.selectQuickDate(0),
              ),
              _QuickDateButton(
                label: 'غداً',
                selected: controller.isQuickDateSelected('غداً'),
                onTap: () => controller.selectQuickDate(1),
              ),
              _QuickDateButton(
                label: 'بعد غد',
                selected: controller.isQuickDateSelected('بعد غد'),
                onTap: () => controller.selectQuickDate(2),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'من',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => controller.pickStartDate(context),
                      child: _DateCell(
                        value: controller.formatDate(controller.selectedDate),
                        hasValue: controller.selectedDate != null,
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
                    const Text(
                      'إلى',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => controller.pickEndDate(context),
                      child: _DateCell(
                        value: controller.formatDate(controller.endDate),
                        hasValue: controller.endDate != null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DateCell extends StatelessWidget {
  final String value;
  final bool hasValue;

  const _DateCell({required this.value, required this.hasValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickDateButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickDateButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primaryTint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
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
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

