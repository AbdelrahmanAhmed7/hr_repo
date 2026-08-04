import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/admin_assignments_cubit.dart';
import '../cubit/admin_assignments_state.dart';
import '../models/department_assignment.dart';

class DepartmentAssignmentCard extends StatelessWidget {
  final DepartmentAssignment assignment;
  final bool isUpdating;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const DepartmentAssignmentCard({
    super.key,
    required this.assignment,
    required this.isUpdating,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(assignment.status);

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
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xFFFF9800),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.employeeNameAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatCreatedAt(assignment.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
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
              icon: Icons.location_on_rounded,
              label: 'الموقع',
              value: assignment.where,
            ),
            const SizedBox(height: 8),
            if (assignment.isSingleDay)
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'التاريخ',
                value: assignment.startDate,
              )
            else ...[
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'من',
                value: assignment.startDate,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.calendar_month_rounded,
                label: 'إلى',
                value: assignment.endDate,
              ),
            ],
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'الوقت',
              value:
                  '${_trimSeconds(assignment.startTime)} - ${_trimSeconds(assignment.endTime)}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.description_outlined,
              label: 'السبب',
              value: assignment.reason,
            ),

            // Rejection reason
            if (assignment.rejectionReason != null &&
                assignment.rejectionReason!.isNotEmpty) ...[
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
                        'سبب الرفض: ${assignment.rejectionReason}',
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

            // ── Action buttons ───────────────────────────────────────────
            if (assignment.isPending) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              BlocBuilder<AdminAssignmentsCubit, AdminAssignmentsState>(
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
