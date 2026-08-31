import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/hr/cubit/employees_cubit.dart';
import '../../features/hr/cubit/employees_state.dart';
import '../../features/hr/employee_profile_screen.dart';
import '../../features/hr/models/employee.dart';
import '../../shared/utils/debouncer.dart';
import '../../shared/widgets/empty_state_widget.dart';

/// Lightweight read-only employees list for the Super Admin.
/// Reuses the EmployeesCubit/APIs but with a compact UI (slim header +
/// search + filter chips) so the list is immediately visible.
class SuperAdminEmployeesScreen extends StatefulWidget {
  const SuperAdminEmployeesScreen({super.key});

  @override
  State<SuperAdminEmployeesScreen> createState() =>
      _SuperAdminEmployeesScreenState();
}

class _SuperAdminEmployeesScreenState extends State<SuperAdminEmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 400));
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EmployeesCubit>().loadInitialData();
    });
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebouncer.call(() {
      if (mounted) context.read<EmployeesCubit>().updateSearchQuery(_searchController.text);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final cubit = context.read<EmployeesCubit>();
    final state = cubit.state;
    if (state.isLoadingMore || !state.hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      cubit.loadMoreEmployees();
    }
  }

  void _handleEmployeeTap(Employee employee) {
    final cubit = context.read<EmployeesCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: EmployeeProfileScreen(employee: employee),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: BlocBuilder<EmployeesCubit, EmployeesState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildHeader(state),
              _buildSearchBar(state),
              _buildFilterChips(state),
              Expanded(child: _buildList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(EmployeesState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الموظفون',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.totalCount} موظف',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
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

  Widget _buildSearchBar(EmployeesState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو الرقم أو البريد',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: _searchController.clear,
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips(EmployeesState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _FilterChip(
            icon: Icons.business_rounded,
            label: state.selectedDepartmentId == null
                ? 'كل الأقسام'
                : _departmentName(state),
            selected: state.selectedDepartmentId != null,
            onTap: () => _showDepartmentPicker(state),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            icon: Icons.toggle_on_outlined,
            label: state.selectedIsActive == null
                ? 'الحالة'
                : (state.selectedIsActive! ? 'نشط' : 'غير نشط'),
            selected: state.selectedIsActive != null,
            onTap: () => _showStatusPicker(state),
          ),
          const Spacer(),
          if (state.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  void _showDepartmentPicker(EmployeesState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('كل الأقسام'),
              trailing: state.selectedDepartmentId == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.read<EmployeesCubit>().applyFilters(
                      departmentId: null,
                      clearDepartment: true,
                      jobId: state.selectedJobId,
                      clearJob: state.selectedJobId == null,
                      isActive: state.selectedIsActive,
                      clearIsActive: state.selectedIsActive == null,
                    );
                Navigator.pop(context);
              },
            ),
            ...state.departments.map(
              (d) => ListTile(
                title: Text(d.name),
                trailing: state.selectedDepartmentId == d.id
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  context.read<EmployeesCubit>().applyFilters(
                        departmentId: d.id,
                        clearDepartment: false,
                        jobId: state.selectedJobId,
                        clearJob: state.selectedJobId == null,
                        isActive: state.selectedIsActive,
                        clearIsActive: state.selectedIsActive == null,
                      );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(EmployeesState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('الكل'),
              trailing: state.selectedIsActive == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.read<EmployeesCubit>().applyFilters(
                      departmentId: state.selectedDepartmentId,
                      clearDepartment: state.selectedDepartmentId == null,
                      jobId: state.selectedJobId,
                      clearJob: state.selectedJobId == null,
                      isActive: null,
                      clearIsActive: true,
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('نشط'),
              trailing: state.selectedIsActive == true
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.read<EmployeesCubit>().applyFilters(
                      departmentId: state.selectedDepartmentId,
                      clearDepartment: state.selectedDepartmentId == null,
                      jobId: state.selectedJobId,
                      clearJob: state.selectedJobId == null,
                      isActive: true,
                      clearIsActive: false,
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('غير نشط'),
              trailing: state.selectedIsActive == false
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.read<EmployeesCubit>().applyFilters(
                      departmentId: state.selectedDepartmentId,
                      clearDepartment: state.selectedDepartmentId == null,
                      jobId: state.selectedJobId,
                      clearJob: state.selectedJobId == null,
                      isActive: false,
                      clearIsActive: false,
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _departmentName(EmployeesState state) {
    for (final d in state.departments) {
      if (d.id == state.selectedDepartmentId) return d.name;
    }
    return 'قسم';
  }

  Widget _buildList(BuildContext context, EmployeesState state) {
    if (state.isLoading && state.employees.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.employees.isEmpty) {
      return _buildErrorState(state.error!);
    }
    if (state.employees.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'لا يوجد موظفون',
        message: 'لم يتم العثور على موظفين بالمعايير الحالية',
        iconColor: AppColors.primary,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent * 0.8) {
          final cubit = context.read<EmployeesCubit>();
          if (!cubit.state.isLoadingMore && cubit.state.hasMore) {
            cubit.loadMoreEmployees();
          }
        }
        return false;
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: state.employees.length +
            (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= state.employees.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final employee = state.employees[index];
          return _CompactEmployeeTile(
            employee: employee,
            onTap: () => _handleEmployeeTap(employee),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<EmployeesCubit>().loadInitialData(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEmployeeTile extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const _CompactEmployeeTile({
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  employee.initials,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (employee.position != null) ...[
                          Flexible(
                            child: Text(
                              employee.position!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (employee.department != null)
                          Flexible(
                            child: Text(
                              '• ${employee.department!}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (employee.isActive == false)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'غير نشط',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
