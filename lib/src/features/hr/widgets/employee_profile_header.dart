import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/employee.dart';

/// Header widget for employee profile screen with gradient background and avatar
class EmployeeProfileHeader extends StatelessWidget {
  final Employee employee;

  const EmployeeProfileHeader({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 4,
                  ),
                ),
                child: employee.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          employee.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialsAvatar(),
                        ),
                      )
                    : _buildInitialsAvatar(),
              ),
              const SizedBox(height: 20),
              Text(
                employee.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                textAlign: TextAlign.center,
              ),
              if (employee.position != null) ...[
                const SizedBox(height: 8),
                Text(
                  employee.position!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (employee.department != null) ...[
                const SizedBox(height: 4),
                Text(
                  employee.department!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (employee.employeeCode != null &&
                      employee.employeeCode!.isNotEmpty)
                    _HeaderChip(
                      label: employee.employeeCode!,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                  if (employee.role != null && employee.role!.isNotEmpty)
                    _HeaderChip(
                      label: employee.role!,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                    ),
                  if (employee.isActive != null)
                    _HeaderChip(
                      label: employee.isActive! ? 'نشط' : 'غير نشط',
                      backgroundColor: employee.isActive!
                          ? const Color(0x3322C55E)
                          : const Color(0x33EF4444),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        employee.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _HeaderChip({
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

