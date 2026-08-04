import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../hr/cubit/employees_cubit.dart';
import '../models/organization_models.dart';
import 'employee_details_dialog.dart';

/// List view for organization chart
class OrganizationChartListView extends StatefulWidget {
  final List<Employee> employees;
  final OrganizationData? organizationData;
  final String? selectedEmployeeId;
  final Function(String)? onEmployeeTap;

  const OrganizationChartListView({
    super.key,
    required this.employees,
    this.organizationData,
    this.selectedEmployeeId,
    this.onEmployeeTap,
  });

  @override
  State<OrganizationChartListView> createState() => _OrganizationChartListViewState();
}

class _OrganizationChartListViewState extends State<OrganizationChartListView> {
  final ScrollController _scrollController = ScrollController();
  int _previousHighlightedCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrganizationChartListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if search query changed (employees list or highlighted state)
    final hasHighlightedChange = widget.employees.any((e) => e.isHighlighted) != 
        oldWidget.employees.any((e) => e.isHighlighted);
    
    // Scroll to first highlighted item when search results change
    final highlightedCount = widget.employees.where((e) => e.isHighlighted).length;
    if (highlightedCount > 0 && (highlightedCount != _previousHighlightedCount || hasHighlightedChange)) {
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
      // Calculate scroll position using fixed itemExtent (100.0)
      // itemExtent = 100.0, padding = 16.0 (top)
      final scrollPosition = (firstHighlightedIndex * 100.0) + 16.0;
      
      // Ensure we don't scroll beyond the bounds
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetScroll = scrollPosition.clamp(0.0, maxScroll);
      
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.employees.length,
      itemExtent: 100.0, // Fixed item height for accurate scrolling
      itemBuilder: (context, index) {
        final employee = widget.employees[index];
        final isSelected = widget.selectedEmployeeId == employee.id;
        
        return _buildEmployeeListItem(context, employee, isSelected)
            .animate()
            .fadeIn(
              duration: 300.ms,
              delay: (index * 50).ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 300.ms,
              delay: (index * 50).ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  Widget _buildEmployeeListItem(
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? levelColor.withValues(alpha: 0.08) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                ? levelColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isSelected ? 12 : 8,
            offset: Offset(0, isSelected ? 4 : 2),
            spreadRadius: isSelected ? 1 : 0,
          ),
          if (employee.isHighlighted)
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
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
          borderRadius: BorderRadius.circular(16),
          splashColor: levelColor.withValues(alpha: 0.1),
          highlightColor: levelColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getLevelColor(employee.level).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getLevelColor(employee.level).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    employee.initials,
                    style: TextStyle(
                      color: _getLevelColor(employee.level),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (position != null && position.isNotEmpty) ...[
                      Text(
                        position,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (department != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              department.name,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getLevelColor(employee.level).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getLevelColor(employee.level).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  employee.level.displayName,
                  style: TextStyle(
                    color: _getLevelColor(employee.level),
                    fontSize: 12,
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

