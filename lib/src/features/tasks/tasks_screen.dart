import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../shared/widgets/searchable_dropdown_field.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'cubit/tasks_cubit.dart';
import 'cubit/tasks_state.dart';
import 'models/task_filters.dart';
import 'models/task_lookups.dart';
import 'utils/task_labels.dart';
import 'widgets/task_card.dart';

/// Tasks hub:
/// - Super admin: "All tasks" tab + create button only (no one assigns him tasks).
/// - Admin: "My tasks" + "All tasks" tabs + create button.
/// - HR / regular employees: "My tasks" tab only.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showAllTasks = false;

  static const TextStyle _kTitleStyle = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
    fontSize: 17,
  );

  bool get _isSuperAdmin {
    final role = context.read<AuthCubit>().state.role;
    return role == UserRole.superAdmin;
  }

  bool get _isAdmin {
    final role = context.read<AuthCubit>().state.role;
    return role == UserRole.admin;
  }

  bool get _isManager => _isSuperAdmin || _isAdmin;

  /// Whether the currently visible list is the "all tasks" one.
  bool get _isAllTasksTab => _isSuperAdmin || (_isAdmin && _showAllTasks);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<TasksCubit>();
      cubit.loadLookups();
      if (!_isSuperAdmin) cubit.loadMyTasks();
      if (_isManager) {
        cubit.loadTasks();
        cubit.loadAssignableEmployees();
      }
    });
  }

  Future<void> _refresh() async {
    final cubit = context.read<TasksCubit>();
    if (_isAllTasksTab) {
      await cubit.loadTasks(silent: true);
    } else {
      await cubit.loadMyTasks(silent: true);
    }
  }

  Future<void> _openFilters() async {
    final cubit = context.read<TasksCubit>();
    final forAll = _isAllTasksTab;
    final result = await showModalBottomSheet<TaskFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFiltersSheet(
        current: forAll ? cubit.state.filters : cubit.state.myTasksFilters,
        lookups: cubit.state.lookups,
        employees: cubit.state.assignableEmployees,
        showEmployee: forAll,
      ),
    );
    if (result == null || !mounted) return;
    if (forAll) {
      cubit.applyFilters(result);
    } else {
      cubit.applyMyFilters(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = _isManager;
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
              context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: _isSuperAdmin
            ? const Text('كل المهام', style: _kTitleStyle)
            : _isAdmin
            ? SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('مهامي')),
                  ButtonSegment(value: true, label: Text('كل المهام')),
                ],
                selected: {_showAllTasks},
                onSelectionChanged: (s) =>
                    setState(() => _showAllTasks = s.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            : const Text('مهامي', style: _kTitleStyle),
        actions: [
          BlocBuilder<TasksCubit, TasksState>(
            builder: (context, state) {
              final forAll = _isAllTasksTab;
              return _AppBarFilterButton(
                active: forAll
                    ? !state.filters.isEmpty
                    : !state.myTasksFilters.isEmpty,
                enabled:
                    state.lookupsStatus == TasksStatus.success ||
                    (forAll && state.assignableEmployees.isNotEmpty),
                onPressed: () => _openFilters(),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              heroTag: 'tasks_fab',
              backgroundColor: AppColors.primary,
              onPressed: () async {
                final created = await context.push<bool>('/tasks/create');
                if (created == true && context.mounted) {
                  context.read<TasksCubit>().refreshAll();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'مهمة جديدة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      body: _isAllTasksTab
          ? _AllTasksTab(onRefresh: _refresh)
          : _MyTasksTab(onRefresh: _refresh),
    );
  }
}

class _MyTasksTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const _MyTasksTab({required this.onRefresh});

  @override
  State<_MyTasksTab> createState() => _MyTasksTabState();
}

class _MyTasksTabState extends State<_MyTasksTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TasksCubit>().loadMyTasks(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.myTasksStatus == TasksStatus.loading &&
            state.myTasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.myTasksStatus == TasksStatus.failure &&
            state.myTasks.isEmpty) {
          return ErrorStateWidget(
            title: 'تعذر تحميل مهامي',
            error: state.myTasksErrorMessage ?? 'حدث خطأ غير متوقع.',
            buttonLabel: 'إعادة المحاولة',
            onRetry: () => context.read<TasksCubit>().loadMyTasks(),
            icon: Icons.task_outlined,
          );
        }
        return Column(
          children: [
            Container(
              color: AppColors.backgroundSecondary,
              child: _StatusFilterRow(
                selected: state.myTasksFilters.status,
                onChanged: (s) =>
                    context.read<TasksCubit>().setMyStatusFilter(s),
              ),
            ),
            Expanded(
              child: state.myTasks.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.task_outlined,
                      title: 'لا توجد مهام مسندة إليك',
                      message: 'ستظهر هنا المهام المسندة إليك من مديرك.',
                      iconColor: AppColors.textTertiary,
                    )
                  : RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          16 + MediaQuery.of(context).padding.bottom + 80,
                        ),
                        itemCount: state.myTasks.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          if (i >= state.myTasks.length) {
                            return _BottomLoader(
                              loading: state.loadingMoreMyTasks,
                              hasMore: state.hasMoreMyTasks,
                            );
                          }
                          return TaskCard(task: state.myTasks[i]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AllTasksTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const _AllTasksTab({required this.onRefresh});

  @override
  State<_AllTasksTab> createState() => _AllTasksTabState();
}

class _AllTasksTabState extends State<_AllTasksTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TasksCubit>().loadTasks(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state.status == TasksStatus.loading && state.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == TasksStatus.failure && state.tasks.isEmpty) {
          return ErrorStateWidget(
            title: 'تعذر تحميل المهام',
            error: state.errorMessage ?? 'حدث خطأ غير متوقع.',
            buttonLabel: 'إعادة المحاولة',
            onRetry: () => context.read<TasksCubit>().loadTasks(),
            icon: Icons.task_outlined,
          );
        }
        return Column(
          children: [
            Container(
              color: AppColors.backgroundSecondary,
              child: _StatusFilterRow(
                selected: state.filters.status,
                onChanged: (s) => context.read<TasksCubit>().setStatusFilter(s),
              ),
            ),
            Expanded(
              child: state.tasks.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.task_outlined,
                      title: 'لا توجد مهام',
                      message: 'جرّب تغيير الفلتر أو إنشاء مهمة جديدة.',
                      iconColor: AppColors.textTertiary,
                    )
                  : RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          16 + MediaQuery.of(context).padding.bottom + 80,
                        ),
                        itemCount: state.tasks.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          if (i >= state.tasks.length) {
                            return _BottomLoader(
                              loading: state.loadingMoreTasks,
                              hasMore: state.hasMoreTasks,
                            );
                          }
                          return TaskCard(task: state.tasks[i]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomLoader extends StatelessWidget {
  final bool loading;
  final bool hasMore;
  const _BottomLoader({required this.loading, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'لا توجد صفحات أخرى',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

class _AppBarFilterButton extends StatelessWidget {
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  const _AppBarFilterButton({
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: active,
                smallSize: 7,
                child: const Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'فلاتر',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;
  const _StatusFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterChip(
            label: 'الكل',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (var s = 0; s <= 6; s++)
            _FilterChip(
              label: TaskLabels.statusText(s),
              selected: selected == s,
              color: TaskLabels.statusColor(s),
              onTap: () => onChanged(s),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskFiltersSheet extends StatefulWidget {
  final TaskFilters current;
  final TaskLookups lookups;
  final List<AssignableEmployee> employees;
  final bool showEmployee;
  const _TaskFiltersSheet({
    required this.current,
    required this.lookups,
    required this.employees,
    this.showEmployee = true,
  });

  @override
  State<_TaskFiltersSheet> createState() => _TaskFiltersSheetState();
}

class _TaskFiltersSheetState extends State<_TaskFiltersSheet> {
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
            _FilterChip(
              label: 'الكل',
              selected: selected == null,
              onTap: () => onChanged(null),
            ),
            for (final item in source)
              _FilterChip(
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
