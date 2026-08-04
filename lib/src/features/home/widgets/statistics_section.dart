import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/skeleton/skeleton_statistics.dart';
import '../models/home_statistics.dart';

class StatisticsSection extends StatelessWidget {
  final HomeStatistics? statistics;
  final bool isLoading;

  const StatisticsSection({super.key, this.statistics, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading || statistics == null) {
      return const SkeletonStatistics(itemCount: 4);
    }

    final stats = statistics!;
    final List<Widget> cards = [];

    if (stats.remainingLeaves != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.date_range_rounded,
          title: 'رصيد الإجازات',
          value: '${stats.remainingLeaves}',
          unit: 'يوم',
          color: AppColors.success,
        ),
      );
    }

    if (stats.workHours != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.timer_rounded,
          title: 'ساعات العمل',
          value: stats.workHours!.toStringAsFixed(1),
          unit: 'ساعة',
          color: AppColors.primaryLight,
        ),
      );
    }

    if (stats.pendingRequests != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.hourglass_empty_rounded,
          title: 'طلبات معلقة',
          value: '${stats.pendingRequests}',
          unit: 'طلب',
          color: AppColors.warning,
        ),
      );
    }

    if (stats.acceptedRequests != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          title: 'طلبات مقبولة',
          value: '${stats.acceptedRequests}',
          unit: 'طلب',
          color: AppColors.success,
        ),
      );
    }

    if (stats.rejectedRequests != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.cancel_rounded,
          title: 'طلبات مرفوضة',
          value: '${stats.rejectedRequests}',
          unit: 'طلب',
          color: AppColors.error,
        ),
      );
    }

    if (stats.totalLeaves != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.calendar_month_rounded,
          title: 'إجازات',
          value: '${stats.totalLeaves}',
          unit: 'طلب',
          color: AppColors.primary,
        ),
      );
    }

    if (stats.totalPermissions != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.directions_walk_rounded,
          title: 'أذونات',
          value: '${stats.totalPermissions}',
          unit: 'طلب',
          color: AppColors.info,
        ),
      );
    }

    if (stats.totalMissions != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.business_center_rounded,
          title: 'مأموريات',
          value: '${stats.totalMissions}',
          unit: 'طلب',
          color: AppColors.textSecondary,
        ),
      );
    }

    if (stats.attendanceDays != null) {
      cards.add(
        _buildStatCard(
          icon: Icons.event_available_rounded,
          title: 'أيام الحضور',
          value: '${stats.attendanceDays}',
          unit: 'يوم',
          color: AppColors.primaryDark,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'إحصائيات سريعة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling list of cards to save space and look modern
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            child: Row(
              children: cards.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(left: entry.key == cards.length - 1 ? 0 : 12),
                  child: SizedBox(
                    width: 140, // Fixed width for modern horizontal cards
                    child: entry.value,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
