import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../hr/models/department_option.dart';
import '../../hr/models/employee.dart';
import '../../hr/services/employees_api_service.dart';
import '../models/public_holiday_model.dart';
import '../models/holiday_exception_model.dart';
import '../repository/public_holiday_repository.dart';

class HolidayExceptionsDialog extends StatefulWidget {
  final PublicHolidayModel holiday;
  final PublicHolidayRepository repository;

  const HolidayExceptionsDialog({
    super.key,
    required this.holiday,
    required this.repository,
  });

  @override
  State<HolidayExceptionsDialog> createState() =>
      _HolidayExceptionsDialogState();
}

class _HolidayExceptionsDialogState extends State<HolidayExceptionsDialog> {
  List<HolidayExceptionModel> _exceptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExceptions();
  }

  Future<void> _loadExceptions() async {
    try {
      final exceptions = await widget.repository.getHolidayExceptions(
        widget.holiday.id,
      );
      setState(() {
        _exceptions = exceptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في تحميل الاستثناءات: $e')));
      }
    }
  }

  Future<void> _deleteException(int exceptionId) async {
    try {
      await widget.repository.deleteHolidayException(exceptionId);
      await _loadExceptions();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الاستثناء بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في حذف الاستثناء: $e')));
      }
    }
  }

  void _showAddExceptionDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExceptionDialog(
        holidayId: widget.holiday.id,
        repository: widget.repository,
        onAdded: _loadExceptions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'استثناءات الإجازة',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.holiday.nameAr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: _showAddExceptionDialog,
            tooltip: 'إضافة استثناء',
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _exceptions.isEmpty
            ? _EmptyState(onAdd: _showAddExceptionDialog)
            : ListView.builder(
                itemCount: _exceptions.length,
                itemBuilder: (context, index) {
                  final exception = _exceptions[index];
                  return _ExceptionTile(
                    exception: exception,
                    onDelete: () => _deleteException(exception.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد استثناءات مسجلة',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('إضافة استثناء'),
          ),
        ],
      ),
    );
  }
}

class _ExceptionTile extends StatelessWidget {
  final HolidayExceptionModel exception;
  final VoidCallback onDelete;

  const _ExceptionTile({required this.exception, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasEmployee = exception.employeeId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasEmployee
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasEmployee ? Icons.person_outline : Icons.apartment,
              color: hasEmployee ? AppColors.primary : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasEmployee
                      ? exception.employeeName ?? 'موظف غير معروف'
                      : exception.departmentName ?? 'قسم غير معروف',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasEmployee ? 'استثناء فردي' : 'استثناء للقسم',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'حذف الاستثناء',
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الاستثناء'),
        content: const Text('هل أنت متأكد من حذف هذا الاستثناء؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _AddExceptionDialog extends StatefulWidget {
  final int holidayId;
  final PublicHolidayRepository repository;
  final VoidCallback onAdded;

  const _AddExceptionDialog({
    required this.holidayId,
    required this.repository,
    required this.onAdded,
  });

  @override
  State<_AddExceptionDialog> createState() => _AddExceptionDialogState();
}

class _AddExceptionDialogState extends State<_AddExceptionDialog> {
  bool _isForEmployee = true;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _errorMessage;

  // Data
  List<Employee> _employees = [];
  List<DepartmentOption> _departments = [];

  // Selected values
  String? _selectedEmployeeId;
  int? _selectedDepartmentId;

  late final EmployeesApiService _employeesService;

  @override
  void initState() {
    super.initState();
    _employeesService = getIt<EmployeesApiService>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // Load both employees and departments in parallel
      final results = await Future.wait([
        _employeesService.getEmployees(pageSize: 500, isActive: true),
        _employeesService.getDepartments(),
      ]);

      final employeesResponse = results[0] as dynamic;
      final departments = results[1] as List<DepartmentOption>;

      setState(() {
        _employees = employeesResponse.items as List<Employee>;
        _departments = departments;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = 'فشل في تحميل البيانات: $e';
      });
    }
  }

  Future<void> _addException() async {
    if (_isForEmployee && _selectedEmployeeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار موظف')));
      return;
    }

    if (!_isForEmployee && _selectedDepartmentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار قسم')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedEmployee = _isForEmployee
          ? _employees.firstWhere((e) => e.id == _selectedEmployeeId)
          : null;
      final selectedDepartment = !_isForEmployee
          ? _departments.firstWhere((d) => d.id == _selectedDepartmentId)
          : null;

      final exception = HolidayExceptionModel(
        id: 0,
        publicHolidayId: widget.holidayId,
        employeeId: _isForEmployee ? _selectedEmployeeId : null,
        employeeName: selectedEmployee?.fullName,
        departmentId: _isForEmployee ? null : _selectedDepartmentId,
        departmentName: selectedDepartment?.name,
      );

      await widget.repository.addHolidayException(widget.holidayId, exception);

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في إضافة الاستثناء: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة استثناء'),
      content: SizedBox(
        width: 400,
        child: _isLoadingData
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل البيانات...'),
                  ],
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadData,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle between employee and department
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('موظف'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('قسم'),
                        icon: Icon(Icons.apartment),
                      ),
                    ],
                    selected: {_isForEmployee},
                    onSelectionChanged: (selected) {
                      setState(() {
                        _isForEmployee = selected.first;
                        _selectedEmployeeId = null;
                        _selectedDepartmentId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Employee Dropdown
                  if (_isForEmployee)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEmployeeId,
                      decoration: InputDecoration(
                        labelText: 'اختيار الموظف',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      isExpanded: true,
                      items: _employees.map((employee) {
                        return DropdownMenuItem<String>(
                          value: employee.id,
                          child: Text(
                            employee.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedEmployeeId = value);
                      },
                    ),

                  // Department Dropdown
                  if (!_isForEmployee)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDepartmentId,
                      decoration: InputDecoration(
                        labelText: 'اختيار القسم',
                        prefixIcon: const Icon(Icons.apartment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      isExpanded: true,
                      items: _departments.map((department) {
                        return DropdownMenuItem<int>(
                          value: department.id,
                          child: Text(
                            department.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDepartmentId = value);
                      },
                    ),

                  const SizedBox(height: 16),
                  Text(
                    _isForEmployee
                        ? 'سيتم استثناء الموظف المحدد من الإجازة العامة'
                        : 'سيتم استثناء جميع موظفي القسم المحدد من الإجازة العامة',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isLoading || _isLoadingData ? null : _addException,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('إضافة'),
        ),
      ],
    );
  }
}
