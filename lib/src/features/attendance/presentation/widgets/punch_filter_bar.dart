import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/searchable_dropdown_field.dart';
import '../cubit/punch_cubit.dart';
import '../cubit/punch_state.dart';

class PunchFilterBar extends StatefulWidget {
  const PunchFilterBar({super.key});

  @override
  State<PunchFilterBar> createState() => _PunchFilterBarState();
}

class _PunchFilterBarState extends State<PunchFilterBar> {
  static const double _sectionPaddingH = 12;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (context, state) {
        String? selectedDeptName;
        if (state.selectedDepartmentId != null) {
          for (final d in state.departments) {
            if (d.id == state.selectedDepartmentId) {
              selectedDeptName = d.name;
              break;
            }
          }
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Row 1 – Date Navigator (RTL correct)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
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
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => _showFilterSheet(context),
                    ),
                    if (!state.isToday)
                      GestureDetector(
                        onTap: () => context.read<PunchCubit>().goToToday(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'اليوم',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: state.isToday
                            ? AppColors.textTertiary
                            : AppColors.textSecondary,
                      ),
                      onPressed: state.isToday
                          ? null
                          : () => context.read<PunchCubit>().goToNextDay(),
                    ),
                    Expanded(
                      child: Text(
                        _formatDisplayDate(state.fromDate, state.toDate),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () =>
                          context.read<PunchCubit>().goToPreviousDay(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Row 2 – Quick date chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sectionPaddingH,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickDateChip(
                        label: 'اليوم',
                        icon: Icons.today_rounded,
                        isActive: _isRange(
                          state,
                          _dateOnly(DateTime.now()),
                          _dateOnly(DateTime.now()),
                        ),
                        onTap: () => context.read<PunchCubit>().goToToday(),
                      ),
                      _QuickDateChip(
                        label: 'أمس',
                        icon: Icons.history_rounded,
                        isActive: _isRange(
                          state,
                          _dateOnly(
                            DateTime.now().subtract(const Duration(days: 1)),
                          ),
                          _dateOnly(
                            DateTime.now().subtract(const Duration(days: 1)),
                          ),
                        ),
                        onTap: () {
                          final d = DateTime.now().subtract(
                            const Duration(days: 1),
                          );
                          context.read<PunchCubit>().applyDateFilter(
                            from: _startOfDay(d),
                            to: _endOfDay(d),
                          );
                        },
                      ),
                      _QuickDateChip(
                        label: 'الأسبوع',
                        icon: Icons.view_week_rounded,
                        isActive: _isRange(
                          state,
                          _weekStart(),
                          _dateOnly(DateTime.now()),
                        ),
                        onTap: () {
                          final now = DateTime.now();
                          context.read<PunchCubit>().applyDateFilter(
                            from: _weekStart(),
                            to: _dateOnly(now),
                          );
                        },
                      ),
                      _QuickDateChip(
                        label: 'الشهر',
                        icon: Icons.calendar_month_rounded,
                        isActive: _isRange(
                          state,
                          _monthStart(),
                          _dateOnly(DateTime.now()),
                        ),
                        onTap: () {
                          final now = DateTime.now();
                          context.read<PunchCubit>().applyDateFilter(
                            from: _monthStart(),
                            to: _dateOnly(now),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Row 3 – Employee + Department dropdowns
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sectionPaddingH,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PunchFilterDropdown<String>(
                            icon: Icons.person_search_rounded,
                            placeholder: 'كل الموظفين',
                            isLoading: state.isLoadingEmployees,
                            selectedLabel: state.selectedEmployeeName,
                            value: state.selectedUserId,
                            labelOf: (id) {
                              if (id == null) return null;
                              for (final o in state.employeeOptions) {
                                if (o.userId == id) return o.name;
                              }
                              return null;
                            },
                            items: [
                              const SearchableDropdownItem<String?>(
                                value: null,
                                label: 'كل الموظفين',
                              ),
                              ...state.employeeOptions.map(
                                (opt) => SearchableDropdownItem<String?>(
                                  value: opt.userId,
                                  label: opt.name,
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
                                  opt?.userId,
                                  opt?.name,
                                );
                              } else {
                                context
                                    .read<PunchCubit>()
                                    .clearEmployeeFilter();
                              }
                            },
                            onClear: state.selectedEmployeeName != null
                                ? () => context
                                      .read<PunchCubit>()
                                      .clearEmployeeFilter()
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _PunchFilterDropdown<int>(
                            icon: Icons.apartment_rounded,
                            placeholder: 'كل الأقسام',
                            isLoading: false,
                            selectedLabel: selectedDeptName,
                            value: state.selectedDepartmentId,
                            labelOf: (id) {
                              if (id == null) return null;
                              for (final d in state.departments) {
                                if (d.id == id) return d.name;
                              }
                              return null;
                            },
                            items: [
                              const SearchableDropdownItem<int?>(
                                value: null,
                                label: 'كل الأقسام',
                              ),
                              ...state.departments.map(
                                (dept) => SearchableDropdownItem<int?>(
                                  value: dept.id,
                                  label: dept.name,
                                ),
                              ),
                            ],
                            onChanged: (id) => context
                                .read<PunchCubit>()
                                .applyDepartmentFilter(id),
                            onClear: state.selectedDepartmentId != null
                                ? () => context
                                      .read<PunchCubit>()
                                      .applyDepartmentFilter(null)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Row 4 – Active filter chips
              if (state.hasActiveFilters) ...[
                const Divider(height: 1, color: AppColors.border),
                Builder(
                  builder: (context) {
                    final dept =
                        state.departments
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
                        horizontal: _sectionPaddingH,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          if (state.showDateChip)
                            _ActiveChip(
                              label:
                                  '${DateFormat('d/M', 'ar').format(state.fromDate)}'
                                  ' — ${DateFormat('d/M', 'ar').format(state.toDate)}',
                              onRemove: () =>
                                  context.read<PunchCubit>().goToToday(),
                            ),
                          if (state.selectedEmployeeName != null) ...[
                            const SizedBox(width: 8),
                            _ActiveChip(
                              label: state.selectedEmployeeName!,
                              onRemove: () => context
                                  .read<PunchCubit>()
                                  .clearEmployeeFilter(),
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
            ],
          ),
        );
      },
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

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
    final isSame =
        from.year == to.year && from.month == to.month && from.day == to.day;
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'تصفية السجلات',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
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
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إعادة تعيين',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            cubit.applyDateFilter(from: tempFrom, to: tempTo);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'تطبيق',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Filter Dropdown Field ──────────────────────────────────────────────────

class _PunchFilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String placeholder;
  final bool isLoading;
  final String? selectedLabel;
  final T? value;
  final List<SearchableDropdownItem<T?>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?) labelOf;
  final VoidCallback? onClear;

  const _PunchFilterDropdown({
    required this.icon,
    required this.placeholder,
    required this.isLoading,
    required this.selectedLabel,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelOf,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedLabel != null;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SearchableDropdownField<T>(
                    value: value,
                    labelText: placeholder,
                    hintText: isLoading ? 'جاري التحميل...' : placeholder,
                    searchHintText: 'بحث',
                    items: items,
                    onChanged: onChanged,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.error,
            ),
          ),
        ],
      ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('d MMM yyyy', 'ar').format(date),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
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
