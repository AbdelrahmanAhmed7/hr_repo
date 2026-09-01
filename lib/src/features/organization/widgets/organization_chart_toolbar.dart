import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../cubit/organization_chart_cubit.dart';
import '../cubit/organization_chart_state.dart';
import '../models/organization_models.dart';
import '../models/view_mode.dart';
import 'organization_chart_search_bar.dart';
import '../../../shared/widgets/searchable_dropdown_field.dart';

/// Toolbar widget for organization chart with portrait and landscape layouts
class OrganizationChartToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final int? selectedDepartmentId;
  final ValueChanged<int?> onDepartmentChanged;
  final VoidCallback onExport;
  final VoidCallback onReset;

  const OrganizationChartToolbar({
    super.key,
    required this.searchController,
    required this.selectedDepartmentId,
    required this.onDepartmentChanged,
    required this.onExport,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return BlocBuilder<OrganizationChartCubit, OrganizationChartState>(
      builder: (context, state) {
        final departments = state.organizationData?.departments ?? [];
        final organizationData = state.organizationData;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 12 : 16,
            vertical: isLandscape ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLandscape
              ? _buildLandscapeLayout(
                  context: context,
                  state: state,
                  departments: departments,
                  organizationData: organizationData,
                )
              : _buildPortraitLayout(
                  context: context,
                  state: state,
                  departments: departments,
                  organizationData: organizationData,
                ),
        );
      },
    );
  }

  Widget _buildPortraitLayout({
    required BuildContext context,
    required OrganizationChartState state,
    required List<Department> departments,
    required OrganizationData? organizationData,
  }) {
    final cubit = context.read<OrganizationChartCubit>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Search bar - takes most space
        Expanded(
          child: OrganizationChartSearchBar(
            controller: searchController,
            onChanged: (value) => cubit.searchEmployees(value),
            resultCount:
                state.searchQuery != null && state.searchQuery!.isNotEmpty
                ? state.employees?.where((e) => e.isHighlighted).length
                : state.employees?.length,
            employees: state.employees,
          ),
        ),
        const SizedBox(width: 12),
        // View Mode Selector - Direct change (no drawer)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: OrganizationViewMode.values.map((mode) {
              final isSelected = state.viewMode == mode;
              return InkWell(
                onTap: () => cubit.changeViewMode(mode),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    mode.icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout({
    required BuildContext context,
    required OrganizationChartState state,
    required List<Department> departments,
    required OrganizationData? organizationData,
  }) {
    final cubit = context.read<OrganizationChartCubit>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Search bar
        SizedBox(
          width: 300,
          child: OrganizationChartSearchBar(
            controller: searchController,
            onChanged: (value) => cubit.searchEmployees(value),
            resultCount:
                state.searchQuery != null && state.searchQuery!.isNotEmpty
                ? state.employees?.where((e) => e.isHighlighted).length
                : state.employees?.length,
            employees: state.employees,
          ),
        ),
        const SizedBox(width: 12),
        // Actions - compact icon buttons
        IconButton(
          onPressed: () {
            onReset();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إعادة تعيين الهيكل التنظيمي'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'إعادة تعيين',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.backgroundSecondary,
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onExport,
          icon: const Icon(Icons.download_rounded, size: 20),
          tooltip: 'تصدير',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 12),
        // Filter dropdown
        SizedBox(
          width: 200,
          child: SearchableDropdownField<int>(
            value: selectedDepartmentId,
            labelText: 'فلترة حسب القسم',
            searchHintText: 'ابحث عن قسم',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            items: [
              const SearchableDropdownItem<int?>(
                value: null,
                label: 'جميع الأقسام',
              ),
              ...departments.map((dept) {
                return SearchableDropdownItem<int?>(
                  value: dept.id,
                  label: dept.name,
                );
              }),
            ],
            onChanged: onDepartmentChanged,
          ),
        ),
      ],
    );
  }
}
