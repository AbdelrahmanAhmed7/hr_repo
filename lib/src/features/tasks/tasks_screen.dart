import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'cubit/tasks_cubit.dart';
import 'cubit/tasks_state.dart';
import 'models/task_filters.dart';
import 'widgets/task_filters_sheet.dart';
import 'widgets/task_list_view.dart';

/// Tasks hub:
/// - Super admin: "All tasks" only + create button (no one assigns him tasks).
/// - Admin: "My tasks" + "All tasks" toggle + create button.
/// - HR / regular employees: "My tasks" only.
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
      builder: (_) => TaskFiltersSheet(
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

class _MyTasksTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _MyTasksTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final cubit = context.read<TasksCubit>();
        return TaskListView(
          items: state.myTasks,
          initialLoading:
              state.myTasksStatus == TasksStatus.loading &&
              state.myTasks.isEmpty,
          initialFailed:
              state.myTasksStatus == TasksStatus.failure &&
              state.myTasks.isEmpty,
          errorTitle: 'تعذر تحميل مهامي',
          errorMessage: state.myTasksErrorMessage ?? 'حدث خطأ غير متوقع.',
          onRetry: () => cubit.loadMyTasks(),
          selectedStatus: state.myTasksFilters.status,
          onStatusChanged: (s) => cubit.setMyStatusFilter(s),
          loadingMore: state.loadingMoreMyTasks,
          hasMore: state.hasMoreMyTasks,
          onRefresh: onRefresh,
          onLoadMore: () => cubit.loadMyTasks(loadMore: true),
          emptyWidget: const EmptyStateWidget(
            icon: Icons.task_outlined,
            title: 'لا توجد مهام مسندة إليك',
            message: 'ستظهر هنا المهام المسندة إليك من مديرك.',
            iconColor: AppColors.textTertiary,
          ),
        );
      },
    );
  }
}

class _AllTasksTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _AllTasksTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final cubit = context.read<TasksCubit>();
        return TaskListView(
          items: state.tasks,
          initialLoading:
              state.status == TasksStatus.loading && state.tasks.isEmpty,
          initialFailed:
              state.status == TasksStatus.failure && state.tasks.isEmpty,
          errorTitle: 'تعذر تحميل المهام',
          errorMessage: state.errorMessage ?? 'حدث خطأ غير متوقع.',
          onRetry: () => cubit.loadTasks(),
          selectedStatus: state.filters.status,
          onStatusChanged: (s) => cubit.setStatusFilter(s),
          loadingMore: state.loadingMoreTasks,
          hasMore: state.hasMoreTasks,
          onRefresh: onRefresh,
          onLoadMore: () => cubit.loadTasks(loadMore: true),
          emptyWidget: const EmptyStateWidget(
            icon: Icons.task_outlined,
            title: 'لا توجد مهام',
            message: 'جرّب تغيير الفلتر أو إنشاء مهمة جديدة.',
            iconColor: AppColors.textTertiary,
          ),
        );
      },
    );
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
