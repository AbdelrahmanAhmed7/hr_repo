import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/empty_state_widget.dart';
import 'cubit/admin_assignments_cubit.dart';
import 'cubit/admin_assignments_state.dart';
import 'cubit/admin_leaves_cubit.dart';
import 'cubit/admin_leaves_state.dart';
import 'cubit/admin_permissions_cubit.dart';
import 'cubit/admin_permissions_state.dart';
import 'models/admin_dashboard_response.dart';
import 'models/department_assignment.dart';
import 'models/department_leave.dart';
import 'models/department_permission.dart';
import 'widgets/department_assignment_card.dart';
import 'widgets/department_leave_card.dart';
import 'widgets/department_permission_card.dart';

class AdminEmployeeDetailsScreen extends StatelessWidget {
  final AdminEmployee employee;

  const AdminEmployeeDetailsScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AdminPermissionsCubit>()
            ..loadPermissionsForUser(employee.id),
        ),
        BlocProvider(
          create: (_) => getIt<AdminLeavesCubit>()
            ..loadLeavesForUser(employee.id),
        ),
        BlocProvider(
          create: (_) => getIt<AdminAssignmentsCubit>()
            ..loadAssignmentsForUser(employee.id),
        ),
      ],
      child: _EmployeeDetailsContent(employee: employee),
    );
  }
}

class _EmployeeDetailsContent extends StatefulWidget {
  final AdminEmployee employee;
  const _EmployeeDetailsContent({required this.employee});

  @override
  State<_EmployeeDetailsContent> createState() =>
      _EmployeeDetailsContentState();
}

class _EmployeeDetailsContentState extends State<_EmployeeDetailsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: const [
                  Tab(text: 'الأذونات'),
                  Tab(text: 'الإجازات'),
                  Tab(text: 'المأموريات'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PermissionsTab(employee: widget.employee),
            _LeavesTab(employee: widget.employee),
            _AssignmentsTab(employee: widget.employee),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final emp = widget.employee;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              // Back button row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تفاصيل الموظف',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Employee info
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: emp.imageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              emp.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildDefaultAvatar(emp),
                            ),
                          )
                        : _buildDefaultAvatar(emp),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.fullNameAr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emp.jobTitleName ?? 'موظف',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (emp.employmentModeName != null)
                              _InfoBadge(
                                icon: Icons.work_outline_rounded,
                                label: emp.employmentModeName!,
                              ),
                            if (emp.startDate != null)
                              _InfoBadge(
                                icon: Icons.calendar_today_rounded,
                                label: emp.startDate!,
                              ),
                            _InfoBadge(
                              icon: emp.isMale
                                  ? Icons.male_rounded
                                  : Icons.female_rounded,
                              label: emp.isMale ? 'ذكر' : 'أنثى',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(AdminEmployee emp) {
    final initials = _initials(emp.fullNameAr);
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0];
    return '${parts.first[0]}${parts.last[0]}';
  }
}

// ─── Info Badge ───────────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Bar Delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Colors.white, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate old) => true;
}

// ─── Permissions Tab ──────────────────────────────────────────────────────────

class _PermissionsTab extends StatefulWidget {
  final AdminEmployee employee;
  const _PermissionsTab({required this.employee});

