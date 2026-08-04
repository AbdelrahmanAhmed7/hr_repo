import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/admin_permissions_cubit.dart';
import '../cubit/admin_permissions_state.dart';
import '../models/department_permission.dart';

class DepartmentPermissionCard extends StatelessWidget {
  final DepartmentPermission permission;
  final bool isUpdating;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const DepartmentPermissionCard({
    super.key,
    required this.permission,
    required this.isUpdating,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(permission.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.employeeNameAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatCreatedAt(permission.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.$1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusInfo.$1.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusInfo.$2,
                    style: TextStyle(
                      color: statusInfo.$1,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Details ──────────────────────────────────────────────────
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'التاريخ',
              value: permission.date,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'الوقت',
              value:
                  '${_trimSeconds(permission.startTime)} - ${_trimSeconds(permission.endTime)}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'المدة',
              value: _calcDuration(permission.startTime, permission.endTime),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.description_outlined,
              label: 'السبب',
              value: permission.reason,
            ),

            // Rejection reason
            if (permission.rejectionReason != null &&
                permission.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${permission.rejectionReason}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Action buttons (pending only) ────────────────────────────
            if (permission.isPending) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              BlocBuilder<AdminPermissionsCubit, AdminPermissionsState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.isUpdating ? null : onReject,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('رفض'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: AppTextStyles.labelMedium,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: state.isUpdating ? null : onApprove,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('قبول'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: AppTextStyles.labelMedium,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _trimSeconds(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  String _calcDuration(String start, String end) {
    try {
      final sp = start.split(':');
      final ep = end.split(':');
      final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
      final endMin = int.parse(ep[0]) * 60 + int.parse(ep[1]);
      final diff = endMin - startMin;
      if (diff <= 0) return '-';
      final h = diff ~/ 60;
      final m = diff % 60;
      if (h == 0) return '$m دقيقة';
      if (m == 0) return '$h ${h == 1 ? 'ساعة' : 'ساعات'}';
      return '$h ${h == 1 ? 'ساعة' : 'ساعات'} و $m دقيقة';
    } catch (_) {
      return '-';
    }
  }

  String _formatCreatedAt(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  (Color, String) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (AppColors.success, 'مقبول');
      case 'rejected':
        return (AppColors.error, 'مرفوض');
      default:
        return (AppColors.warning, 'معلق');
    }
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
