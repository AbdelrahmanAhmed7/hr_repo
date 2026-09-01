import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../cubit/organization_chart_cubit.dart';
import '../cubit/organization_chart_state.dart';
import '../models/organization_models.dart';
import 'organization_chart_legend.dart';
import 'organization_chart_view_mode_selector.dart';
import 'organization_chart_statistics_dashboard.dart';
import '../../../shared/widgets/searchable_dropdown_field.dart';

/// Drawer for organization chart settings and view modes
class OrganizationChartDrawer extends StatelessWidget {
  final int? selectedDepartmentId;
  final ValueChanged<int?> onDepartmentChanged;
  final VoidCallback onExport;
  final VoidCallback onReset;

  const OrganizationChartDrawer({
    super.key,
    required this.selectedDepartmentId,
    required this.onDepartmentChanged,
    required this.onExport,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationChartCubit, OrganizationChartState>(
      builder: (context, state) {
        final cubit = context.read<OrganizationChartCubit>();
        final departments = state.organizationData?.departments ?? [];

        return Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_tree_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إعدادات',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الهيكل التنظيمي',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // View Mode Section - Quick access (first priority)
                      _buildSectionHeader(
                        context,
                        icon: Icons.view_module_rounded,
                        title: 'نمط العرض',
                      ),
                      const SizedBox(height: 12),
                      OrganizationChartViewModeSelector(
                        selectedMode: state.viewMode,
                        onModeChanged: (mode) {
                          cubit.changeViewMode(mode);
                          Navigator.of(
                            context,
                          ).pop(); // Close drawer after selection
                        },
                      ),
                      const SizedBox(height: 24),
                      // Filter Section
                      _buildSectionHeader(
                        context,
                        icon: Icons.filter_list_rounded,
                        title: 'الفلترة',
                      ),
                      const SizedBox(height: 12),
                      SearchableDropdownField<int>(
                        value: selectedDepartmentId,
                        labelText: 'فلترة حسب القسم',
                        searchHintText: 'ابحث عن قسم',
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
                      const SizedBox(height: 12),
                      SearchableDropdownField<EmployeeLevel>(
                        value: state.filteredLevel,
                        labelText: 'فلترة حسب المستوى',
                        searchHintText: 'ابحث عن مستوى',
                        items: [
                          const SearchableDropdownItem<EmployeeLevel?>(
                            value: null,
                            label: 'جميع المستويات',
                          ),
                          ...EmployeeLevel.values.map((level) {
                            return SearchableDropdownItem<EmployeeLevel?>(
                              value: level,
                              label: level.displayName,
                            );
                          }),
                        ],
                        onChanged: (value) {
                          cubit.filterByLevel(value);
                        },
                      ),
                      const SizedBox(height: 24),
                      // Statistics Dashboard - Secondary info
                      if (state.organizationData != null) ...[
                        _buildSectionHeader(
                          context,
                          icon: Icons.bar_chart_rounded,
                          title: 'الإحصائيات',
                        ),
                        const SizedBox(height: 12),
                        OrganizationChartStatisticsDashboard(
                          organizationData: state.organizationData!,
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Legend Section
                      _buildSectionHeader(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'مفتاح الألوان',
                      ),
                      const SizedBox(height: 12),
                      const OrganizationChartLegend(),
                      const SizedBox(height: 24),
                      // Actions Section
                      _buildSectionHeader(
                        context,
                        icon: Icons.settings_rounded,
                        title: 'الإجراءات',
                      ),
                      const SizedBox(height: 12),
                      // Reset Button
                      ListTile(
                        leading: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text('إعادة تعيين'),
                        subtitle: const Text('إعادة تعيين الهيكل التنظيمي'),
                        onTap: () {
                          onReset();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إعادة تعيين الهيكل التنظيمي'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: AppColors.backgroundSecondary,
                      ),
                      const SizedBox(height: 8),
                      // Toggle Orientation Button
                      ListTile(
                        leading: Icon(
                          state.isHorizontal
                              ? Icons.swap_vert_rounded
                              : Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          state.isHorizontal ? 'وضع رأسي' : 'وضع أفقي',
                        ),
                        subtitle: const Text('تغيير اتجاه الشجرة'),
                        onTap: () {
                          cubit.toggleOrientation();
                          Navigator.of(context).pop();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: AppColors.backgroundSecondary,
                      ),
                      const SizedBox(height: 8),
                      // Export Button
                      ListTile(
                        leading: const Icon(
                          Icons.download_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text('تصدير'),
                        subtitle: const Text('تصدير الهيكل التنظيمي'),
                        onTap: () {
                          Navigator.of(context).pop();
                          onExport();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: AppColors.backgroundSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
