import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AdminRecentActivities extends StatelessWidget {
  const AdminRecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الأنشطة الأخيرة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            context,
            icon: Icons.event_available,
            title: 'طلب إجازة جديد',
            subtitle: 'محمد أحمد - إجازة سنوية',
            time: 'منذ 5 دقائق',
            color: AppColors.primary,
          ),
          const Divider(height: 24),
          _buildActivityItem(
            context,
            icon: Icons.description,
            title: 'طلب إذن جديد',
            subtitle: 'أحمد علي - إذن خروج',
            time: 'منذ 15 دقيقة',
            color: AppColors.warning,
          ),
          const Divider(height: 24),
          _buildActivityItem(
            context,
            icon: Icons.assignment,
            title: 'مأمورية جديدة',
            subtitle: 'سارة محمد - مأمورية خارجية',
            time: 'منذ 30 دقيقة',
            color: AppColors.primary,
          ),
          const Divider(height: 24),
          _buildActivityItem(
            context,
            icon: Icons.check_circle,
            title: 'تم الموافقة على طلب',
            subtitle: 'علي حسن - إجازة',
            time: 'منذ ساعة',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }
}
