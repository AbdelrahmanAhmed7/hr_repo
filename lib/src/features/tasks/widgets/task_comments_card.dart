import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/task_details_cubit.dart';
import '../cubit/task_details_state.dart';
import '../utils/task_labels.dart';
import 'task_section_card.dart';

class TaskCommentsCard extends StatelessWidget {
  final TaskDetailsState state;
  final TextEditingController controller;

  const TaskCommentsCard({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TaskSectionCard(
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
