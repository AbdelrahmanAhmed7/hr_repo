import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../hr/cubit/employees_cubit.dart';
import '../models/organization_models.dart';
import 'employee_details_dialog.dart';

/// Grid view for organization chart
class OrganizationChartGridView extends StatefulWidget {
  final List<Employee> employees;
  final OrganizationData? organizationData;
  final String? selectedEmployeeId;
  final Function(String)? onEmployeeTap;

  const OrganizationChartGridView({
    super.key,
    required this.employees,
    this.organizationData,
    this.selectedEmployeeId,
    this.onEmployeeTap,
  });

  @override
  State<OrganizationChartGridView> createState() => _OrganizationChartGridViewState();
}

class _OrganizationChartGridViewState extends State<OrganizationChartGridView> {
  final ScrollController _scrollController = ScrollController();
  int _previousHighlightedCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrganizationChartGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Scroll to first highlighted item when search results change
    final highlightedCount = widget.employees.where((e) => e.isHighlighted).length;
    if (highlightedCount > 0 && highlightedCount != _previousHighlightedCount) {
      _previousHighlightedCount = highlightedCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstHighlighted();
      });
    } else if (highlightedCount == 0) {
      _previousHighlightedCount = 0;
    }
  }

  void _scrollToFirstHighlighted() {
    if (!_scrollController.hasClients) return;
    
    final firstHighlightedIndex = widget.employees.indexWhere((e) => e.isHighlighted);
    if (firstHighlightedIndex != -1) {
      // First, scroll to the beginning to ensure accurate positioning
      _scrollController.jumpTo(0);
      
      // Then scroll to the first highlighted item after a short delay
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!_scrollController.hasClients) return;
        
        // Calculate scroll position for grid (2 columns)
        // Item height is approximately 250px (200px content + 16px spacing)
        final row = firstHighlightedIndex ~/ 2;
        const itemHeight = 250.0; // Approximate item height with spacing
        final scrollPosition = row * itemHeight;
        
        // Ensure we don't scroll beyond the bounds
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetScroll = scrollPosition.clamp(0.0, maxScroll);
        
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.employees.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'لا توجد بيانات للعرض',
        message: 'لم يتم العثور على أي موظفين',
        iconColor: AppColors.textSecondary,
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72, // Reduced to prevent overflow
      ),
      itemCount: widget.employees.length,
      itemBuilder: (context, index) {
        final employee = widget.employees[index];
        final isSelected = widget.selectedEmployeeId == employee.id;
        
        return _buildEmployeeGridItem(context, employee, isSelected)
            .animate()
            .fadeIn(
              duration: 300.ms,
              delay: (index * 60).ms,
              curve: Curves.easeOut,
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 350.ms,
              delay: (index * 60).ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  Widget _buildEmployeeGridItem(
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

    // Find department
    Department? department;
    if (widget.organizationData != null) {
      for (final dept in widget.organizationData!.departments) {
        if (dept.manager.id == employee.id ||
            dept.employees.any((e) => e.id == employee.id)) {
          department = dept;
          break;
        }
      }
    }

    final levelColor = _getLevelColor(employee.level);

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? levelColor.withValues(alpha: 0.08) 
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected 
              ? levelColor 
              : employee.isHighlighted 
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : AppColors.border,
          width: isSelected ? 2.5 : employee.isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? levelColor.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isSelected ? 16 : 10,
            offset: Offset(0, isSelected ? 6 : 3),
            spreadRadius: isSelected ? 1 : 0,
          ),
          if (employee.isHighlighted)
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
              spreadRadius: 2,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onEmployeeTap?.call(employee.id);
            _showEmployeeDetails(context, employee, department);
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: levelColor.withValues(alpha: 0.15),
          highlightColor: levelColor.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      levelColor.withValues(alpha: 0.15),
                      levelColor.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: levelColor.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    employee.initials,
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Flexible(
                child: Text(
                  employee.username,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              // Position
              if (position != null && position.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    position,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
              ],
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
          ),
        ),
        ),
      ),
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
    final subordinatesCount = widget.employees.where((e) => e.managerId == employee.id).length;

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
            subordinatesCount: subordinatesCount > 0 ? subordinatesCount : null,
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
          subordinatesCount: subordinatesCount > 0 ? subordinatesCount : null,
        ),
      );
    }
  }
}

