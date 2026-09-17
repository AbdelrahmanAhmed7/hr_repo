import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/task_details_cubit.dart';
import '../models/task.dart';
import '../utils/task_labels.dart';
import 'task_chips.dart';

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;

  const _DateBox({required this.label, required this.icon, this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            TaskLabels.formatDate(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskHeaderCard extends StatelessWidget {
  final TaskModel task;
  final bool isManager;

  const TaskHeaderCard({super.key, required this.task, this.isManager = false});

  Future<void> _edit(BuildContext context) async {
    final updated = await context.push<bool>('/tasks/edit?id=${task.id}');
    if (updated == true && context.mounted) {
      context.read<TaskDetailsCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = TaskLabels.statusColor(task.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [statusColor.withValues(alpha: 0.08), Colors.white],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TaskStatusChip(status: task.status)),
              if (task.isOverdue && !task.isCompleted)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'متأخرة عن الموعد',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (isManager) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _edit(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'تعديل',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TaskMetaChip(
                icon: TaskLabels.taskTypeIcon(task.taskType),
                label: TaskLabels.taskTypeText(task.taskType),
              ),
              TaskMetaChip(
                icon: Icons.flag_outlined,
                label: TaskLabels.priorityText(task.priority),
              ),
              if (task.departmentName?.isNotEmpty == true)
                TaskMetaChip(
                  icon: Icons.business_outlined,
                  label: task.departmentName!,
                ),
              if (task.isOccurrence)
                const TaskMetaChip(
                  icon: Icons.repeat_rounded,
                  label: 'تكرار من سلسلة',
                ),
            ],
          ),
          const Divider(height: 24),
          _MetaLine(
            icon: Icons.person_outline,
            label: 'المسند إليه',
            value: task.assignedEmployeeName?.isNotEmpty == true
                ? task.assignedEmployeeName!
                : '--',
          ),
          _MetaLine(
            icon: Icons.account_circle_outlined,
            label: 'أنشأها',
            value: task.createdByName ?? '--',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateBox(
                  label: 'تاريخ البدء',
                  icon: Icons.play_circle_outline,
                  date: task.startDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateBox(
                  label: 'تاريخ الاستحقاق',
                  icon: Icons.event_outlined,
                  date: task.dueDate,
                ),
              ),
            ],
          ),
          if (task.estimatedHours case final hours?) ...[
            const SizedBox(height: 10),
            _MetaLine(
              icon: Icons.schedule_outlined,
              label: 'الساعات المقدرة',
              value: TaskLabels.formatHours(hours),
            ),
          ],
          if (task.completedAt case final doneAt?) ...[
            const SizedBox(height: 6),
            _MetaLine(
              icon: Icons.check_circle_outline,
              label: 'تاريخ الإنجاز',
              value: TaskLabels.formatDate(doneAt),
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: 12),
          TaskProgressBar(progress: task.progressPercentage),
        ],
      ),
    );
  }
}
