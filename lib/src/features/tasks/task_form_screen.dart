import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/searchable_dropdown_field.dart';
import 'cubit/task_details_cubit.dart';
import 'cubit/task_details_state.dart';
import 'cubit/tasks_cubit.dart';
import 'cubit/tasks_state.dart';
import 'models/task.dart';
import 'models/task_lookups.dart';
import 'utils/task_labels.dart';

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
  final _intervalController = TextEditingController(text: '1');

  String? _assigneeId;
  String? _assigneeLabel;
  int _priority = 2;
  int _taskType = 0;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(hours: 8));
  DateTime? _endDate;

  // Daily
  int _occurrencesPerDay = 1;
  List<String> _dueTimes = ['10:00:00'];

  // Weekly
  final Set<int> _daysOfWeek = {0};

  // Monthly / yearly
  int _dayOfMonth = 1;
  int _monthlyMode = 0;
  int _monthOfYear = 1;

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
    _intervalController.dispose();
    super.dispose();
  }

  List<LookupItem> _fallback(List<LookupItem> items, List<LookupItem> fb) =>
      items.isNotEmpty ? items : fb;

  void _prefill(TaskModel t) {
    _titleController.text = t.title;
    if (t.description?.isNotEmpty ?? false) _descriptionController.text = t.description!;
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
    final r = t.recurrence;
    if (r != null) {
      _intervalController.text = '${r.interval}';
      _endDate = r.endDate;
      switch (t.taskType) {
        case 1:
          _occurrencesPerDay = r.dailyOccurrencesPerDay ?? 1;
          _dueTimes = r.dueTimes.isEmpty
              ? ['10:00:00']
              : List<String>.from(r.dueTimes);
          while (_dueTimes.length < _occurrencesPerDay) {
            _dueTimes.add('10:00:00');
          }
        case 2:
          _daysOfWeek
            ..clear()
            ..addAll(r.daysOfWeek);
          if (_daysOfWeek.isEmpty) _daysOfWeek.add(0);
        case 3:
          _dayOfMonth = r.dayOfMonth ?? 1;
          _monthlyMode = r.monthlyMode ?? 0;
        case 4:
          _dayOfMonth = r.dayOfMonth ?? 1;
          _monthOfYear = r.monthOfYear ?? 1;
      }
    }
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
      final interval = int.tryParse(_intervalController.text.trim()) ?? 0;
      if (interval < 1) {
        CustomToast.showError('الفاصل الزمني يجب أن يكون 1 على الأقل.');
        return;
      }
      switch (_taskType) {
        case 1: // Daily
          if (_dueTimes.length != _occurrencesPerDay) {
            CustomToast.showError(
              'عدد أوقات الاستحقاق يجب أن يساوي مرات التكرار يوميًا.',
            );
            return;
          }
          recurrence = TaskRecurrence(
            recurrenceType: 1,
            interval: interval,
            startDate: _startDate,
            endDate: _endDate,
            dailyOccurrencesPerDay: _occurrencesPerDay,
            dueTimes: List.of(_dueTimes),
          );
        case 2: // Weekly
          if (_daysOfWeek.isEmpty) {
            CustomToast.showError('اختر يومًا واحدًا على الأقل.');
            return;
          }
          recurrence = TaskRecurrence(
            recurrenceType: 2,
            interval: interval,
            startDate: _startDate,
            endDate: _endDate,
            daysOfWeek: _daysOfWeek.toList()..sort(),
          );
        case 3: // Monthly
          recurrence = TaskRecurrence(
            recurrenceType: 3,
            interval: interval,
            startDate: _startDate,
            endDate: _endDate,
            dayOfMonth: _dayOfMonth,
            monthlyMode: _monthlyMode,
          );
        case 4: // Yearly
          recurrence = TaskRecurrence(
            recurrenceType: 4,
            interval: interval,
            startDate: _startDate,
            endDate: _endDate,
            monthOfYear: _monthOfYear,
            dayOfMonth: _dayOfMonth,
          );
      }
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
      CustomToast.showSuccess(_isEdit ? 'تم حفظ التعديلات بنجاح.' : 'تم إنشاء المهمة بنجاح.');
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
    return BlocListener<TaskDetailsCubit, TaskDetailsState>(
      listenWhen: (p, c) =>
          _isEdit &&
          !_formInit &&
          c.status == TaskDetailsStatus.success &&
          c.task != null,
      listener: (context, state) {
        setState(() {
          _prefill(state.task!);
          _formInit = true;
        });
      },
      child: Scaffold(
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
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/tasks'),
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
                  _Card(
                    title: 'بيانات المهمة',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                              ? 'أدخل عنوان المهمة'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'الوصف',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (state.assignableLoading)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Builder(
                            builder: (context) {
                              final items = state.assignableEmployees
                                  .map(
                                    (e) => SearchableDropdownItem<String?>(
                                      value: e.id,
                                      label: e.fullName,
                                    ),
                                  )
                                  .toList();
                              if (_assigneeId != null &&
                                  (_assigneeLabel?.isNotEmpty ?? false) &&
                                  !items.any((e) => e.value == _assigneeId)) {
                                items.insert(
                                  0,
                                  SearchableDropdownItem<String?>(
                                    value: _assigneeId,
                                    label: _assigneeLabel!,
                                  ),
                                );
                              }
                              return SearchableDropdownField<String>(
                                value: _assigneeId,
                                hintText: 'الموظف المسند إليه *',
                                searchHintText: 'ابحث عن موظف',
                                isDense: true,
                                items: items,
                                onChanged: (id) {
                                  if (id == null) return;
                                  setState(() => _assigneeId = id);
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SearchableDropdownField<int>(
                                value: _priority,
                                labelText: 'الأولوية',
                                searchHintText: 'ابحث',
                                isDense: true,
                                items: _fallback(
                                  state.lookups.priorities,
                                  const [
                                    LookupItem(value: 1, name: ''),
                                    LookupItem(value: 2, name: ''),
                                    LookupItem(value: 3, name: ''),
                                  ],
                                )
                                    .map(
                                      (p) =>
                                          SearchableDropdownItem<int?>(
                                            value: p.value,
                                            label: TaskLabels.lookupLabel(
                                              p.name,
                                              TaskLabels.priorityText(
                                                p.value,
                                              ),
                                            ),
                                          ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _priority = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _hoursController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'الساعات المقدرة',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null;
                                  }
                                  final d = double.tryParse(v.trim());
                                  if (d == null || d < 0) {
                                    return 'رقم غير صالح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SearchableDropdownField<int>(
                          value: _taskType,
                          labelText: 'نوع المهمة',
                          searchHintText: 'ابحث',
                          isDense: true,
items: _fallback(
                                state.lookups.taskTypes,
                                List.generate(
                                  5,
                                  (i) => LookupItem(value: i, name: ''),
                                ),
                              )
                                  .map(
                                    (t) => SearchableDropdownItem<int?>(
                                      value: t.value,
                                      label: TaskLabels.lookupLabel(
                                        t.name,
                                        TaskLabels.taskTypeText(t.value),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _taskType = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _DateTimeField(
                          label: 'تاريخ البدء',
                          value: _startDate,
                          onChanged: (d) => setState(() {
                            _startDate = d;
                            if (_dueDate.isBefore(d)) {
                              _dueDate = d.add(const Duration(hours: 8));
                            }
                          }),
                        ),
                        const SizedBox(height: 12),
                        _DateTimeField(
                          label: 'تاريخ الاستحقاق',
                          value: _dueDate,
                          onChanged: (d) => setState(() => _dueDate = d),
                        ),
                      ],
                    ),
                  ),
                  if (_taskType != 0) ...[
                    const SizedBox(height: 12),
                    _Card(
                      title:
                          'التكرار (${TaskLabels.taskTypeText(_taskType)})',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _intervalController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: _taskType == 1
                                        ? 'كل كم يوم'
                                        : _taskType == 2
                                        ? 'كل كم أسبوع'
                                        : _taskType == 3
                                        ? 'كل كم شهر'
                                        : 'كل كم سنة',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    final n = int.tryParse((v ?? '').trim());
                                    if (n == null || n < 1) {
                                      return '1 على الأقل';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DateTimeField(
                                  label: 'ينتهي في (اختياري)',
                                  value: _endDate,
                                  clearable: true,
                                  onChanged: (d) =>
                                      setState(() => _endDate = d),
                                  onClear: () =>
                                      setState(() => _endDate = null),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _recurrenceBody(state),
                        ],
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
                              ? (_isEdit ? 'جاري الحفظ...' : 'جاري الإنشاء...')
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
      ),
    );
  }

  Widget _recurrenceBody(TasksState state) {
    switch (_taskType) {
      case 1: // Daily
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('مرات التكرار يوميًا'),
                const Spacer(),
                IconButton(
                  onPressed: _occurrencesPerDay > 1
                      ? () => setState(() {
                          _occurrencesPerDay--;
                          _dueTimes = _dueTimes
                              .take(_occurrencesPerDay)
                              .toList();
                        })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text(
                  '$_occurrencesPerDay',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: _occurrencesPerDay < 4
                      ? () => setState(() {
                          _occurrencesPerDay++;
                          while (_dueTimes.length < _occurrencesPerDay) {
                            _dueTimes.add('10:00:00');
                          }
                        })
                      : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'أوقات الاستحقاق (HH:mm) بعدد المرات',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _occurrencesPerDay; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TimeField(
                  label: 'الموعد ${i + 1}',
                  value: i < _dueTimes.length ? _dueTimes[i] : '10:00:00',
                  onChanged: (hhmmss) => setState(() {
                    while (_dueTimes.length <= i) {
                      _dueTimes.add('10:00:00');
                    }
                    _dueTimes[i] = hhmmss;
                  }),
                ),
              ),
          ],
        );
      case 2: // Weekly
        final lookups = state.lookups.daysOfWeek;
        final days = lookups.isNotEmpty
            ? lookups.map((e) => e.value).toList()
            : List.generate(7, (i) => i);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أيام الأسبوع'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days.map((d) {
                final selected = _daysOfWeek.contains(d);
                final name = lookups.isNotEmpty
                    ? lookups
                          .firstWhere(
                            (e) => e.value == d,
                            orElse: () => LookupItem(value: d, name: ''),
                          )
                          .name
                    : '';
                return FilterChip(
                  selected: selected,
                  label: Text(
                    TaskLabels.lookupLabel(
                      name,
                      TaskLabels.dayOfWeekText(d),
                    ),
                  ),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _daysOfWeek.add(d);
                    } else {
                      _daysOfWeek.remove(d);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
        );
      case 3: // Monthly
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchableDropdownField<int>(
                    value: _dayOfMonth,
                    labelText: 'يوم الشهر',
                    searchHintText: 'ابحث',
                    isDense: true,
                    items: List.generate(
                      31,
                      (i) => SearchableDropdownItem<int?>(
                        value: i + 1,
                        label: '${i + 1}',
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _dayOfMonth = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SearchableDropdownField<int>(
                    value: _monthlyMode,
                    labelText: 'وضع الشهر',
                    searchHintText: 'ابحث',
                    isDense: true,
                    items: _fallback(
                      state.lookups.monthlyModes,
                      List.generate(
                        5,
                        (i) => LookupItem(value: i, name: ''),
                      ),
                    )
                        .map(
                          (m) => SearchableDropdownItem<int?>(
                            value: m.value,
                            label: TaskLabels.lookupLabel(
                              m.name,
                              TaskLabels.monthlyModeText(m.value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _monthlyMode = v);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      case 4: // Yearly
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchableDropdownField<int>(
                    value: _monthOfYear,
                    labelText: 'الشهر',
                    searchHintText: 'ابحث',
                    isDense: true,
                    items: List.generate(
                      12,
                      (i) => SearchableDropdownItem<int?>(
                        value: i + 1,
                        label: TaskLabels.monthText(i + 1),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _monthOfYear = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SearchableDropdownField<int>(
                    value: _dayOfMonth,
                    labelText: 'اليوم',
                    searchHintText: 'ابحث',
                    isDense: true,
                    items: List.generate(
                      31,
                      (i) => SearchableDropdownItem<int?>(
                        value: i + 1,
                        label: '${i + 1}',
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _dayOfMonth = v);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

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
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool clearable;
  final VoidCallback? onClear;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.clearable = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 5),
          locale: const Locale('ar', 'EG'),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? now),
        );
        if (time == null) return;
        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: clearable && value != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_month_outlined, size: 18),
        ),
        child: Text(
          value == null
              ? 'اختياري'
              : '${TaskLabels.formatDate(value)} — ${TimeOfDay.fromDateTime(value!).format(context)}',
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  String _display() {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 10,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        );
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked == null) return;
        onChanged(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00',
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.schedule_rounded, size: 18),
        ),
        child: Text(_display()),
      ),
    );
  }
}
