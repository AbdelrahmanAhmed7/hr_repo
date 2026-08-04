import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/super_admin_dashboard_response.dart';

class SuperAdminRequestDetailsScreen extends StatelessWidget {
  final SuperAdminRequest request;
  final SuperAdminDeptEmployee? employee;

  const SuperAdminRequestDetailsScreen({
    super.key,
    required this.request,
    this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _typeInfo(request.type);
    final statusInfo = _statusInfo(request.status);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: typeInfo.$2.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: typeInfo.$2.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeInfo.$1, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                typeInfo.$3,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Title = employee name or request type
                        Text(
                          employee != null
                              ? (employee!.fullNameAr ?? employee!.shortNameAr)
                              : typeInfo.$3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusInfo.$1,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusInfo.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Employee card
                if (employee != null) ...[
                  _buildEmployeeCard(employee!),
                  const SizedBox(height: 16),
                ],

                // Request details card
                _buildDetailsCard(typeInfo),

                // Rejection reason
                if (request.status.toLowerCase() == 'rejected') ...[
                  const SizedBox(height: 16),
                  _buildRejectionCard(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Employee Card ──────────────────────────────────────────────────────────

  Widget _buildEmployeeCard(SuperAdminDeptEmployee emp) {
    return _Card(
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryTint,
            ),
            child: emp.imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      emp.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          _initials(emp.shortNameAr),
                    ),
                  )
                : _initials(emp.shortNameAr),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emp.fullNameAr ?? emp.shortNameAr,
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      emp.isPresent
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 13,
                      color: emp.isPresent
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      emp.isPresent
                          ? 'حاضر - ${_fmt(emp.todayAttendanceTime!)}'
                          : 'غائب اليوم',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: emp.isPresent
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.person_rounded,
              color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }

  // ── Details Card ───────────────────────────────────────────────────────────

  Widget _buildDetailsCard(
      (IconData, Color, String) typeInfo) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.info_outline_rounded, title: 'تفاصيل الطلب'),
          const SizedBox(height: 14),

          // Date
          if (request.date != null) ...[
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'التاريخ',
              value: request.date!,
            ),
            const SizedBox(height: 10),
          ],

          // Date range
          if (request.startDate != null) ...[
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'من',
              value: request.startDate!,
            ),
            if (request.endDate != null &&
                request.endDate != request.startDate) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.calendar_month_rounded,
                label: 'إلى',
                value: request.endDate!,
              ),
            ],
            const SizedBox(height: 10),
          ],

          // Time
          if (request.startTime != null) ...[
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'الوقت',
              value:
                  '${_trimSec(request.startTime!)} - ${_trimSec(request.endTime ?? '')}',
            ),
            const SizedBox(height: 10),
          ],

          // Location
          if (request.where != null && request.where!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'الموقع',
              value: request.where!,
            ),
            const SizedBox(height: 10),
          ],

          // Reason
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.description_outlined,
              label: 'السبب',
              value: request.reason!,
            ),
            const SizedBox(height: 10),
          ],

          // Created at
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'تاريخ الإنشاء',
            value: _fmtDate(request.createdAt),
          ),
        ],
      ),
    );
  }

  // ── Rejection Card ─────────────────────────────────────────────────────────

  Widget _buildRejectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سبب الرفض',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لم يتم تحديد سبب',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final text = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts[0][0]
            : '${parts.first[0]}${parts.last[0]}';
    return Center(
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _fmt(String time) {
    final p = time.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : time;
  }

  String _trimSec(String time) {
    final p = time.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : time;
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 15),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style:
              AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
