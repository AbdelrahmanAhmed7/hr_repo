import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/organization_models.dart';

class EmployeeDetailsDialog extends StatelessWidget {
  final Employee employee;
  final Department? department;
  final int? subordinatesCount;

  const EmployeeDetailsDialog({
    super.key,
    required this.employee,
    this.department,
    this.subordinatesCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForLevel(employee.level);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors[0], colors[1]],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: employee.imageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              employee.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildInitials(),
                            ),
                          )
                        : _buildInitials(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    employee.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      employee.level.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'المستوى الوظيفي',
                    value: employee.level.displayName,
                  ),
                  if (department != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.business_outlined,
                      label: 'القسم',
                      value: department!.name,
                    ),
                  ],
                  if (subordinatesCount != null && subordinatesCount! > 0) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.group_outlined,
                      label: 'عدد المرؤوسين',
                      value: '$subordinatesCount',
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        employee.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Color> _getColorsForLevel(EmployeeLevel level) {
    switch (level) {
      case EmployeeLevel.ceo:
        return [AppColors.primary, AppColors.primaryDark];
      case EmployeeLevel.manager:
        return [const Color(0xFFFF9800), const Color(0xFFE65100)];
      case EmployeeLevel.employee:
        return [const Color(0xFF2196F3), const Color(0xFF0D47A1)];
    }
  }
}
