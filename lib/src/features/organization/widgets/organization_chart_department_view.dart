import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../hr/cubit/employees_cubit.dart';
import '../models/organization_models.dart';
import 'employee_details_dialog.dart';

/// Department-based view for organization chart
class OrganizationChartDepartmentView extends StatelessWidget {
  final List<Employee> employees;
  final OrganizationData? organizationData;
  final String? selectedEmployeeId;
  final Function(String)? onEmployeeTap;

  const OrganizationChartDepartmentView({
    super.key,
    required this.employees,
    this.organizationData,
    this.selectedEmployeeId,
    this.onEmployeeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (organizationData == null || organizationData!.departments.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.business_outlined,
        title: 'لا توجد بيانات للعرض',
        message: 'لم يتم العثور على بيانات الهيكل التنظيمي',
        iconColor: AppColors.textSecondary,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: organizationData!.departments.length + 1, // +1 for CEO
      itemBuilder: (context, index) {
        if (index == 0) {
          // CEO Section
          final ceo = organizationData!.ceo;
          return _buildCEOSection(context, ceo);
        } else {
          // Department Section
          final department = organizationData!.departments[index - 1];
          return _buildDepartmentSection(context, department);
        }
      },
    );
  }

  Widget _buildCEOSection(BuildContext context, Employee ceo) {
    final isSelected = selectedEmployeeId == ceo.id;
    final levelColor = _getLevelColor(ceo.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? levelColor : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  levelColor,
                  levelColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'المدير التنفيذي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // CEO Card
          InkWell(
            onTap: () {
              onEmployeeTap?.call(ceo.id);
              _showEmployeeDetails(context, ceo, null);
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildEmployeeRow(context, ceo, isSelected),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentSection(BuildContext context, Department department) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    department.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${department.employees.length + 1} موظف', // +1 for manager
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Manager
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            child: _buildManagerCard(context, department.manager),
          ),
          // Employees
          if (department.employees.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                'الموظفين',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            ...department.employees.map((employee) {
              final isSelected = selectedEmployeeId == employee.id;
              return InkWell(
                onTap: () {
                  onEmployeeTap?.call(employee.id);
                  _showEmployeeDetails(context, employee, department);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    color: isSelected
                        ? AppColors.primaryTint
                        : Colors.transparent,
                  ),
                  child: _buildEmployeeRow(context, employee, isSelected),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildManagerCard(BuildContext context, Employee manager) {
    final isSelected = selectedEmployeeId == manager.id;
    final levelColor = _getLevelColor(manager.level);

    return InkWell(
      onTap: () {
        onEmployeeTap?.call(manager.id);
        // Find department for manager
        Department? dept;
        if (organizationData != null) {
          dept = organizationData!.departments.firstWhere(
            (d) => d.manager.id == manager.id,
            orElse: () => throw StateError('Department not found'),
          );
        }
        _showEmployeeDetails(context, manager, dept);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: levelColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'مدير',
              style: TextStyle(
                color: levelColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEmployeeRow(context, manager, isSelected),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(
    BuildContext context,
    Employee employee,
    bool isSelected,
  ) {
    // Get employee position from HR cubit if available
    String? position;
    try {
      final employeesCubit = context.read<EmployeesCubit>();
      final hrEmployee = employeesCubit.state.employees.firstWhere(
        (e) => e.id == employee.id,
        orElse: () => throw StateError('Employee not found'),
      );
      position = hrEmployee.position;
    } catch (e) {
      // Employee not found in HR list
    }

    final levelColor = _getLevelColor(employee.level);

    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: levelColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: levelColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              employee.initials,
              style: TextStyle(
                color: levelColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.username,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (position != null && position.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  position,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // Level Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: levelColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: levelColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            employee.level.displayName,
            style: TextStyle(
              color: levelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(EmployeeLevel level) {
    switch (level) {
      case EmployeeLevel.ceo:
        return AppColors.primary;
      case EmployeeLevel.manager:
        return const Color(0xFFFF9800);
      case EmployeeLevel.employee:
        return const Color(0xFF2196F3);
    }
  }

  void _showEmployeeDetails(
    BuildContext context,
    Employee employee,
    Department? department,
  ) {
    // Calculate subordinates count
    int? subordinatesCount;
    if (organizationData != null) {
      if (employee.level == EmployeeLevel.ceo) {
        // For CEO, count all managers and employees
        subordinatesCount = organizationData!.departments.length +
            organizationData!.departments.fold(
              0,
              (sum, dept) => sum + dept.employees.length,
            );
      } else if (employee.level == EmployeeLevel.manager) {
        // For manager, count employees in their department
        subordinatesCount = department?.employees.length ?? 0;
      } else {
        subordinatesCount = 0;
      }
    }

    // Try to get EmployeesCubit and AuthCubit from context
    try {
      final employeesCubit = context.read<EmployeesCubit>();
      final authCubit = context.read<AuthCubit>();
      showDialog(
        context: context,
        builder: (dialogContext) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: employeesCubit),
            BlocProvider.value(value: authCubit),
          ],
          child: EmployeeDetailsDialog(
            employee: employee,
            department: department,
            subordinatesCount: subordinatesCount != null && subordinatesCount > 0
                ? subordinatesCount
                : null,
          ),
        ),
      );
    } catch (e) {
      // Cubits not available, show dialog without them
      showDialog(
        context: context,
        builder: (dialogContext) => EmployeeDetailsDialog(
          employee: employee,
          department: department,
          subordinatesCount: subordinatesCount != null && subordinatesCount > 0
              ? subordinatesCount
              : null,
        ),
      );
    }
  }
}

