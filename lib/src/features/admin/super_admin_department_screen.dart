import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/empty_state_widget.dart';
import 'super_admin_employee_details_screen.dart';
import 'super_admin_request_details_screen.dart';
import 'models/super_admin_dashboard_response.dart';

class SuperAdminDepartmentScreen extends StatefulWidget {
  final SuperAdminDepartmentData department;

  const SuperAdminDepartmentScreen({super.key, required this.department});

  @override
  State<SuperAdminDepartmentScreen> createState() =>
      _SuperAdminDepartmentScreenState();
}

class _SuperAdminDepartmentScreenState
    extends State<SuperAdminDepartmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.department;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader(dept)),
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
                tabs: [
                  Tab(text: 'الموظفون (${dept.employees.length})'),
                  Tab(text: 'الطلبات (${dept.requests.length})'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _EmployeesTab(department: dept),
            _RequestsTab(department: dept),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SuperAdminDepartmentData dept) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + title
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
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.departmentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${dept.employees.length} موظف',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatChip(
                      label: 'الموظفون',
                      count: dept.employees.length,
                      color: Colors.white),
                  _StatChip(
                      label: 'حضور اليوم',
                      count: dept.presentToday,
                      color: Colors.greenAccent),
                  _StatChip(
                      label: 'الطلبات',
                      count: dept.requests.length,
                      color: Colors.white),
                  if (dept.pendingRequestsCount > 0)
                    _StatChip(
                        label: 'معلقة',
                        count: dept.pendingRequestsCount,
                        color: Colors.orangeAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Employees Tab ────────────────────────────────────────────────────────────

class _EmployeesTab extends StatelessWidget {
  final SuperAdminDepartmentData department;
  const _EmployeesTab({required this.department});

  @override
  Widget build(BuildContext context) {
    final employees = department.employees;

    if (employees.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'لا يوجد موظفون',
        message: 'لا يوجد موظفون في هذا القسم',
        iconColor: AppColors.textTertiary,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
      itemCount: employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final emp = employees[i];
        final name = emp.shortNameAr;
        return _EmployeeCard(
          employee: emp,
          name: name,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SuperAdminEmployeeDetailsScreen(
                employee: emp,
                department: department,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final SuperAdminDeptEmployee employee;
  final String name;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            // Avatar with image or initials
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTint,
              ),
              child: employee.imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        employee.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            _initials(name),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _initials(name),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        employee.isPresent
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 13,
                        color: employee.isPresent
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        employee.isPresent
                            ? 'حاضر - ${_fmt(employee.todayAttendanceTime!)}'
                            : 'غائب',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: employee.isPresent
                              ? AppColors.success
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (employee.managerName != null &&
                      employee.managerName!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.supervisor_account_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            employee.managerName!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
          ],
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

  String _fmt(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }
}

// ─── Requests Tab ─────────────────────────────────────────────────────────────

class _RequestsTab extends StatefulWidget {
  final SuperAdminDepartmentData department;
  const _RequestsTab({required this.department});

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  String? _statusFilter; // null = all

  List<SuperAdminRequest> get _filtered {
    if (_statusFilter == null) return widget.department.requests;
    return widget.department.requests
        .where((r) => r.status.toLowerCase() == _statusFilter!.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final requests = widget.department.requests;

    if (requests.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'لا توجد طلبات',
        message: 'لا توجد طلبات في هذا القسم',
        iconColor: AppColors.textTertiary,
      );
    }

    return Column(
      children: [
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(null, 'الكل', requests.length),
                const SizedBox(width: 8),
                _buildChip('Pending', 'معلقة',
                    requests.where((r) => r.isPending).length,
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _buildChip('Approved', 'مقبولة',
                    requests.where((r) => r.isApproved).length,
                    color: AppColors.success),
                const SizedBox(width: 8),
                _buildChip('Rejected', 'مرفوضة',
                    requests.where((r) => r.isRejected).length,
                    color: AppColors.error),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.filter_list_off_rounded,
                  title: 'لا توجد نتائج',
                  message: 'جرّب تغيير الفلتر',
                  iconColor: AppColors.textTertiary,
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, MediaQuery.of(context).padding.bottom + 24),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _RequestCard(
                    request: _filtered[i],
                    department: widget.department,
                    onTap: () {
                      final r = _filtered[i];
                      final emp = r.userId != null
                          ? widget.department.employeeMap[r.userId]
                          : null;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SuperAdminRequestDetailsScreen(
                            request: r,
                            employee: emp,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChip(String? value, String label, int count,
      {Color? color}) {
    final selected = _statusFilter == value;
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? chipColor : AppColors.border, width: 1.5),
        ),
        child: Text(
          '$label $count',
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

}

class _RequestCard extends StatelessWidget {
  final SuperAdminRequest request;
  final SuperAdminDepartmentData department;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.department,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _typeInfo(request.type);
    final statusInfo = _statusInfo(request.status);

    // Lookup employee from department map (preferred) or fall back to request name
    final emp = request.userId != null
        ? department.employeeMap[request.userId]
        : null;
    final displayName = emp?.shortNameAr ?? request.shortNameAr;
    final imageUrl = emp?.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: avatar + name + type + status ──
            Row(
              children: [
                // Employee avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryTint,
                  ),
                  child: imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                _buildInitials(displayName),
                          ),
                        )
                      : _buildInitials(displayName),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Type badge
                      Row(
                        children: [
                          Icon(typeInfo.$1, color: typeInfo.$2, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            typeInfo.$3,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: typeInfo.$2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.$1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusInfo.$1.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusInfo.$2,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: statusInfo.$1,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            // ── Reason ──
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.reason!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts[0][0]
            : '${parts.first[0]}${parts.last[0]}';
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  (IconData, Color, String) _typeInfo(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return (Icons.beach_access_rounded, const Color(0xFF9C27B0), 'إجازة');
      case 'permission':
        return (Icons.exit_to_app_rounded, AppColors.primary, 'إذن خروج');
      case 'overtime':
        return (Icons.more_time_rounded, AppColors.warning, 'عمل إضافي');
      case 'assignment':
        return (Icons.assignment_rounded, const Color(0xFFFF9800), 'مأمورية');
      default:
        return (Icons.help_outline_rounded, AppColors.textSecondary, type);
    }
  }

  (Color, String) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return (AppColors.success, 'مقبول');
      case 'rejected':
        return (AppColors.error, 'مرفوض');
      default:
        return (AppColors.warning, 'معلق');
    }
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Colors.white, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate old) => true;
}
