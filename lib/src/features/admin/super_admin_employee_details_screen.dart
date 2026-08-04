import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/empty_state_widget.dart';
import 'super_admin_request_details_screen.dart';
import 'models/super_admin_dashboard_response.dart';

class SuperAdminEmployeeDetailsScreen extends StatefulWidget {
  final SuperAdminDeptEmployee employee;
  final SuperAdminDepartmentData department;

  const SuperAdminEmployeeDetailsScreen({
    super.key,
    required this.employee,
    required this.department,
  });

  @override
  State<SuperAdminEmployeeDetailsScreen> createState() =>
      _SuperAdminEmployeeDetailsScreenState();
}

class _SuperAdminEmployeeDetailsScreenState
    extends State<SuperAdminEmployeeDetailsScreen> {
  String? _statusFilter;

  List<SuperAdminRequest> get _employeeRequests => widget.department.requests
      .where((r) => r.userId == widget.employee.id)
      .toList();

  List<SuperAdminRequest> get _filtered {
    if (_statusFilter == null) return _employeeRequests;
    return _employeeRequests
        .where((r) => r.status.toLowerCase() == _statusFilter!.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final requests = _employeeRequests;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(emp, requests)),

          // ── Filter chips ─────────────────────────────────────────────────
          if (requests.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip(null, 'الكل', requests.length),
                      const SizedBox(width: 8),
                      _buildChip(
                          'Pending',
                          'معلقة',
                          requests.where((r) => r.isPending).length,
                          color: AppColors.warning),
                      const SizedBox(width: 8),
                      _buildChip(
                          'Approved',
                          'مقبولة',
                          requests.where((r) => r.isApproved).length,
                          color: AppColors.success),
                      const SizedBox(width: 8),
                      _buildChip(
                          'Rejected',
                          'مرفوضة',
                          requests.where((r) => r.isRejected).length,
                          color: AppColors.error),
                    ],
                  ),
                ),
              ),
            ),

          // ── Requests list ────────────────────────────────────────────────
          if (requests.isEmpty)
            const SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.assignment_outlined,
                title: 'لا توجد طلبات',
                message: 'لم يقدم هذا الموظف أي طلبات',
                iconColor: AppColors.textTertiary,
              ),
            )
          else if (_filtered.isEmpty)
            const SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.filter_list_off_rounded,
                title: 'لا توجد نتائج',
                message: 'جرّب تغيير الفلتر',
                iconColor: AppColors.textTertiary,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 24),
              sliver: SliverList.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _RequestCard(
                  request: _filtered[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SuperAdminRequestDetailsScreen(
                        request: _filtered[i],
                        employee: emp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(SuperAdminDeptEmployee emp, List<SuperAdminRequest> requests) {
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
              // Back button
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
              const SizedBox(height: 20),
              // Employee info
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
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
                              errorBuilder: (context, error, stack) =>
                                  _buildInitials(emp.shortNameAr),
                            ),
                          )
                        : _buildInitials(emp.shortNameAr),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.fullNameAr ?? emp.shortNameAr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              emp.isPresent
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 14,
                              color: emp.isPresent
                                  ? Colors.greenAccent
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              emp.isPresent
                                  ? 'حاضر - ${_fmt(emp.todayAttendanceTime!)}'
                                  : 'غائب اليوم',
                              style: TextStyle(
                                color: emp.isPresent
                                    ? Colors.greenAccent
                                    : Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (emp.managerName != null &&
                            emp.managerName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.supervisor_account_outlined,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  emp.managerName!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
                ],
              ),
              const SizedBox(height: 16),
              // Stats
              Row(
                children: [
                  _StatChip(
                      label: 'الطلبات',
                      count: requests.length,
                      color: Colors.white),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'معلقة',
                      count: requests.where((r) => r.isPending).length,
                      color: Colors.orangeAccent),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'مقبولة',
                      count: requests.where((r) => r.isApproved).length,
                      color: Colors.greenAccent),
                ],
              ),
            ],
          ),
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChip(String? value, String label, int count, {Color? color}) {
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

  String _fmt(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
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

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final SuperAdminRequest request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeInfo = _typeInfo(request.type);
    final statusInfo = _statusInfo(request.status);

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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeInfo.$2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeInfo.$1, color: typeInfo.$2, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeInfo.$3,
                      style: AppTextStyles.titleSmall
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    _dateText(),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (request.reason != null &&
                      request.reason!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      request.reason!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateText() {
    if (request.date != null) return request.date!;
    if (request.startDate != null) {
      if (request.endDate != null && request.endDate != request.startDate) {
        return '${request.startDate} → ${request.endDate}';
      }
      return request.startDate!;
    }
    return _formatCreatedAt(request.createdAt);
  }

  String _formatCreatedAt(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
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
