import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import 'models/admin_statistics.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: wire to SuperAdminDashboardCubit or a dedicated statistics endpoint
    final statistics = AdminStatistics(
      totalEmployees: 0,
      pendingRequests: 0,
      todayAttendance: 0,
      activeLeaves: 0,
      totalDepartments: 0,
      todayAbsent: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('الإحصائيات'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Section
            Container(
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
                        'نظرة عامة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow(
                    context,
                    icon: Icons.people_rounded,
                    label: 'إجمالي الموظفين',
                    value: '${statistics.totalEmployees}',
                    color: AppColors.primary,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    context,
                    icon: Icons.business_rounded,
                    label: 'عدد الأقسام',
                    value: '${statistics.totalDepartments}',
                    color: AppColors.primaryDark,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    context,
                    icon: Icons.pending_actions_rounded,
                    label: 'الطلبات المعلقة',
                    value: '${statistics.pendingRequests}',
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Attendance Statistics
            Container(
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
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إحصائيات الحضور',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow(
                    context,
                    icon: Icons.check_circle_rounded,
                    label: 'حضور اليوم',
                    value: '${statistics.todayAttendance}',
                    color: AppColors.success,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    context,
                    icon: Icons.person_off_rounded,
                    label: 'غائبون اليوم',
                    value: '${statistics.todayAbsent}',
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Leaves Statistics
            Container(
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
                          color: const Color(0xFF9C27B0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إحصائيات الإجازات',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow(
                    context,
                    icon: Icons.event_available_rounded,
                    label: 'إجازات نشطة',
                    value: '${statistics.activeLeaves}',
                    color: const Color(0xFF9C27B0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
