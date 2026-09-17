import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_toast.dart';
import '../cubit/task_details_cubit.dart';
import '../cubit/task_details_state.dart';
import '../models/task_interactions.dart';
import 'task_section_card.dart';

class TaskAttachmentsCard extends StatelessWidget {
  final TaskDetailsState state;

  const TaskAttachmentsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return TaskSectionCard(
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
