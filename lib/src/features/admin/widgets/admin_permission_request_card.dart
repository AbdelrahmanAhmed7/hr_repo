import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../permissions/models/permission_request.dart';

class AdminPermissionRequestCard extends StatelessWidget {
  final PermissionRequest permission;

  const AdminPermissionRequestCard({
    super.key,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          context,
          icon: Icons.calendar_today_outlined,
          label: 'التاريخ',
          value: permission.dateText,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          icon: Icons.access_time,
          label: 'وقت الخروج',
          value: permission.timeRangeText,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          icon: Icons.timer_outlined,
          label: 'المدة',
          value: permission.durationText,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          icon: Icons.info_outline,
          label: 'السبب',
          value: permission.reason,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}





