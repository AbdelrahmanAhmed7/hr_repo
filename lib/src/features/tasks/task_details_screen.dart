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
import 'widgets/task_action_card.dart';
import 'widgets/task_attachments_card.dart';
import 'widgets/task_comments_card.dart';
import 'widgets/task_header_card.dart';
import 'widgets/task_section_card.dart';

/// Task details (?id=): info, status-driven actions, comments, attachments.
class TaskDetailsScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _commentController = TextEditingController();
  double _progressDraft = 0;
  int? _lastTaskId;
  bool _draftTouched = false;

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
          final taskProgress = task.progressPercentage.toDouble();
          if (task.id != _lastTaskId ||
              (!_draftTouched && _progressDraft != taskProgress)) {
            _lastTaskId = task.id;
            _progressDraft = taskProgress;
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
                  TaskHeaderCard(task: task, isManager: _isManager),
                  const SizedBox(height: 12),
                  TaskActionCard(
                    task: task,
                    isManager: _isManager,
                    isAssignee: _isAssignee(task),
                    progressDraft: _progressDraft,
                    onProgressChanged: (v) => setState(() {
                      _progressDraft = v;
                      _draftTouched = true;
                    }),
                  ),
                  if (task.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    TaskSectionCard(
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
                  TaskCommentsCard(
                    state: state,
                    controller: _commentController,
                  ),
                  const SizedBox(height: 12),
                  TaskAttachmentsCard(state: state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
