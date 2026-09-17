import 'package:flutter/material.dart';

import '../utils/task_labels.dart';

/// Label + date/time picker field (date then time).
class TaskDateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool clearable;
  final VoidCallback? onClear;

  const TaskDateTimeField({
    super.key,
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

/// Time-only picker field storing a "HH:mm:ss" string.
class TaskTimeField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const TaskTimeField({
    super.key,
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
