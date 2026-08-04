import 'package:flutter/material.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import 'models/employee.dart';
import 'repository/employees_repository.dart';

class HRDepartmentsScreen extends StatefulWidget {
  const HRDepartmentsScreen({super.key});

  @override
  State<HRDepartmentsScreen> createState() => _HRDepartmentsScreenState();
}

class _HRDepartmentsScreenState extends State<HRDepartmentsScreen> {
  final EmployeesRepository _repository = getIt<EmployeesRepository>();

  bool _isLoading = true;
  String? _error;
  List<_DepartmentSummary> _departments = const [];
  int? _expandedDepartmentId;
  final Map<int, bool> _employeesLoading = {};
  final Map<int, List<Employee>> _departmentEmployees = {};

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final departments = await _fetchAllDepartments();
      final summaries = await Future.wait(
        departments.map((department) async {
          final employeesPage = await _repository.getEmployees(
            pageNumber: 1,
            pageSize: 1,
            departmentId: department.id,
            isActive: true,
          );

          return _DepartmentSummary(
            id: department.id,
            name: department.name,
            employeeCount: employeesPage.totalCount,
          );
        }),
      );

      summaries.sort((a, b) => b.employeeCount.compareTo(a.employeeCount));

      if (!mounted) return;
      setState(() {
        _departments = summaries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'تعذر تحميل الأقسام حاليًا';
      });
    }
  }

  Future<List<_DepartmentSummary>> _fetchAllDepartments() async {
    var pageNumber = 1;
    const pageSize = 50;
    final results = <_DepartmentSummary>[];

    while (true) {
      final page = await _repository.getDepartments(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );

      if (page.isEmpty) break;

      results.addAll(
        page.map(
          (item) => _DepartmentSummary(
            id: item.id,
            name: item.name,
            employeeCount: 0,
          ),
        ),
      );

      if (page.length < pageSize) break;
      pageNumber++;
    }

    return results;
  }

  Future<void> _toggleDepartment(_DepartmentSummary department) async {
    if (_expandedDepartmentId == department.id) {
      setState(() {
        _expandedDepartmentId = null;
      });
      return;
    }

    setState(() {
      _expandedDepartmentId = department.id;
    });

    if (_departmentEmployees.containsKey(department.id)) return;

    setState(() {
      _employeesLoading[department.id] = true;
    });

    try {
      final employeesPage = await _repository.getEmployees(
        pageNumber: 1,
        pageSize: 20,
        departmentId: department.id,
        isActive: true,
      );

      if (!mounted) return;
      setState(() {
        _departmentEmployees[department.id] = employeesPage.items;
        _employeesLoading[department.id] = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _employeesLoading[department.id] = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحميل موظفي القسم')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalEmployees = _departments.fold<int>(
      0,
      (sum, department) => sum + department.employeeCount,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDepartments,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الأقسام',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'اختر أي قسم لعرض موظفيه بشكل مباشر',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DepartmentTopMetric(
                                label: 'عدد الأقسام',
                                value: '${_departments.length}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DepartmentTopMetric(
                                label: 'إجمالي الموظفين',
                                value: '$totalEmployees',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _loadDepartments,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  sliver: SliverList.separated(
                    itemCount: _departments.length,
                    itemBuilder: (context, index) {
                      final department = _departments[index];
                      return _DepartmentCard(
                        department: department,
                        isExpanded: _expandedDepartmentId == department.id,
                        isLoadingEmployees:
                            _employeesLoading[department.id] ?? false,
                        employees:
                            _departmentEmployees[department.id] ?? const [],
                        onTap: () => _toggleDepartment(department),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentTopMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DepartmentTopMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final _DepartmentSummary department;
  final bool isExpanded;
  final bool isLoadingEmployees;
  final List<Employee> employees;
  final VoidCallback onTap;

  const _DepartmentCard({
    required this.department,
    required this.isExpanded,
    required this.isLoadingEmployees,
    required this.employees,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpanded ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isExpanded
                              ? 'اضغط لإخفاء موظفي القسم'
                              : 'اضغط لعرض موظفي القسم',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${department.employeeCount} موظف',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (isLoadingEmployees)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  )
                else if (employees.isEmpty)
                  Text(
                    'لا يوجد موظفون داخل هذا القسم حاليًا',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Column(
                    children: employees
                        .map(
                          (employee) =>
                              _DepartmentEmployeeTile(employee: employee),
                        )
                        .toList(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentEmployeeTile extends StatelessWidget {
  final Employee employee;

  const _DepartmentEmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryTint,
              child: Text(
                employee.initials,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.position ?? employee.role ?? employee.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (employee.isActive ?? false)
                    ? AppColors.successTint
                    : AppColors.errorTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                (employee.isActive ?? false) ? 'نشط' : 'غير نشط',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: (employee.isActive ?? false)
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentSummary {
  final int id;
  final String name;
  final int employeeCount;

  const _DepartmentSummary({
    required this.id,
    required this.name,
    required this.employeeCount,
  });
}
