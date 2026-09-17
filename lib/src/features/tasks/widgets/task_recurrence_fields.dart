import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_toast.dart';
import '../../../shared/widgets/searchable_dropdown_field.dart';
import '../models/task.dart';
import '../models/task_lookups.dart';
import '../utils/task_labels.dart';
import 'task_date_time_field.dart';

List<LookupItem> _fallback(List<LookupItem> items, List<LookupItem> fb) =>
    items.isNotEmpty ? items : fb;

/// Recurrence builder card (daily / weekly / monthly / yearly). Wraps the
/// interval + optional end-date row and each task-type specific body. The
/// parent reads the final [TaskRecurrence] via
/// `TaskRecurrenceFieldsState.buildRecurrence`.
class TaskRecurrenceFields extends StatefulWidget {
  final int taskType;
  final TaskLookups lookups;
  final TaskRecurrence? initial;

  const TaskRecurrenceFields({
    super.key,
    required this.taskType,
    required this.lookups,
    this.initial,
  });

  @override
  TaskRecurrenceFieldsState createState() => TaskRecurrenceFieldsState();
}

class TaskRecurrenceFieldsState extends State<TaskRecurrenceFields> {
  final _intervalController = TextEditingController(text: '1');
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
    _seed(widget.initial);
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  void _seed(TaskRecurrence? r) {
    if (r == null) return;
    _intervalController.text = '${r.interval}';
    _endDate = r.endDate;
    switch (widget.taskType) {
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

  /// Validates all recurrence fields and builds the [TaskRecurrence] to send,
  /// or returns null (with a toast) when invalid. Call from the parent submit.
  TaskRecurrence? buildRecurrence({required DateTime startDate}) {
    final interval = int.tryParse(_intervalController.text.trim()) ?? 0;
    if (interval < 1) {
      CustomToast.showError('الفاصل الزمني يجب أن يكون 1 على الأقل.');
      return null;
    }
    switch (widget.taskType) {
      case 1: // Daily
        if (_dueTimes.length != _occurrencesPerDay) {
          CustomToast.showError(
            'عدد أوقات الاستحقاق يجب أن يساوي مرات التكرار يوميًا.',
          );
          return null;
        }
        return TaskRecurrence(
          recurrenceType: 1,
          interval: interval,
          startDate: startDate,
          endDate: _endDate,
          dailyOccurrencesPerDay: _occurrencesPerDay,
          dueTimes: List.of(_dueTimes),
        );
      case 2: // Weekly
        if (_daysOfWeek.isEmpty) {
          CustomToast.showError('اختر يومًا واحدًا على الأقل.');
          return null;
        }
        return TaskRecurrence(
          recurrenceType: 2,
          interval: interval,
          startDate: startDate,
          endDate: _endDate,
          daysOfWeek: _daysOfWeek.toList()..sort(),
        );
      case 3: // Monthly
        return TaskRecurrence(
          recurrenceType: 3,
          interval: interval,
          startDate: startDate,
          endDate: _endDate,
          dayOfMonth: _dayOfMonth,
          monthlyMode: _monthlyMode,
        );
      case 4: // Yearly
        return TaskRecurrence(
          recurrenceType: 4,
          interval: interval,
          startDate: startDate,
          endDate: _endDate,
          monthOfYear: _monthOfYear,
          dayOfMonth: _dayOfMonth,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.taskType == 1
                      ? 'كل كم يوم'
                      : widget.taskType == 2
                      ? 'كل كم أسبوع'
                      : widget.taskType == 3
                      ? 'كل كم شهر'
                      : 'كل كم سنة',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 1) return '1 على الأقل';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TaskDateTimeField(
                label: 'ينتهي في (اختياري)',
                value: _endDate,
                clearable: true,
                onChanged: (d) => setState(() => _endDate = d),
                onClear: () => setState(() => _endDate = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _body(),
      ],
    );
  }

  Widget _body() {
    switch (widget.taskType) {
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
                child: TaskTimeField(
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
        final lookups = widget.lookups.daysOfWeek;
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
                    TaskLabels.lookupLabel(name, TaskLabels.dayOfWeekText(d)),
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
        return Row(
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
                items:
                    _fallback(
                          widget.lookups.monthlyModes,
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
        );
      case 4: // Yearly
        return Row(
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
        );
    }
    return const SizedBox.shrink();
  }
}
