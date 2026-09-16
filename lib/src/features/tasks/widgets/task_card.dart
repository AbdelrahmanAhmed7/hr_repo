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
    final s = whole ? hours.round().toString() : hours.toStringAsFixed(1);
    return '$s ساعة';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = TaskLabels.statusColor(task.status);
    final assignedName = (task.assignedEmployeeName?.isNotEmpty ?? false)
        ? task.assignedEmployeeName!
        : 'غير مسندة';
    final description = (task.description?.trim().isNotEmpty ?? false)
        ? task.description!.trim()
        : null;
    final priorityColor = task.priority >= 3
        ? AppColors.error
        : task.priority == 2
        ? AppColors.warning
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
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      TaskLabels.taskTypeIcon(task.taskType),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TaskStatusChip(status: task.status),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
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
                      ],
                    ),
                  ),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 5,
                children: [
                  _CardMeta(
                    icon: TaskLabels.taskTypeIcon(task.taskType),
                    text: TaskLabels.taskTypeText(task.taskType),
                  ),
                  _CardMeta(
                    icon: Icons.flag_outlined,
                    text: TaskLabels.priorityText(task.priority),
                    color: priorityColor,
                  ),
                  if ((task.departmentName?.isNotEmpty ?? false))
                    _CardMeta(
                      icon: Icons.business_center_outlined,
                      text: task.departmentName!,
                    ),
                  if (task.estimatedHours != null && task.estimatedHours! > 0)
                    _CardMeta(
                      icon: Icons.schedule_outlined,
                      text: _formatHours(task.estimatedHours!),
                    ),
                  if (task.isRecurringSeries)
                    _CardMeta(
                      icon: Icons.repeat_rounded,
                      text: 'متكررة',
                      color: AppColors.warning,
                    ),
                  if (task.isOccurrence)
                    _CardMeta(
                      icon: Icons.all_inclusive,
                      text: 'جزء من متكررة',
                      color: AppColors.warning,
                    ),
                  _CardMeta(
                    icon: Icons.event_outlined,
                    text: TaskLabels.formatDate(task.dueDate),
                    color: task.isOverdue ? AppColors.error : null,
                  ),
                ],
              ),
              if (task.progressPercentage > 0) ...[
                const SizedBox(height: 12),
                TaskProgressBar(progress: task.progressPercentage, height: 5),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact icon + text metadata line used inside task cards.
class _CardMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _CardMeta({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
