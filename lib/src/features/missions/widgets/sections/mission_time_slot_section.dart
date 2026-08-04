import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../create_mission_controller.dart';

class MissionTimeSlotSection extends StatelessWidget {
  final CreateMissionController controller;

  const MissionTimeSlotSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final durationText = controller.calculateDuration();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الفترة الزمنية *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _TimeSlotCard(
          slotKey: 'full_day',
          title: 'يوم كامل',
          subtitle: '24 ساعة (طوال اليوم)',
          icon: Icons.wb_sunny,
          selected: controller.selectedTimeSlot == 'full_day',
          onTap: () => controller.selectTimeSlot('full_day'),
        ),
        if (!controller.isMultiDay) ...[
          const SizedBox(height: 12),
          _TimeSlotCard(
            slotKey: 'morning',
            title: 'فترة صباحية',
            subtitle: '9:00 - 1:00 (4 ساعات)',
            icon: Icons.wb_twilight,
            selected: controller.selectedTimeSlot == 'morning',
            onTap: () => controller.selectTimeSlot('morning'),
          ),
          const SizedBox(height: 12),
          _TimeSlotCard(
            slotKey: 'afternoon',
            title: 'فترة مسائية',
            subtitle: '1:00 - 5:00 (4 ساعات)',
            icon: Icons.dark_mode_outlined,
            selected: controller.selectedTimeSlot == 'afternoon',
            onTap: () => controller.selectTimeSlot('afternoon'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: controller.selectCustomTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller.selectedTimeSlot == 'custom'
                    ? AppColors.primaryTint
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.selectedTimeSlot == 'custom'
                      ? AppColors.primary
                      : AppColors.border,
                  width: controller.selectedTimeSlot == 'custom' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: controller.selectedTimeSlot == 'custom'
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'وقت مخصص',
                      style: TextStyle(
                        color: controller.selectedTimeSlot == 'custom'
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: controller.selectedTimeSlot == 'custom'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (controller.selectedTimeSlot == 'custom')
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        ],
        if (controller.selectedTimeSlot == 'custom') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimePickerCell(
                  label: 'من',
                  value: controller.formatTime(controller.startTime),
                  hasValue: controller.startTime != null,
                  onTap: () => controller.pickStartTime(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerCell(
                  label: 'إلى',
                  value: controller.formatTime(controller.endTime),
                  hasValue: controller.endTime != null,
                  onTap: () => controller.pickEndTime(context),
                ),
              ),
            ],
          ),
        ],
        if (controller.startTime != null &&
            controller.endTime != null &&
            durationText.isNotEmpty) ...[
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
                  'المدة: $durationText',
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
    );
  }
}

class _TimePickerCell extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  const _TimePickerCell({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
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
                  value,
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final String slotKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TimeSlotCard({
    required this.slotKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

