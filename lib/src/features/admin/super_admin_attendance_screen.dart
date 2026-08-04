import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'cubit/super_admin_dashboard_cubit.dart';
import 'cubit/super_admin_dashboard_state.dart';
import 'models/super_admin_dashboard_response.dart';

class SuperAdminAttendanceScreen extends StatelessWidget {
  const SuperAdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AttendanceContent();
  }
}

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuperAdminDashboardCubit, SuperAdminDashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<SuperAdminDashboardCubit>().refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildHeader(state),
                ),

                // ── Content ─────────────────────────────────────────────
                if (state.isLoading && state.data == null)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null && state.data == null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            state.error!.replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context
                                .read<SuperAdminDashboardCubit>()
                                .loadDashboard(),
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
                  )
                else if (state.data != null) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList.separated(
                      itemCount: state.data!.departments.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _DepartmentAttendanceCard(
                        department: state.data!.departments[i],
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SuperAdminDashboardState state) {
    final data = state.data;
    final present = data?.presentToday ?? 0;
    final total = data?.totalEmployees ?? 0;
    final absent = total - present;
    final pct = total > 0 ? (present / total * 100).round() : 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.how_to_reg_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الحضور اليوم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'إجمالي $total موظف',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  _StatCard(
                    label: 'حاضر',
                    count: present,
                    color: Colors.greenAccent,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'غائب',
                    count: absent,
                    color: Colors.redAccent,
                    icon: Icons.cancel_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'نسبة الحضور',
                    count: pct,
                    suffix: '%',
                    color: Colors.white,
                    icon: Icons.pie_chart_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Department Attendance Card ───────────────────────────────────────────────

class _DepartmentAttendanceCard extends StatefulWidget {
  final SuperAdminDepartmentData department;
  const _DepartmentAttendanceCard({required this.department});

  @override
  State<_DepartmentAttendanceCard> createState() =>
      _DepartmentAttendanceCardState();
}

class _DepartmentAttendanceCardState
    extends State<_DepartmentAttendanceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dept = widget.department;
    final present = dept.presentToday;
    final total = dept.employees.length;
    final absent = total - present;
    final pct = total > 0 ? (present / total * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          InkWell(
            onTap: total > 0
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Progress circle
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: total > 0 ? present / total : 0,
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.success),
                          strokeWidth: 4,
                        ),
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.departmentName,
                          style: AppTextStyles.titleSmall
                              .copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MiniChip(
                                label: '$present حاضر',
                                color: AppColors.success),
                            const SizedBox(width: 6),
                            _MiniChip(
                                label: '$absent غائب',
                                color: AppColors.error),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (total > 0)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
            ),
          ),

          // ── Expanded employees list ──────────────────────────────────
          if (_expanded && total > 0) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              itemCount: dept.employees.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final emp = dept.employees[i];
                final name = emp.shortNameAr;
                return _EmployeeAttendanceRow(employee: emp, name: name);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Employee Attendance Row ──────────────────────────────────────────────────

class _EmployeeAttendanceRow extends StatelessWidget {
  final SuperAdminDeptEmployee employee;
  final String name;
  const _EmployeeAttendanceRow(
      {required this.employee, required this.name});

  @override
  Widget build(BuildContext context) {
    final isPresent = employee.isPresent;

    return Row(
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPresent
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.08),
          ),
          child: employee.imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    employee.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        _initials(name, isPresent),
                  ),
                )
              : _initials(name, isPresent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Status
        if (isPresent)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login_rounded,
                  size: 13, color: AppColors.success),
              const SizedBox(width: 3),
              Text(
                _fmt(employee.todayAttendanceTime!),
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.success),
              ),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_rounded,
                  size: 13, color: AppColors.error),
              const SizedBox(width: 3),
              Text(
                'غائب',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.error),
              ),
            ],
          ),
      ],
    );
  }

  Widget _initials(String name, bool isPresent) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final text = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts[0][0]
            : '${parts.first[0]}${parts.last[0]}';
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isPresent ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  String _fmt(String time) {
    final p = time.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : time;
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final String suffix;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              '$count$suffix',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
