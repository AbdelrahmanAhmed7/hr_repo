import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/utils/debouncer.dart';
import '../../shared/widgets/empty_state_widget.dart';
import 'add_employee_screen.dart';
import 'cubit/employees_cubit.dart';
import 'cubit/employees_state.dart';
import 'employee_profile_screen.dart';
import 'models/department_option.dart';
import 'models/employee.dart';
import 'models/job_title_option.dart';
import 'widgets/employee_card.dart';
import 'widgets/hr_screen_header.dart';

class HREmployeesScreen extends StatefulWidget {
  const HREmployeesScreen({super.key});

  @override
  State<HREmployeesScreen> createState() => _HREmployeesScreenState();
}

class _HREmployeesScreenState extends State<HREmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 500));
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EmployeesCubit>().loadInitialData();
      }
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
    final query = _searchController.text;
    if (mounted) {
      setState(() {});
    }
    _searchDebouncer.call(() {
      if (mounted) {
        context.read<EmployeesCubit>().updateSearchQuery(query);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final cubit = context.read<EmployeesCubit>();
    final state = cubit.state;
    if (state.isLoadingMore || !state.hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      cubit.loadMoreEmployees();
    }
  }

  Future<void> _loadEmployees() async {
    await context.read<EmployeesCubit>().refresh();
  }

  Future<void> _applyInlineFilters({
    int? departmentId,
    bool clearDepartment = false,
    int? jobId,
    bool clearJob = false,
    bool? isActive,
    bool clearIsActive = false,
  }) async {
    await context.read<EmployeesCubit>().applyFilters(
          departmentId: departmentId,
          clearDepartment: clearDepartment,
          jobId: jobId,
          clearJob: clearJob,
          isActive: isActive,
          clearIsActive: clearIsActive,
        );
  }

  void _handleEmployeeTap(Employee employee) {
    final employeesCubit = context.read<EmployeesCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: employeesCubit,
              child: EmployeeProfileScreen(employee: employee),
            ),
          ),
        )
        .then((result) {
      if (result == true) {
        _loadEmployees();
      }
    });
  }

  void _handleAddEmployee() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEmployeeScreen(),
          ),
        )
        .then((result) {
      if (result == true) {
        _loadEmployees();
      }
    });
  }

  Widget _buildDropdownField<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlDeck(EmployeesState state) {
    final activeFilterCount = [
      state.selectedDepartmentId,
      state.selectedJobId,
      state.selectedIsActive,
    ].where((value) => value != null).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة التحكم',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ابحث وفلتر الموظفين بسرعة من نفس الشاشة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      '$activeFilterCount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'فلتر نشط',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الهاتف أو البريد',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFF3F7FB),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricBadge(
                        icon: Icons.groups_rounded,
                        label: 'إجمالي النتائج',
                        value: '${state.totalCount}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBadge(
                        icon: Icons.view_agenda_outlined,
                        label: 'الصفحة',
                        value: '${state.pageNumber}/${state.totalPages}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdownField<int?>(
                  context: context,
                  label: 'القسم',
                  value: state.selectedDepartmentId,
                  icon: Icons.business_outlined,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('كل الأقسام'),
                    ),
                    ...state.departments.map(
                      (department) => DropdownMenuItem<int?>(
                        value: department.id,
                        child: Text(department.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _applyInlineFilters(
                      departmentId: value,
                      clearDepartment: value == null,
                      jobId: state.selectedJobId,
                      clearJob: state.selectedJobId == null,
                      isActive: state.selectedIsActive,
                      clearIsActive: state.selectedIsActive == null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdownField<int?>(
                  context: context,
                  label: 'المسمى الوظيفي',
                  value: state.selectedJobId,
                  icon: Icons.badge_outlined,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('كل الوظائف'),
                    ),
                    ...state.jobTitles.map(
                      (job) => DropdownMenuItem<int?>(
                        value: job.id,
                        child: Text(job.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _applyInlineFilters(
                      departmentId: state.selectedDepartmentId,
                      clearDepartment: state.selectedDepartmentId == null,
                      jobId: value,
                      clearJob: value == null,
                      isActive: state.selectedIsActive,
                      clearIsActive: state.selectedIsActive == null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdownField<bool?>(
                  context: context,
                  label: 'الحالة',
                  value: state.selectedIsActive,
                  icon: Icons.toggle_on_outlined,
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('الكل'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('نشط'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('غير نشط'),
                    ),
                  ],
                  onChanged: (value) {
                    _applyInlineFilters(
                      departmentId: state.selectedDepartmentId,
                      clearDepartment: state.selectedDepartmentId == null,
                      jobId: state.selectedJobId,
                      clearJob: state.selectedJobId == null,
                      isActive: value,
                      clearIsActive: value == null,
                    );
                  },
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (state.selectedDepartmentId != null)
                          _ActiveFilterChip(
                            label: _departmentName(
                              state.departments,
                              state.selectedDepartmentId!,
                            ),
                            onRemove: () {
                              _applyInlineFilters(
                                departmentId: null,
                                clearDepartment: true,
                                jobId: state.selectedJobId,
                                clearJob: state.selectedJobId == null,
                                isActive: state.selectedIsActive,
                                clearIsActive:
                                    state.selectedIsActive == null,
                              );
                            },
                          ),
                        if (state.selectedJobId != null)
                          _ActiveFilterChip(
                            label: _jobName(
                              state.jobTitles,
                              state.selectedJobId!,
                            ),
                            onRemove: () {
                              _applyInlineFilters(
                                departmentId: state.selectedDepartmentId,
                                clearDepartment:
                                    state.selectedDepartmentId == null,
                                jobId: null,
                                clearJob: true,
                                isActive: state.selectedIsActive,
                                clearIsActive:
                                    state.selectedIsActive == null,
                              );
                            },
                          ),
                        if (state.selectedIsActive != null)
                          _ActiveFilterChip(
                            label: state.selectedIsActive!
                                ? 'الموظفون النشطون'
                                : 'الموظفون غير النشطين',
                            onRemove: () {
                              _applyInlineFilters(
                                departmentId: state.selectedDepartmentId,
                                clearDepartment:
                                    state.selectedDepartmentId == null,
                                jobId: state.selectedJobId,
                                clearJob: state.selectedJobId == null,
                                isActive: null,
                                clearIsActive: true,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: activeFilterCount == 0
                            ? null
                            : () => context.read<EmployeesCubit>().clearFilters(),
                        icon: const Icon(Icons.layers_clear_outlined),
                        label: const Text('مسح الكل'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loadEmployees,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('تحديث'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddEmployee,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'إضافة موظف',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<EmployeesCubit, EmployeesState>(
        builder: (context, state) {
          if (state.isLoading && state.employees.isEmpty) {
            return const Scaffold(
              backgroundColor: AppColors.backgroundSecondary,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadEmployees,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: HRScreenHeader(
                    title: 'إدارة الموظفين',
                    subtitle: 'وصول أسرع للبيانات والفلاتر من شاشة واحدة',
                    icon: Icons.people_outlined,
                    showBackButton: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${state.totalCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _buildControlDeck(state),
                  ),
                ),
                if (state.error != null && state.employees.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorState(state.error!),
                  )
                else if (state.employees.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final employee = state.employees[index];
                          return EmployeeCard(
                            employee: employee,
                            onTap: () => _handleEmployeeTap(employee),
                          );
                        },
                        childCount: state.employees.length,
                      ),
                    ),
                  ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (!state.hasMore && state.employees.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
                      child: Center(
                        child: Text(
                          'تم عرض كل الموظفين',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _departmentName(List<DepartmentOption> departments, int id) {
    for (final department in departments) {
      if (department.id == id) return department.name;
    }
    return 'قسم #$id';
  }

  String _jobName(List<JobTitleOption> jobTitles, int id) {
    for (final job in jobTitles) {
      if (job.id == id) return job.displayName;
    }
    return 'وظيفة #$id';
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<EmployeesCubit>().loadInitialData(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'لا يوجد موظفون',
      message: 'لم يتم العثور على موظفين بالمعايير الحالية',
      iconColor: AppColors.primary,
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;

  const _ActiveFilterChip({
    required this.label,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
