import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/organization_models.dart';

/// Comprehensive statistics dashboard for organization chart
class OrganizationChartStatisticsDashboard extends StatelessWidget {
  final OrganizationData organizationData;

  const OrganizationChartStatisticsDashboard({
    super.key,
    required this.organizationData,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics(organizationData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Overview Cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_rounded,
                label: 'إجمالي الموظفين',
                value: '${stats.totalEmployees}',
                color: AppColors.primary,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.business_rounded,
                label: 'الأقسام',
                value: '${stats.totalDepartments}',
                color: const Color(0xFFFF9800),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF9800),
                    const Color(0xFFF57C00),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.person_outline_rounded,
                label: 'المديرين',
                value: '${stats.totalManagers}',
                color: const Color(0xFF2196F3),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2196F3),
                    const Color(0xFF1976D2),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.account_tree_rounded,
                label: 'الموظفين العاديين',
                value: '${stats.totalRegularEmployees}',
                color: const Color(0xFF4CAF50),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF388E3C),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Level Distribution
        _buildSectionHeader('التوزيع حسب المستوى'),
        const SizedBox(height: 12),
        _LevelDistributionCard(stats: stats),
        
        const SizedBox(height: 24),
        
        // Department Breakdown
        _buildSectionHeader('التوزيع حسب الأقسام'),
        const SizedBox(height: 12),
        _DepartmentBreakdownCard(departments: organizationData.departments),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  _Statistics _calculateStatistics(OrganizationData data) {
    final allEmployees = OrganizationData.convertToOrgChartList(data);
    int totalEmployees = allEmployees.length;
    int totalDepartments = 0; // We don't have department data from API yet
    int totalManagers = allEmployees.where((e) => e.level == EmployeeLevel.ceo || e.level == EmployeeLevel.manager).length;
    int totalRegularEmployees = allEmployees.where((e) => e.level == EmployeeLevel.employee).length;
    int ceoCount = allEmployees.where((e) => e.level == EmployeeLevel.ceo).length;
    int managerCount = allEmployees.where((e) => e.level == EmployeeLevel.manager).length;

    return _Statistics(
      totalEmployees: totalEmployees,
      totalDepartments: totalDepartments,
      totalManagers: totalManagers,
      totalRegularEmployees: totalRegularEmployees,
      ceoCount: ceoCount,
      managerCount: managerCount,
    );
  }
}

class _Statistics {
  final int totalEmployees;
  final int totalDepartments;
  final int totalManagers;
  final int totalRegularEmployees;
  final int ceoCount;
  final int managerCount;

  _Statistics({
    required this.totalEmployees,
    required this.totalDepartments,
    required this.totalManagers,
    required this.totalRegularEmployees,
    required this.ceoCount,
    required this.managerCount,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Gradient gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelDistributionCard extends StatelessWidget {
  final _Statistics stats;

  const _LevelDistributionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalEmployees;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _LevelItem(
            label: 'CEO',
            count: stats.ceoCount,
            total: total,
            color: AppColors.primary,
            icon: Icons.star_rounded,
          ),
          const SizedBox(height: 12),
          _LevelItem(
            label: 'مديرين',
            count: stats.managerCount,
            total: total,
            color: const Color(0xFFFF9800),
            icon: Icons.supervisor_account_rounded,
          ),
          const SizedBox(height: 12),
          _LevelItem(
            label: 'موظفين',
            count: stats.totalRegularEmployees,
            total: total,
            color: const Color(0xFF2196F3),
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _LevelItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _LevelItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.backgroundSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepartmentBreakdownCard extends StatelessWidget {
  final List<Department> departments;

  const _DepartmentBreakdownCard({required this.departments});

  @override
  Widget build(BuildContext context) {
    if (departments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'لا توجد أقسام',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: departments.asMap().entries.map((entry) {
          final index = entry.key;
          final dept = entry.value;
          final employeeCount = dept.employees.length;

          return Column(
            children: [
              if (index > 0) const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
                          dept.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$employeeCount موظف',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    dept.manager.username,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

