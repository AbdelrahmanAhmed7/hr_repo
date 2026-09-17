import 'package:flutter/material.dart';

import '../models/task_lookups.dart';
import '../utils/task_labels.dart';
import '../../../shared/widgets/searchable_dropdown_field.dart';
import 'task_date_time_field.dart';

List<LookupItem> _fallback(List<LookupItem> items, List<LookupItem> fb) =>
    items.isNotEmpty ? items : fb;

/// "بيانات المهمة" card: title, description, assignee, priority, hours,
/// task type + date fields. Reused by create & edit; the parent owns the
/// controllers/values and passes them in.
class TaskBasicInfoFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController hoursController;
  final String? assigneeId;
  final String? assigneeLabel;
  final bool assignableLoading;
  final List<AssignableEmployee> assignableEmployees;
  final TaskLookups lookups;
  final int priority;
  final ValueChanged<int> onPriorityChanged;
  final int taskType;
  final ValueChanged<int> onTaskTypeChanged;
  final DateTime startDate;
  final DateTime dueDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onDueDateChanged;
  final ValueChanged<String> onAssigneeChanged;

  const TaskBasicInfoFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.hoursController,
    required this.assigneeId,
    required this.assigneeLabel,
    required this.assignableLoading,
    required this.assignableEmployees,
    required this.lookups,
    required this.priority,
    required this.onPriorityChanged,
    required this.taskType,
    required this.onTaskTypeChanged,
    required this.startDate,
    required this.dueDate,
    required this.onStartDateChanged,
    required this.onDueDateChanged,
    required this.onAssigneeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'العنوان *',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'أدخل عنوان المهمة' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'الوصف',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (assignableLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Builder(
            builder: (context) {
              final items = assignableEmployees
                  .map(
                    (e) => SearchableDropdownItem<String?>(
                      value: e.id,
                      label: e.fullName,
                    ),
                  )
                  .toList();
              if (assigneeId != null &&
                  (assigneeLabel?.isNotEmpty ?? false) &&
                  !items.any((e) => e.value == assigneeId)) {
                items.insert(
                  0,
                  SearchableDropdownItem<String?>(
                    value: assigneeId,
                    label: assigneeLabel!,
                  ),
                );
              }
              return SearchableDropdownField<String>(
                value: assigneeId,
                hintText: 'الموظف المسند إليه *',
                searchHintText: 'ابحث عن موظف',
                isDense: true,
                items: items,
                onChanged: (id) {
                  if (id == null) return;
                  onAssigneeChanged(id);
                },
              );
            },
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SearchableDropdownField<int>(
                value: priority,
                labelText: 'الأولوية',
                searchHintText: 'ابحث',
                isDense: true,
                items:
                    _fallback(lookups.priorities, const [
                          LookupItem(value: 1, name: ''),
                          LookupItem(value: 2, name: ''),
                          LookupItem(value: 3, name: ''),
                        ])
                        .map(
                          (p) => SearchableDropdownItem<int?>(
                            value: p.value,
                            label: TaskLabels.lookupLabel(
                              p.name,
                              TaskLabels.priorityText(p.value),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onPriorityChanged(v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'الساعات المقدرة',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final d = double.tryParse(v.trim());
                  if (d == null || d < 0) return 'رقم غير صالح';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SearchableDropdownField<int>(
          value: taskType,
          labelText: 'نوع المهمة',
          searchHintText: 'ابحث',
          isDense: true,
          items:
              _fallback(
                    lookups.taskTypes,
                    List.generate(5, (i) => LookupItem(value: i, name: '')),
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
            onTaskTypeChanged(v);
          },
        ),
        const SizedBox(height: 12),
        TaskDateTimeField(
          label: 'تاريخ البدء',
          value: startDate,
          onChanged: onStartDateChanged,
        ),
        const SizedBox(height: 12),
        TaskDateTimeField(
          label: 'تاريخ الاستحقاق',
          value: dueDate,
          onChanged: onDueDateChanged,
        ),
      ],
    );
  }
}