  @override
  State<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<_PermissionsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AdminPermissionsCubit, AdminPermissionsState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.items.isEmpty) {
          return _ErrorView(
            error: state.error!,
            onRetry: () => context
                .read<AdminPermissionsCubit>()
                .loadPermissionsForUser(widget.employee.id),
          );
        }
        if (state.items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.exit_to_app_outlined,
            title: 'لا توجد أذونات',
            message: 'لم يقدم هذا الموظف أي طلبات إذن',
            iconColor: AppColors.textTertiary,
          );
        }
        return RefreshIndicator(
          onRefresh: () => context
              .read<AdminPermissionsCubit>()
              .loadPermissionsForUser(widget.employee.id),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification &&
                  n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                context.read<AdminPermissionsCubit>().loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()));
                }
                return DepartmentPermissionCard(
                  permission: state.items[index],
                  isUpdating: state.isUpdating,
                  onApprove: () => _approve(context, state.items[index]),
                  onReject: () => _reject(context, state.items[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _approve(
      BuildContext context, DepartmentPermission permission) async {
    final ok = await context
        .read<AdminPermissionsCubit>()
        .approvePermission(permission.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم قبول الإذن' : 'فشل قبول الإذن'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _reject(
      BuildContext context, DepartmentPermission permission) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('رفض الإذن'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
              hintText: 'سبب الرفض (اختياري)',
              border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AdminPermissionsCubit>().rejectPermission(
          permission.id,
          rejectionReason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم رفض الإذن' : 'فشل رفض الإذن'),
      backgroundColor: AppColors.error,
    ));
  }
}

// ─── Leaves Tab ───────────────────────────────────────────────────────────────

class _LeavesTab extends StatefulWidget {
  final AdminEmployee employee;
  const _LeavesTab({required this.employee});

  @override
  State<_LeavesTab> createState() => _LeavesTabState();
}

class _LeavesTabState extends State<_LeavesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AdminLeavesCubit, AdminLeavesState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.items.isEmpty) {
          return _ErrorView(
            error: state.error!,
            onRetry: () => context
                .read<AdminLeavesCubit>()
                .loadLeavesForUser(widget.employee.id),
          );
        }
        if (state.items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.beach_access_outlined,
            title: 'لا توجد إجازات',
            message: 'لم يقدم هذا الموظف أي طلبات إجازة',
            iconColor: AppColors.textTertiary,
          );
        }
        return RefreshIndicator(
          onRefresh: () => context
              .read<AdminLeavesCubit>()
              .loadLeavesForUser(widget.employee.id),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification &&
                  n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                context.read<AdminLeavesCubit>().loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()));
                }
                return DepartmentLeaveCard(
                  leave: state.items[index],
                  isUpdating: state.isUpdating,
                  onApprove: () => _approve(context, state.items[index]),
                  onReject: () => _reject(context, state.items[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _approve(BuildContext context, DepartmentLeave leave) async {
    final ok =
        await context.read<AdminLeavesCubit>().approveLeave(leave.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم قبول الإجازة' : 'فشل قبول الإجازة'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _reject(BuildContext context, DepartmentLeave leave) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('رفض الإجازة'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
              hintText: 'سبب الرفض (اختياري)',
              border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم رفض الإجازة' : 'فشل رفض الإجازة'),
      backgroundColor: AppColors.error,
    ));
  }
}

// ─── Assignments Tab ──────────────────────────────────────────────────────────

class _AssignmentsTab extends StatefulWidget {
  final AdminEmployee employee;
  const _AssignmentsTab({required this.employee});

  @override
  State<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<_AssignmentsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AdminAssignmentsCubit, AdminAssignmentsState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.items.isEmpty) {
          return _ErrorView(
            error: state.error!,
            onRetry: () => context
                .read<AdminAssignmentsCubit>()
                .loadAssignmentsForUser(widget.employee.id),
          );
        }
        if (state.items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.assignment_outlined,
            title: 'لا توجد مأموريات',
            message: 'لم يقدم هذا الموظف أي طلبات مأمورية',
            iconColor: AppColors.textTertiary,
          );
        }
        return RefreshIndicator(
          onRefresh: () => context
              .read<AdminAssignmentsCubit>()
              .loadAssignmentsForUser(widget.employee.id),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification &&
                  n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                context.read<AdminAssignmentsCubit>().loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()));
                }
                return DepartmentAssignmentCard(
                  assignment: state.items[index],
                  isUpdating: state.isUpdating,
                  onApprove: () => _approve(context, state.items[index]),
                  onReject: () => _reject(context, state.items[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _approve(
      BuildContext context, DepartmentAssignment assignment) async {
    final ok = await context
        .read<AdminAssignmentsCubit>()
        .approveAssignment(assignment.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم قبول المأمورية' : 'فشل قبول المأمورية'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _reject(
      BuildContext context, DepartmentAssignment assignment) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('رفض المأمورية'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
              hintText: 'سبب الرفض (اختياري)',
              border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AdminAssignmentsCubit>().rejectAssignment(
          assignment.id,
          rejectionReason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم رفض المأمورية' : 'فشل رفض المأمورية'),
      backgroundColor: AppColors.error,
    ));
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
