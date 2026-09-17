import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/error_state_widget.dart';
import 'cubit/task_details_cubit.dart';
import 'cubit/task_details_state.dart';
import 'cubit/tasks_cubit.dart';
import 'cubit/tasks_state.dart';
import 'models/task.dart';
import 'utils/task_labels.dart';
import 'widgets/task_basic_info_fields.dart';
import 'widgets/task_recurrence_fields.dart';
import 'widgets/task_section_card.dart';

/// Create or edit task: one-time + daily/weekly/monthly/yearly
/// recurrence builder. No departmentId/category is ever sent — the backend
/// resolves the department from assignedToUserId.
class TaskFormScreen extends StatefulWidget {
  final int? taskId;
  const TaskFormScreen({super.key, this.taskId});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  bool get _isEdit => widget.taskId != null;
  bool _formInit = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _recurrenceKey = GlobalKey<TaskRecurrenceFieldsState>();

  String? _assigneeId;
  String? _assigneeLabel;
  int _priority = 2;
  int _taskType = 0;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(hours: 8));
  TaskRecurrence? _seedRecurrence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<TasksCubit>();
      cubit.loadLookups();
      cubit.loadAssignableEmployees();
      if (_isEdit) {
        context.read<TaskDetailsCubit>().loadTask(widget.taskId!);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _prefill(TaskModel t) {
    _titleController.text = t.title;
    if (t.description?.isNotEmpty ?? false) {
      _descriptionController.text = t.description!;
    }
    if (t.estimatedHours != null && t.estimatedHours! > 0) {
      final whole = t.estimatedHours! == t.estimatedHours!.roundToDouble();
      _hoursController.text = whole
          ? t.estimatedHours!.round().toString()
          : t.estimatedHours!.toStringAsFixed(1);
    }
    _assigneeId = t.assignedToUserId;
    _assigneeLabel = t.assignedEmployeeName;
    _priority = t.priority;
    _taskType = t.taskType;
    _startDate = t.startDate ?? DateTime.now();
    _dueDate = t.dueDate ?? DateTime.now().add(const Duration(hours: 8));
    _seedRecurrence = t.recurrence;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assigneeId == null || _assigneeId!.isEmpty) {
      CustomToast.showError('اختر الموظف المسند إليه.');
      return;
    }
    if (_dueDate.isBefore(_startDate)) {
      CustomToast.showError('تاريخ الاستحقاق يجب أن يكون بعد تاريخ البدء.');
      return;
    }

    TaskRecurrence? recurrence;
    if (_taskType != 0) {
      recurrence = _recurrenceKey.currentState?.buildRecurrence(
        startDate: _startDate,
      );
      if (recurrence == null) return;
    }

    final request = TaskUpsertRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      assignedToUserId: _assigneeId!,
      priority: _priority,
      taskType: _taskType,
      startDate: _startDate,
      dueDate: _dueDate,
      estimatedHours: _hoursController.text.trim().isEmpty
          ? null
          : double.tryParse(_hoursController.text.trim()),
      recurrence: recurrence,
    );

    final cubit = context.read<TasksCubit>();
    final bool ok;
    if (_isEdit) {
      ok = await cubit.updateTask(widget.taskId!, request);
    } else {
      ok = (await cubit.createTask(request)) != null;
    }
    if (!mounted) return;
    if (ok) {
      CustomToast.showSuccess(
        _isEdit ? 'تم حفظ التعديلات بنجاح.' : 'تم إنشاء المهمة بنجاح.',
      );
      cubit.resetActionStatus();
      context.pop(true);
    } else {
      CustomToast.showError(
        cubit.state.actionErrorMessage ??
            (_isEdit ? 'تعذر حفظ التعديلات.' : 'تعذر إنشاء المهمة.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailsCubit, TaskDetailsState>(
      listenWhen: (p, c) {
        if (!_isEdit || _formInit) return false;
        return c.status == TaskDetailsStatus.success && c.task != null;
      },
      listener: (context, state) {
        setState(() {
          _prefill(state.task!);
          _formInit = true;
        });
      },
      builder: (context, detailsState) {
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
            title: Text(
              _isEdit ? 'تعديل المهمة' : 'مهمة جديدة',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          body: BlocBuilder<TasksCubit, TasksState>(
            builder: (context, state) {
              final submitting =
                  state.actionStatus == TasksActionStatus.submitting;
              if (_isEdit && !_formInit) {
                if (detailsState.status == TaskDetailsStatus.failure) {
                  return ErrorStateWidget(
                    title: 'تعذر تحميل المهمة',
                    error: detailsState.errorMessage ?? 'حدث خطأ غير متوقع.',
                    buttonLabel: 'إعادة المحاولة',
                    onRetry: () => context.read<TaskDetailsCubit>().loadTask(
                      widget.taskId!,
                    ),
                    icon: Icons.task_outlined,
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TaskSectionCard(
                        title: 'بيانات المهمة',
                        child: TaskBasicInfoFields(
                          titleController: _titleController,
                          descriptionController: _descriptionController,
                          hoursController: _hoursController,
                          assigneeId: _assigneeId,
                          assigneeLabel: _assigneeLabel,
                          assignableLoading: state.assignableLoading,
                          assignableEmployees: state.assignableEmployees,
                          lookups: state.lookups,
                          priority: _priority,
                          onPriorityChanged: (v) =>
                              setState(() => _priority = v),
                          taskType: _taskType,
                          onTaskTypeChanged: (v) =>
                              setState(() => _taskType = v),
                          startDate: _startDate,
                          dueDate: _dueDate,
                          onStartDateChanged: (d) => setState(() {
                            _startDate = d;
                            if (_dueDate.isBefore(d)) {
                              _dueDate = d.add(const Duration(hours: 8));
                            }
                          }),
                          onDueDateChanged: (d) => setState(() => _dueDate = d),
                          onAssigneeChanged: (id) =>
                              setState(() => _assigneeId = id),
                        ),
                      ),
                      if (_taskType != 0) ...[
                        const SizedBox(height: 12),
                        TaskSectionCard(
                          title:
                              'التكرار (${TaskLabels.taskTypeText(_taskType)})',
                          child: TaskRecurrenceFields(
                            key: _recurrenceKey,
                            taskType: _taskType,
                            lookups: state.lookups,
                            initial: _seedRecurrence,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            submitting
                                ? (_isEdit
                                      ? 'جاري الحفظ...'
                                      : 'جاري الإنشاء...')
                                : (_isEdit ? 'حفظ التعديلات' : 'إنشاء'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
