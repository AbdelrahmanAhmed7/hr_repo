import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_toast.dart';
import '../cubit/task_details_cubit.dart';
import '../cubit/task_details_state.dart';
import '../models/task.dart';
import 'task_action_button.dart';
import 'task_chips.dart';
import 'task_section_card.dart';

/// Status-driven action area per spec:
/// Pending→Start | InProgress→progress+Submit | Submitted→waiting |
/// Rejected→reason+Start Again | Completed→read-only | Cancelled→note.
class TaskActionCard extends StatelessWidget {
  final TaskModel task;
  final bool isManager;
  final bool isAssignee;
  final double progressDraft;
  final ValueChanged<double> onProgressChanged;

  const TaskActionCard({
    super.key,
    required this.task,
    required this.isManager,
    required this.isAssignee,
    required this.progressDraft,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskDetailsCubit>();
    final submitting =
        context.watch<TaskDetailsCubit>().state.actionStatus ==
        TaskDetailsActionStatus.submitting;
    final canAct = isAssignee;

    Widget? body;
    switch (task.status) {
      case 0: // Pending
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('المهمة بانتظار البدء.'),
            if (canAct) ...[
              const SizedBox(height: 10),
              TaskActionButton(
                label: 'بدء التنفيذ',
                icon: Icons.play_arrow_rounded,
                loading: submitting,
                onPressed: () => _run(context, cubit.start()),
              ),
            ],
          ],
        );
      case 1: // InProgress
      case 6: // Overdue — same work actions still apply
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('نسبة الإنجاز'),
                const Spacer(),
                Text(
                  '${progressDraft.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (task.progressPercentage > 0 && !canAct)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TaskProgressBar(
                  progress: task.progressPercentage,
                  height: 6,
                ),
              )
            else
              Slider(
                value: progressDraft.clamp(0, 100),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${progressDraft.round()}%',
                onChanged: canAct ? onProgressChanged : null,
              ),
            if (canAct) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TaskActionButton(
                      label: 'حفظ التقدم',
                      icon: Icons.save_outlined,
                      outlined: true,
                      loading: submitting,
                      onPressed: () => _run(
                        context,
                        cubit.updateProgress(progressDraft.round()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TaskActionButton(
                      label: 'تسليم',
                      icon: Icons.send_rounded,
                      loading: submitting,
                      onPressed: () => _run(context, cubit.submit()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      case 2: // Submitted
        body = const TaskStatusBanner(
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFF8B5CF6),
          text: 'تم التسليم — بانتظار اعتماد المدير.',
        );
      case 4: // Rejected
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (task.rejectionReason?.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'سبب الرفض: ${task.rejectionReason}',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (canAct) ...[
              const SizedBox(height: 10),
              TaskActionButton(
                label: 'بدء من جديد',
                icon: Icons.restart_alt_rounded,
                loading: submitting,
                onPressed: () => _run(context, cubit.start()),
              ),
            ],
          ],
        );
      case 3: // Completed
        body = const TaskStatusBanner(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          text: 'مهمة مكتملة ومعتمدة.',
        );
      case 5: // Cancelled
        body = const TaskStatusBanner(
          icon: Icons.block_rounded,
          color: AppColors.textTertiary,
          text: 'تم إلغاء هذه المهمة.',
        );
      default:
        body = null;
    }

    final managerApproval = isManager && task.status == 2;
    final recurrenceRow = isManager && task.isRecurringSeries;
    if (body == null && !managerApproval && !recurrenceRow) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    if (body != null) children.add(body);
    if (managerApproval) {
      children.add(const SizedBox(height: 10));
      children.add(
        Row(
          children: [
            Expanded(
              child: TaskActionButton(
                label: 'اعتماد',
                icon: Icons.check_rounded,
                color: AppColors.success,
                loading: submitting,
                onPressed: () => _run(context, cubit.approve()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TaskActionButton(
                label: 'رفض',
                icon: Icons.close_rounded,
                color: AppColors.error,
                loading: submitting,
                onPressed: () => _rejectDialog(context, cubit),
              ),
            ),
          ],
        ),
      );
    }
    if (recurrenceRow) {
      children.add(const SizedBox(height: 10));
      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TaskSmallAction(
              label: 'إيقاف مؤقت',
              icon: Icons.pause_rounded,
              loading: submitting,
              onPressed: () => _run(context, cubit.pauseRecurrence()),
            ),
            TaskSmallAction(
              label: 'استئناف',
              icon: Icons.play_arrow_rounded,
              loading: submitting,
              onPressed: () => _run(context, cubit.resumeRecurrence()),
            ),
            TaskSmallAction(
              label: 'إيقاف السلسلة',
              icon: Icons.stop_rounded,
              loading: submitting,
              onPressed: () => _run(context, cubit.stopRecurrence()),
            ),
          ],
        ),
      );
    }

    return TaskSectionCard(
      title: 'الإجراءات',
      icon: Icons.rule_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Future<void> _run(BuildContext context, Future<bool> call) async {
    final ok = await call;
    if (!context.mounted) return;
    if (ok) {
      CustomToast.showSuccess('تم تنفيذ الإجراء بنجاح.');
      context.read<TaskDetailsCubit>().resetActionStatus();
    }
  }

  void _rejectDialog(BuildContext context, TaskDetailsCubit cubit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('رفض المهمة'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (مطلوب)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                CustomToast.showError('اكتب سبب الرفض أولاً.');
                return;
              }
              Navigator.of(d).pop();
              _run(context, cubit.reject(reason));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
