import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../cubit/punch_cubit.dart';
import '../cubit/punch_state.dart';

class PunchFilterBar extends StatefulWidget {
  const PunchFilterBar({super.key});

  @override
  State<PunchFilterBar> createState() => _PunchFilterBarState();
}

class _PunchFilterBarState extends State<PunchFilterBar> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final dividerColor = theme.dividerColor;

        return Column(
          children: [
            // Row 1 – Date Navigator (RTL correct)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: dividerColor)),
              ),
              child: Row(
                children: [
                  // Filter icon (leftmost in RTL)
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.tune_rounded),
                        if (state.hasActiveFilters)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => _showFilterSheet(context),
                  ),
                  // Today chip
                  if (!state.isToday)
                    GestureDetector(
                      onTap: () => context.read<PunchCubit>().goToToday(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'اليوم',
                          style: TextStyle(fontSize: 11, color: primary),
                        ),
                      ),
                    ),
                  // Previous day = chevron_right (RTL: right arrow goes back)
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () =>
                        context.read<PunchCubit>().goToPreviousDay(),
                  ),
                  // Date label
                  Expanded(
                    child: Text(
                      _formatDisplayDate(state.fromDate, state.toDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  // Next day = chevron_left (RTL: left arrow goes forward)
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: state.isToday ? theme.disabledColor : null,
                    ),
                    onPressed: state.isToday
                        ? null
                        : () => context.read<PunchCubit>().goToNextDay(),
                  ),
                ],
              ),
            ),

            // Row 2 – Quick date chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: dividerColor)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickDateChip(
                      label: 'اليوم',
                      icon: Icons.today_rounded,
                      isActive: _isRange(state, _dateOnly(DateTime.now()),
                          _dateOnly(DateTime.now())),
                      onTap: () => context.read<PunchCubit>().goToToday(),
                    ),
                    _QuickDateChip(
                      label: 'أمس',
                      icon: Icons.history_rounded,
                      isActive: _isRange(
                          state,
                          _dateOnly(DateTime.now().subtract(
                              const Duration(days: 1))),
                          _dateOnly(DateTime.now().subtract(
                              const Duration(days: 1)))),
                      onTap: () {
                        final d = DateTime.now().subtract(const Duration(days: 1));
                        context
                            .read<PunchCubit>()
                            .applyDateFilter(from: _startOfDay(d), to: _endOfDay(d));
                      },
                    ),
                    _QuickDateChip(
                      label: 'الأسبوع',
                      icon: Icons.view_week_rounded,
                      isActive: _isRange(state, _weekStart(), _dateOnly(DateTime.now())),
                      onTap: () {
                        final now = DateTime.now();
                        context
                            .read<PunchCubit>()
                            .applyDateFilter(from: _weekStart(), to: _dateOnly(now));
                      },
                    ),
                    _QuickDateChip(
                      label: 'الشهر',
                      icon: Icons.calendar_month_rounded,
                      isActive: _isRange(
                          state, _monthStart(), _dateOnly(DateTime.now())),
                      onTap: () {
                        final now = DateTime.now();
                        context
                            .read<PunchCubit>()
                            .applyDateFilter(from: _monthStart(), to: _dateOnly(now));
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Row 3 – Employee + Department dropdowns
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: dividerColor)),
              ),
              child: Column(
                children: [
                  // Employee dropdown
                  Row(
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 18,
                        color: state.selectedEmployeeName != null
                            ? primary
                            : theme.hintColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: state.selectedUserId,
                            isExpanded: true,
                            isDense: true,
                            hint: Text(
                              state.isLoadingEmployees
                                  ? 'جاري تحميل الموظفين...'
                                  : 'كل الموظفين',
                              style: TextStyle(
                                  fontSize: 13, color: theme.hintColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('كل الموظفين',
                                    style: TextStyle(fontSize: 13)),
                              ),
                              ...state.employeeOptions.map(
                                (opt) => DropdownMenuItem<String?>(
                                  value: opt.userId,
                                  child: Text(opt.name,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: (id) {
                              EmployeeOption? opt;
                              for (final o in state.employeeOptions) {
                                if (o.userId == id) {
                                  opt = o;
                                  break;
                                }
                              }
                              if (id != null) {
                                context.read<PunchCubit>().selectEmployee(
                                    opt?.userId, opt?.name);
                              } else {
                                context
                                    .read<PunchCubit>()
                                    .clearEmployeeFilter();
                              }
                            },
                          ),
                        ),
                      ),
                      if (state.selectedEmployeeName != null)
                        GestureDetector(
                          onTap: () => context
                              .read<PunchCubit>()
                              .clearEmployeeFilter(),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Department dropdown
                  Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 18,
                        color: state.selectedDepartmentId != null
                            ? primary
                            : theme.hintColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: state.selectedDepartmentId,
                            isExpanded: true,
                            isDense: true,
                            hint: const Text('كل الأقسام',
                                style: TextStyle(fontSize: 13)),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('كل الأقسام',
                                    style: TextStyle(fontSize: 13)),
                              ),
                              ...state.departments.map(
                                (dept) => DropdownMenuItem<int?>(
                                  value: dept.id,
                                  child: Text(dept.name,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: (id) =>
                                context
                                    .read<PunchCubit>()
                                    .applyDepartmentFilter(id),
                          ),
                        ),
                      ),
                      if (state.selectedDepartmentId != null)
                        GestureDetector(
                          onTap: () => context
                              .read<PunchCubit>()
                              .applyDepartmentFilter(null),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Row 4 – Active filter chips
            if (state.hasActiveFilters)
              Builder(
                builder: (context) {
                  final dept = state.departments
                      .where((d) => d.id == state.selectedDepartmentId)
                      .toList()
                      .isEmpty
                      ? null
                      : state.departments
                          .where((d) => d.id == state.selectedDepartmentId)
                          .first;
                  final deptName = state.selectedDepartmentId != null
                      ? dept?.name ?? 'القسم'
                      : null;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        if (state.showDateChip)
                          _ActiveChip(
                            label: '${DateFormat('d/M', 'ar').format(state.fromDate)}'
                                ' — ${DateFormat('d/M', 'ar').format(state.toDate)}',
                            onRemove: () =>
                                context.read<PunchCubit>().goToToday(),
                          ),
                        if (state.selectedEmployeeName != null) ...[
                          const SizedBox(width: 8),
                          _ActiveChip(
                            label: state.selectedEmployeeName!,
                            onRemove: () =>
                                context.read<PunchCubit>().clearEmployeeFilter(),
                          ),
                        ],
                        if (deptName != null) ...[
                          const SizedBox(width: 8),
                          _ActiveChip(
                            label: deptName,
                            onRemove: () => context
                                .read<PunchCubit>()
                                .applyDepartmentFilter(null),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  DateTime _weekStart() {
    final now = DateTime.now();
    final today = _dateOnly(now);
    return today.subtract(Duration(days: today.weekday - DateTime.monday));
  }

  DateTime _monthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  bool _isRange(PunchState state, DateTime from, DateTime to) {
    final f = _dateOnly(state.fromDate);
    final t = _dateOnly(state.toDate);
    return f == from && t == to;
  }

  String _formatDisplayDate(DateTime from, DateTime to) {
    final isSame = from.year == to.year &&
        from.month == to.month &&
        from.day == to.day;
    if (isSame) {
      return DateFormat('EEEE، d MMMM yyyy', 'ar').format(from);
    }
    return '${DateFormat('d MMM', 'ar').format(from)} — ${DateFormat('d MMM yyyy', 'ar').format(to)}';
  }

  void _showFilterSheet(BuildContext context) {
    final cubit = context.read<PunchCubit>();
    DateTime tempFrom = cubit.state.fromDate;
    DateTime tempTo = cubit.state.toDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تصفية السجلات',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerButton(
                          label: 'من',
                          date: tempFrom,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: tempFrom,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              locale: const Locale('ar'),
                            );
                            if (d != null) setSheetState(() => tempFrom = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerButton(
                          label: 'إلى',
                          date: tempTo,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: tempTo,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              locale: const Locale('ar'),
                            );
                            if (d != null) setSheetState(() => tempTo = d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            cubit.clearFilters();
                            Navigator.pop(ctx);
                          },
                          child: const Text('إعادة تعيين'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            cubit.applyDateFilter(
                                from: tempFrom, to: tempTo);
                            Navigator.pop(ctx);
                          },
                          child: const Text('تطبيق'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Quick Date Chip ────────────────────────────────────────────────────────

class _QuickDateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? primary.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: isActive ? primary : Theme.of(context).hintColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? primary : Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Filter Chip ─────────────────────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: primary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: primary),
          ),
        ],
      ),
    );
  }
}

// ─── Date Picker Button ──────────────────────────────────────────────────────

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: theme.hintColor),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('d MMM yyyy', 'ar').format(date),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}