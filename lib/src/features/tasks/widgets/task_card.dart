import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/tasks_cubit.dart';
import '../models/task.dart';
import '../utils/task_labels.dart';
import 'task_chips.dart';

/// Card for a single task in lists. Taps into details via ?id= query param,
/// then auto-refreshes both lists on return so status changes reflect
/// immediately without a manual pull-to-refresh.
class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  Future<void> _openDetails(BuildContext context) async {
    await context.push('/tasks/details?id=${task.id}');
    if (!context.mounted) return;
    context.read<TasksCubit>().refreshAll();
  }

  static String _formatHours(double hours) {
    final whole = hours == hours.roundToDouble();
    final s = whole
        ? hours.round().toString()
        : hours.toStringAsFixed(1);
    return '$s ساعة';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = TaskLabels.statusColor(task.status);
    final assignedName =
        (task.assignedEmployeeName?.isNotEmpty ?? false)
            ? task.assignedEmployeeName!
            : 'غير مسندة';
    final description =
        (task.description?.trim().isNotEmpty ?? false)
            ? task.description!.trim()
            : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      TaskLabels.taskTypeIcon(task.taskType),
                      color: statusColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                assignedName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((task.createdByName?.isNotEmpty ?? false))
                          const SizedBox(height: 1),
                        if ((task.createdByName?.isNotEmpty ?? false))
                          Row(
                            children: [
                              Icon(
                                Icons.account_circle_outlined,
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'بواسطة ${task.createdByName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TaskStatusChip(status: task.status),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  TaskMetaChip(
                    icon: Icons.repeat_rounded,
                    label: TaskLabels.taskTypeText(task.taskType),
                  ),
                  TaskMetaChip(
                    icon: Icons.flag_outlined,
                    label: TaskLabels.priorityText(task.priority),
                  ),
                  if ((task.departmentName?.isNotEmpty ?? false))
                    TaskMetaChip(
                      icon: Icons.business_center_outlined,
                      label: task.departmentName!,
                    ),
                  if (task.isRecurringSeries)
                    const TaskMetaChip(
                      icon: Icons.repeat_rounded,
                      label: 'متكررة',
                      color: AppColors.warning,
                    ),
                  if (task.isOccurrence)
                    const TaskMetaChip(
                      icon: Icons.all_inclusive,
                      label: 'جزء من متكررة',
                      color: AppColors.warning,
                    ),
                  if (task.estimatedHours != null && task.estimatedHours! > 0)
                    TaskMetaChip(
                      icon: Icons.schedule_outlined,
                      label: _formatHours(task.estimatedHours!),
                    ),
                  TaskMetaChip(
                    icon: Icons.event_outlined,
                    label: TaskLabels.formatDate(task.dueDate),
                    color: task.isOverdue ? AppColors.error : null,
                  ),
                ],
              ),
              if (task.progressPercentage > 0) ...[
                const SizedBox(height: 10),
                TaskProgressBar(progress: task.progressPercentage, height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
