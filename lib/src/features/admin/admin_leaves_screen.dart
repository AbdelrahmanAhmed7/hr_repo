import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/skeleton/skeleton_list_item.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import 'cubit/admin_leaves_cubit.dart';
import 'cubit/admin_leaves_state.dart';
import 'models/department_leave.dart';
import 'widgets/admin_dept_list_header.dart';
import 'widgets/department_leave_card.dart';

class AdminLeavesScreen extends StatefulWidget {
  const AdminLeavesScreen({super.key});

  @override
  State<AdminLeavesScreen> createState() => _AdminLeavesScreenState();
}

class _AdminLeavesScreenState extends State<AdminLeavesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    context.read<AdminLeavesCubit>().loadLeaves();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final statuses = [null, 'Pending', 'Approved', 'Rejected'];
    context.read<AdminLeavesCubit>().setStatusFilter(
      statuses[_tabController.index],
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminLeavesCubit>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AdminLeavesCubit>().setSearch(
        value.trim().isEmpty ? null : value.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const AppBackButton(),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocBuilder<AdminLeavesCubit, AdminLeavesState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<AdminLeavesCubit>().loadLeaves(refresh: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: AdminDeptListHeader(
                      title: 'إجازات الموظفين',
                      subtitle: 'إجمالي ${state.allCount} إجازة',
                      icon: Icons.beach_access_rounded,
                      iconBackground: const Color(0xFFF3E8FD),
                      iconColor: const Color(0xFF9C27B0),
                      pendingCount: state.pendingCount,
                      approvedCount: state.approvedCount,
                      rejectedCount: state.rejectedCount,
                      searchController: _searchController,
                      searchHint: 'بحث باسم الموظف...',
                      onSearchChanged: _onSearchChanged,
                      onClearSearch: () =>
                          context.read<AdminLeavesCubit>().setSearch(null),
                      hasActiveFilters:
                          state.dateFromFilter != null ||
                          state.dateToFilter != null,
                      onOpenFilters: () => _showFiltersSheet(context, state),
                    ),
                  ),

                  // ── Pinned segmented tabs ───────────────────────────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StatusTabsSliverDelegate(
                      StatusTabsBar(
                        controller: _tabController,
                        style: StatusTabsStyle.segmented,
                      ),
                    ),
                  ),

                  // ── Content ─────────────────────────────────────────
                  if (state.isLoading && state.items.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 + MediaQuery.of(context).padding.bottom,
                      ),
                      sliver: SliverList.separated(
                        itemCount: 6,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, _) =>
                            const SkeletonListItem(showAvatar: true),
                      ),
                    )
                  else if (state.error != null && state.items.isEmpty)
                    SliverFillRemaining(child: _buildError(state.error!))
                  else if (state.items.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.beach_access_outlined,
                        title: 'لا توجد إجازات',
                        message: 'جرّب تغيير الفلتر أو الفترة الزمنية',
                        iconColor: AppColors.textTertiary,
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverList.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => DepartmentLeaveCard(
                          leave: state.items[index],
                          isUpdating: state.isUpdating,
                          onApprove: () =>
                              _approve(context, state.items[index]),
                          onReject: () => _reject(context, state.items[index]),
                        ),
                      ),
                    ),
                    if (state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 24,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<AdminLeavesCubit>().loadLeaves(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, DepartmentLeave leave) async {
    final ok = await context.read<AdminLeavesCubit>().approveLeave(leave.id);
    if (!context.mounted) return;
    if (ok) {
      CustomToast.showSuccess('تم قبول الإجازة');
    } else {
      CustomToast.showError('فشل قبول الإجازة');
    }
  }

  Future<void> _reject(BuildContext context, DepartmentLeave leave) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('رفض الإجازة'),
          ],
        ),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (اختياري)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AdminLeavesCubit>().rejectLeave(
      leave.id,
      rejectionReason: reasonController.text.trim().isEmpty
          ? null
          : reasonController.text.trim(),
    );
    if (!context.mounted) return;
    if (ok) {
      CustomToast.showSuccess('تم رفض الإجازة');
    } else {
      CustomToast.showError('فشل رفض الإجازة');
    }
  }

  void _showFiltersSheet(BuildContext context, AdminLeavesState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminLeavesCubit>(),
        child: _FiltersSheet(state: state),
      ),
    );
  }
}

// ─── Filters Sheet ────────────────────────────────────────────────────────────

class _FiltersSheet extends StatefulWidget {
  final AdminLeavesState state;
  const _FiltersSheet({required this.state});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _dateFrom;
  late String? _dateTo;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.state.dateFromFilter;
    _dateTo = widget.state.dateToFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Row(
            children: [
              Text(
                'تصفية النتائج',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  context.read<AdminLeavesCubit>().clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('مسح الكل'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'الفترة الزمنية',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'من',
                  value: _dateFrom,
                  onPicked: (v) => setState(() => _dateFrom = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: 'إلى',
                  value: _dateTo,
                  onPicked: (v) => setState(() => _dateTo = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<AdminLeavesCubit>().setDateFilter(
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تطبيق',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onPicked;
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null ? DateTime.parse(value!) : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onPicked(
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onPicked(null),
                child: const Icon(
                  Icons.clear_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
