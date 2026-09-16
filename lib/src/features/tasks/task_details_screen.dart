import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'cubit/task_details_cubit.dart';
import 'cubit/task_details_state.dart';
import 'models/task.dart';
import 'models/task_interactions.dart';
import 'utils/task_labels.dart';
import 'widgets/task_chips.dart';

/// Task details (?id=): info, status-driven actions, comments,
/// attachments and history.
class TaskDetailsScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _commentController = TextEditingController();
  double _progressDraft = 0;
  bool _progressInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TaskDetailsCubit>().loadTask(widget.taskId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isManager {
    final role = context.read<AuthCubit>().state.role;
    return role == UserRole.admin || role == UserRole.superAdmin;
  }

  bool _isAssignee(TaskModel task) {
    final userId = context.read<AuthCubit>().state.userId;
    return userId != null &&
        userId.isNotEmpty &&
        userId == task.assignedToUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/tasks'),
        ),
        title: BlocBuilder<TaskDetailsCubit, TaskDetailsState>(
          buildWhen: (p, c) => p.task?.title != c.task?.title,
          builder: (context, state) {
            final t = state.task?.title.trim();
            return Text(
              (t == null || t.isEmpty) ? 'تفاصيل المهمة' : t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            );
          },
        ),
      ),
      body: BlocConsumer<TaskDetailsCubit, TaskDetailsState>(
        listenWhen: (p, c) =>
            p.actionStatus != c.actionStatus &&
            c.actionStatus == TaskDetailsActionStatus.failure,
        listener: (context, state) {
          CustomToast.showError(
            state.actionErrorMessage ?? 'حدث خطأ غير متوقع.',
          );
          context.read<TaskDetailsCubit>().resetActionStatus();
        },
        builder: (context, state) {
          if (state.status == TaskDetailsStatus.loading && state.task == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TaskDetailsStatus.failure && state.task == null) {
            return ErrorStateWidget(
              title: 'تعذر تحميل المهمة',
              error: state.errorMessage ?? 'حدث خطأ غير متوقع.',
              buttonLabel: 'إعادة المحاولة',
              onRetry: () =>
                  context.read<TaskDetailsCubit>().loadTask(widget.taskId),
              icon: Icons.task_outlined,
            );
          }
          final task = state.task;
          if (task == null) {
            return const EmptyStateWidget(
              icon: Icons.task_outlined,
              title: 'لا توجد مهمة',
              message: 'تأكد من رقم المهمة وحاول مجددًا.',
              iconColor: AppColors.textTertiary,
            );
          }
          if (!_progressInit) {
            _progressDraft = task.progressPercentage.toDouble();
            _progressInit = true;
          }
          return RefreshIndicator(
            onRefresh: () => context.read<TaskDetailsCubit>().refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskHeaderCard(task: task, isManager: _isManager),
                  const SizedBox(height: 12),
                  _ActionCard(
                    task: task,
                    isManager: _isManager,
                    isAssignee: _isAssignee(task),
                    progressDraft: _progressDraft,
                    onProgressChanged: (v) =>
                        setState(() => _progressDraft = v),
                  ),
                  if (task.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'الوصف',
                      icon: Icons.notes_rounded,
                      child: Text(
                        task.description!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _CommentsCard(state: state, controller: _commentController),
                  const SizedBox(height: 12),
                  _AttachmentsCard(state: state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskHeaderCard extends StatelessWidget {
  final TaskModel task;
  final bool isManager;
  const _TaskHeaderCard({required this.task, this.isManager = false});

  static String _formatHours(double hours) {
    final whole = hours == hours.roundToDouble();
    final s = whole ? hours.round().toString() : hours.toStringAsFixed(1);
    return '$s ساعة';
  }

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
              value: _formatHours(hours),
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

/// Status-driven action area per spec:
/// Pending→Start | InProgress→progress+Submit | Submitted→waiting |
/// Rejected→reason+Start Again | Completed→read-only | Cancelled→note.
class _ActionCard extends StatelessWidget {
  final TaskModel task;
  final bool isManager;
  final bool isAssignee;
  final double progressDraft;
  final ValueChanged<double> onProgressChanged;

  const _ActionCard({
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
              _ActionButton(
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
                    child: _ActionButton(
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
                    child: _ActionButton(
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
        body = const _StatusBanner(
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
              _ActionButton(
                label: 'بدء من جديد',
                icon: Icons.restart_alt_rounded,
                loading: submitting,
                onPressed: () => _run(context, cubit.start()),
              ),
            ],
          ],
        );
      case 3: // Completed
        body = const _StatusBanner(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          text: 'مهمة مكتملة ومعتمدة.',
        );
      case 5: // Cancelled
        body = const _StatusBanner(
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
              child: _ActionButton(
                label: 'اعتماد',
                icon: Icons.check_rounded,
                color: AppColors.success,
                loading: submitting,
                onPressed: () => _run(context, cubit.approve()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
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
            _SmallAction(
              label: 'إيقاف مؤقت',
              icon: Icons.pause_rounded,
              loading: submitting,
              onPressed: () => _run(context, cubit.pauseRecurrence()),
            ),
            _SmallAction(
              label: 'استئناف',
              icon: Icons.play_arrow_rounded,
              loading: submitting,
              onPressed: () => _run(context, cubit.resumeRecurrence()),
            ),
            _SmallAction(
              label: 'إيقاف السلسلة',
              icon: Icons.stop_rounded,
              loading: submitting,
              onPressed: () => _run(context, cubit.stopRecurrence()),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;
  final bool outlined;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;

  const _SmallAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

/// Tinted read-only status banner for terminal task states.
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  const _SectionCard({required this.title, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  final TaskDetailsState state;
  final TextEditingController controller;
  const _CommentsCard({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'التعليقات (${state.comments.length})',
      icon: Icons.chat_bubble_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.commentsLoading && state.comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (state.comments.isEmpty)
            const Text('لا توجد تعليقات بعد.'),
          ...state.comments.map((c) {
            final myId = context.read<AuthCubit>().state.userId;
            final isMine = c.userId != null && myId != null && c.userId == myId;
            final author = isMine
                ? 'أنت'
                : (c.createdByName?.isNotEmpty == true
                      ? c.createdByName!
                      : 'مستخدم');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: isMine
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 76,
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                      decoration: BoxDecoration(
                        color: isMine ? AppColors.primaryTint : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMine ? 16 : 4),
                          bottomRight: Radius.circular(isMine ? 4 : 16),
                        ),
                        border: isMine
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: isMine
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (c.createdAt case final commentedAt?) ...[
                                const SizedBox(width: 8),
                                Text(
                                  TaskLabels.formatDate(commentedAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.comment,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(context),
                  decoration: const InputDecoration(
                    hintText: 'اكتب تعليقًا...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _send(context),
                icon: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _send(BuildContext context) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final ok = await context.read<TaskDetailsCubit>().addComment(text);
    if (ok) controller.clear();
    if (context.mounted) {
      context.read<TaskDetailsCubit>().resetActionStatus();
    }
  }
}

class _AttachmentsCard extends StatelessWidget {
  final TaskDetailsState state;
  const _AttachmentsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'المرفقات (${state.attachments.length})',
      icon: Icons.attach_file_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.attachmentsLoading && state.attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (state.attachments.isEmpty)
            const Text('لا توجد مرفقات.'),
          ...state.attachments.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.fileName.isNotEmpty ? a.fileName : a.fileUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (a.fileName.isNotEmpty)
                          Text(
                            a.fileUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _addDialog(context),
            icon: const Icon(Icons.add_link_rounded, size: 18),
            label: const Text('إضافة مرفق (اسم + رابط)'),
          ),
        ],
      ),
    );
  }

  void _addDialog(BuildContext context) {
    final name = TextEditingController();
    final url = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('إضافة مرفق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'اسم الملف',
                hintText: 'report.pdf',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: url,
              decoration: const InputDecoration(
                labelText: 'رابط الملف',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final fileName = name.text.trim();
              final fileUrl = url.text.trim();
              if (fileName.isEmpty || fileUrl.isEmpty) {
                CustomToast.showError('أدخل الاسم والرابط.');
                return;
              }
              Navigator.of(d).pop();
              final ok = await context.read<TaskDetailsCubit>().addAttachment(
                TaskAttachment(fileName: fileName, fileUrl: fileUrl),
              );
              if (context.mounted) {
                if (ok) {
                  CustomToast.showSuccess('تمت إضافة المرفق.');
                }
                context.read<TaskDetailsCubit>().resetActionStatus();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
