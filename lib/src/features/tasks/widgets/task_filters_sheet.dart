import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/searchable_dropdown_field.dart';
import '../models/task_filters.dart';
import '../models/task_lookups.dart';
import '../utils/task_labels.dart';
import 'task_chips.dart';

/// Bottom sheet with all task filters (priority, type, employee, date ranges).
class TaskFiltersSheet extends StatefulWidget {
  final TaskFilters current;
  final TaskLookups lookups;
  final List<AssignableEmployee> employees;
  final bool showEmployee;

  const TaskFiltersSheet({
    super.key,
    required this.current,
    required this.lookups,
    required this.employees,
    this.showEmployee = true,
  });

  @override
  State<TaskFiltersSheet> createState() => _TaskFiltersSheetState();
}

class _TaskFiltersSheetState extends State<TaskFiltersSheet> {
  late TaskFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.current;
  }

  void _apply() => Navigator.of(context).pop(_filters);

  void _clear() => setState(() => _filters = const TaskFilters());

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'فلاتر المهام',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'إغلاق',
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LookupChips(
                            title: 'الأولوية',
                            items: widget.lookups.priorities,
                            selected: _filters.priority,
                            fallbackLabel: (item) =>
                                TaskLabels.priorityText(item.value),
                            onChanged: (v) => setState(() {
                              _filters = _filters.copyWith(priority: v);
                            }),
                          ),
                          _LookupChips(
                            title: 'نوع المهمة',
                            items: widget.lookups.taskTypes,
                            selected: _filters.taskType,
                            fallbackLabel: (item) =>
                                TaskLabels.taskTypeText(item.value),
                            onChanged: (v) => setState(() {
                              _filters = _filters.copyWith(taskType: v);
                            }),
                          ),
                          if (widget.showEmployee &&
                              widget.employees.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'الموظف',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SearchableDropdownField<String>(
                              value: _filters.employeeId,
                              hintText: 'كل الموظفين',
                              searchHintText: 'ابحث عن موظف',
                              isDense: true,
                              items: widget.employees
                                  .map(
                                    (e) => SearchableDropdownItem<String?>(
                                      value: e.id,
                                      label: e.fullName,
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) => setState(() {
                                _filters = _filters.copyWith(employeeId: id);
                              }),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _DateRangeTile(
                            title: 'تاريخ البدء',
                            from: _filters.startDateFrom,
                            to: _filters.startDateTo,
                            onFrom: (d) => setState(() {
                              _filters = _filters.copyWith(startDateFrom: d);
                            }),
                            onTo: (d) => setState(() {
                              _filters = _filters.copyWith(startDateTo: d);
                            }),
                          ),
                          const SizedBox(height: 12),
                          _DateRangeTile(
                            title: 'تاريخ الاستحقاق',
                            from: _filters.dueDateFrom,
                            to: _filters.dueDateTo,
                            onFrom: (d) => setState(() {
                              _filters = _filters.copyWith(dueDateFrom: d);
                            }),
                            onTo: (d) => setState(() {
                              _filters = _filters.copyWith(dueDateTo: d);
                            }),
                          ),
                          const SizedBox(height: 12),
                          _DateRangeTile(
                            title: 'تاريخ الإنشاء',
                            from: _filters.createdDateFrom,
                            to: _filters.createdDateTo,
                            onFrom: (d) => setState(() {
                              _filters = _filters.copyWith(createdDateFrom: d);
                            }),
                            onTo: (d) => setState(() {
                              _filters = _filters.copyWith(createdDateTo: d);
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clear,
                            child: const Text('مسح الكل'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _apply,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('تطبيق الفلاتر'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LookupChips extends StatelessWidget {
  final String title;
  final List<LookupItem> items;
  final int? selected;
  final String Function(LookupItem item) fallbackLabel;
  final ValueChanged<int?> onChanged;

  const _LookupChips({
    required this.title,
    required this.items,
    required this.selected,
    required this.fallbackLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final source = items.isNotEmpty
        ? items
        : List.generate(2, (i) => LookupItem(value: i, name: ''));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TaskFilterChip(
              label: 'الكل',
              selected: selected == null,
              onTap: () => onChanged(null),
            ),
            for (final item in source)
              TaskFilterChip(
                label: TaskLabels.lookupLabel(item.name, fallbackLabel(item)),
                selected: selected == item.value,
                onTap: () => onChanged(item.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _DateRangeTile extends StatelessWidget {
  final String title;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<DateTime?> onFrom;
  final ValueChanged<DateTime?> onTo;

  const _DateRangeTile({
    required this.title,
    required this.from,
    required this.to,
    required this.onFrom,
    required this.onTo,
  });

  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final current = isFrom ? from : to;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar', 'EG'),
    );
    if (picked == null) return;
    if (isFrom) {
      onFrom(picked);
    } else {
      onTo(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String label, DateTime? value, bool isFrom) {
      return Expanded(
        child: InkWell(
          onTap: () => _pick(context, isFrom: isFrom),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: value == null
                  ? const Icon(Icons.calendar_month_outlined, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => isFrom ? onFrom(null) : onTo(null),
                    ),
            ),
            child: Text(
              TaskLabels.formatDate(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            field('من', from, true),
            const SizedBox(width: 8),
            field('إلى', to, false),
          ],
        ),
      ],
    );
  }
}
