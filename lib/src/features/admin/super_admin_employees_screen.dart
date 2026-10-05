import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/hr/cubit/employees_cubit.dart';
import '../../features/hr/cubit/employees_state.dart';
import '../../features/hr/employee_profile_screen.dart';
import '../../features/hr/models/employee.dart';
import '../../shared/utils/debouncer.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../shared/widgets/shimmer_loading.dart';

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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الموظفون',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.totalCount} موظف',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_hasActiveFilters(state))
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('مسح'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters(EmployeesState state) {
    return state.selectedDepartmentId != null ||
        state.selectedIsActive != true;
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<EmployeesCubit>().applyFilters(
          clearDepartment: true,
          isActive: true,
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                    selected: state.selectedIsActive != true,
                    onTap: () => _showStatusPicker(state),
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
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
      return _buildLoadingShimmer();
    }
    if (state.error != null && state.employees.isEmpty) {
      return ErrorStateWidget(
        error: state.error!,
        buttonLabel: 'إعادة المحاولة',
        onRetry: () => context.read<EmployeesCubit>().loadInitialData(),
      );
    }
    if (state.employees.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'لا يوجد موظفون',
        message: 'لم يتم العثور على موظفين بالمعايير الحالية',
        iconColor: AppColors.textTertiary,
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(
            children: [
              Text(
                '${state.totalCount} موظف',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state.isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<EmployeesCubit>().loadInitialData(),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount:
                  state.employees.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= state.employees.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child:
                        Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final employee = state.employees[index];
                return _CompactEmployeeTile(
                  employee: employee,
                  onTap: () => _handleEmployeeTap(employee),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const ShimmerPlaceholder(
                  width: 46,
                  height: 46,
                  borderRadius: 23,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(
                        width: 140 + (index % 3) * 30.0,
                        height: 14,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 8),
                      const ShimmerPlaceholder(
                        width: 100,
                        height: 10,
                        borderRadius: 4,
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
    final isActive = employee.isActive != false;
    final statusColor = isActive ? AppColors.success : AppColors.error;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.backgroundSecondary,
                    child: Text(
                      employee.initials,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isActive ? 'نشط' : 'غير نشط',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (employee.position != null &&
                            employee.position!.isNotEmpty) ...[
                          const Icon(
                            Icons.work_outline_rounded,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
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
                        ],
                        if (employee.position != null &&
                            employee.position!.isNotEmpty &&
                            employee.department != null &&
                            employee.department!.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style:
                                  TextStyle(color: AppColors.textTertiary),
                            ),
                          ),
                        if (employee.department != null &&
                            employee.department!.isNotEmpty)
                          Flexible(
                            child: Text(
                              employee.department!,
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
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
