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
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [
            _SlotTile(
              title: 'يوم كامل',
              subtitle: '24 ساعة',
              icon: Icons.wb_sunny,
              selected: controller.selectedTimeSlot == 'full_day',
              onTap: () => controller.selectTimeSlot('full_day'),
            ),
            if (!controller.isMultiDay)
              _SlotTile(
                title: 'صباحية',
                subtitle: '9 - 1',
                icon: Icons.wb_twilight,
                selected: controller.selectedTimeSlot == 'morning',
                onTap: () => controller.selectTimeSlot('morning'),
              ),
            if (!controller.isMultiDay)
              _SlotTile(
                title: 'مسائية',
                subtitle: '1 - 5',
                icon: Icons.dark_mode_outlined,
                selected: controller.selectedTimeSlot == 'afternoon',
                onTap: () => controller.selectTimeSlot('afternoon'),
              ),
            _SlotTile(
              title: 'مخصص',
              subtitle: controller.selectedTimeSlot == 'custom' &&
                      controller.startTime != null &&
                      controller.endTime != null
                  ? '${controller.formatTime(controller.startTime)} - ${controller.formatTime(controller.endTime)}'
                  : 'حدد الوقت',
              icon: Icons.schedule,
              selected: controller.selectedTimeSlot == 'custom',
              onTap: controller.selectCustomTime,
            ),
          ],
        ),
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
        if (!controller.isMultiDay) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'مدة سريعة:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _QuickDurationChip(
                      label: 'ساعة',
                      onTap: () => controller.applyQuickDuration(1),
                    ),
                    _QuickDurationChip(
                      label: 'ساعتين',
                      onTap: () => controller.applyQuickDuration(2),
                    ),
                    _QuickDurationChip(
                      label: '3 ساعات',
                      onTap: () => controller.applyQuickDuration(3),
                    ),
                    _QuickDurationChip(
                      label: '4 ساعات',
                      onTap: () => controller.applyQuickDuration(4),
                    ),
                  ],
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

class _QuickDurationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDurationChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

class _SlotTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SlotTile({
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
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

