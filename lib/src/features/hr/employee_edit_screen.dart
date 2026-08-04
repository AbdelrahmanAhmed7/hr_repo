import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/departments.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/mixins/form_controller_mixin.dart';
import '../../shared/widgets/form_section_container.dart';
import '../../shared/widgets/form_section_header.dart';
import '../organization/cubit/organization_chart_cubit.dart';
import 'cubit/employees_cubit.dart';
import 'employee_attendance_report_screen.dart';
import 'models/employee.dart';
import 'repository/employees_repository.dart';
import 'widgets/employee_job_info_section.dart';
import 'widgets/employee_personal_info_section.dart';
import 'widgets/employee_profile_actions.dart';
import 'widgets/employee_profile_header.dart';
import 'widgets/employee_security_clearance_section.dart';

class EmployeeEditScreen extends StatefulWidget {
  final Employee employee;
  final bool isReadOnly;

  const EmployeeEditScreen({
    super.key,
    required this.employee,
    this.isReadOnly = false,
  });

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen>
    with FormControllerMixin {
  late final EmployeesRepository _employeesRepository;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _positionController;
  late TextEditingController _nationalIdController;
  late TextEditingController _securityClearanceController;
  late TextEditingController _genderController;

  List<String> _departments = Departments.mockDepartments;
  String? _selectedDepartment;
  DateTime? _birthDate;
  DateTime? _hireDate;

  bool _isSaving = false;
  bool _isProfileLoading = true;
  String? _profileError;
  Employee? _employeeDetails;

  Employee get _employee => _employeeDetails ?? widget.employee;

  @override
  void initState() {
    super.initState();
    _employeesRepository = getIt<EmployeesRepository>();
    _initializeControllers(widget.employee);
    _loadDepartments();
    _loadEmployeeDetails();
  }

  void _initializeControllers(Employee employee) {
    _fullNameController = TextEditingController(text: employee.fullName);
    _phoneController = TextEditingController(text: employee.phone);
    _emailController = TextEditingController(text: employee.email);
    _positionController = TextEditingController(text: employee.position ?? '');
    _nationalIdController = TextEditingController(text: employee.nationalId ?? '');
    _securityClearanceController =
        TextEditingController(text: employee.securityClearance ?? '');
    _genderController = TextEditingController(text: employee.gender ?? '');

    _selectedDepartment = employee.department;
    _hireDate = employee.hireDate;
    _birthDate = employee.birthDate;

    registerControllers([
      _fullNameController,
      _phoneController,
      _emailController,
      _positionController,
      _nationalIdController,
      _securityClearanceController,
      _genderController,
    ]);
  }

  void _syncControllers(Employee employee) {
    _fullNameController.text = employee.fullName;
    _phoneController.text = employee.phone;
    _emailController.text = employee.email;
    _positionController.text = employee.position ?? '';
    _nationalIdController.text = employee.nationalId ?? '';
    _securityClearanceController.text = employee.securityClearance ?? '';
    _genderController.text = employee.gender ?? '';

    _selectedDepartment = employee.department;
    _hireDate = employee.hireDate;
    _birthDate = employee.birthDate;
  }

  Future<void> _loadEmployeeDetails() async {
    setState(() {
      _isProfileLoading = true;
      _profileError = null;
    });

    try {
      final details = await _employeesRepository.getEmployeeDetails(widget.employee.id);
      if (!mounted) return;

      setState(() {
        _employeeDetails = details;
        _syncControllers(details);
        _isProfileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProfileLoading = false;
        _profileError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _loadDepartments() {
    try {
      final orgCubit = context.read<OrganizationChartCubit>();
      final orgData = orgCubit.state.organizationData;

      if (orgData != null && orgData.departments.isNotEmpty) {
        final uniqueDepartments = LinkedHashSet<String>.from(
          orgData.departments
              .map((department) => department.name.trim())
              .where((name) => name.isNotEmpty),
        ).toList();

        setState(() {
          _departments = uniqueDepartments;
          if (_selectedDepartment != null &&
              !_departments.contains(_selectedDepartment)) {
            _selectedDepartment = null;
          }
        });
      }
    } catch (_) {
      // Keep fallback departments.
    }
  }

  Future<void> _selectBirthDate() async {
    if (widget.isReadOnly) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Select birth date',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _selectHireDate() async {
    if (widget.isReadOnly) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select hire date',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
    );

    if (picked != null) {
      setState(() => _hireDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_fullNameController.text.trim().isEmpty) {
      CustomToast.showError('Full name is required');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      CustomToast.showError('Phone number is required');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      CustomToast.showError('Email is required');
      return;
    }

    setState(() => _isSaving = true);

    final employeesCubit = context.read<EmployeesCubit>();
    final updatedEmployee = await employeesCubit.updateEmployeeRemote(
      employeeId: _employee.id,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      gender: _genderController.text.trim(),
      departmentName: _selectedDepartment,
      positionName: _positionController.text.trim(),
      startDate: _hireDate,
      birthday: _birthDate,
      isActive: _employee.isActive,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (updatedEmployee == null) {
      CustomToast.showError(employeesCubit.state.error ?? 'Failed to update employee. Please try again.');
      return;
    }

    setState(() {
      _employeeDetails = updatedEmployee;
      _syncControllers(updatedEmployee);
    });

    CustomToast.showSuccess('Employee updated successfully');
    Navigator.of(context).pop(true);
  }

  void _handleViewAttendanceReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeAttendanceReportScreen(employee: _employee),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: EmployeeProfileHeader(employee: _employee),
          ),
          if (_isProfileLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_profileError != null) ...[
                    _ProfileErrorBanner(
                      message: _profileError!,
                      onRetry: _loadEmployeeDetails,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _ProfileOverviewCard(employee: _employee),
                  const SizedBox(height: 24),
                  FormSectionHeader(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  FormSectionContainer(
                    child: EmployeePersonalInfoSection(
                      fullNameController: _fullNameController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      nationalIdController: _nationalIdController,
                      genderController: _genderController,
                      birthDate: _birthDate,
                      onBirthDateSelected: _selectBirthDate,
                      isReadOnly: widget.isReadOnly,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionHeader(
                    title: 'Job Information',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 16),
                  FormSectionContainer(
                    child: EmployeeJobInfoSection(
                      selectedDepartment: _selectedDepartment,
                      departments: _departments,
                      onDepartmentChanged: (value) {
                        if (!widget.isReadOnly) {
                          setState(() => _selectedDepartment = value);
                        }
                      },
                      positionController: _positionController,
                      hireDate: _hireDate,
                      onHireDateSelected: _selectHireDate,
                      isReadOnly: widget.isReadOnly,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionHeader(
                    title: 'Additional Details',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  FormSectionContainer(
                    child: _EmployeeDetailsGrid(employee: _employee),
                  ),
                  const SizedBox(height: 24),
                  FormSectionHeader(
                    title: 'Security Clearance',
                    icon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 16),
                  FormSectionContainer(
                    child: EmployeeSecurityClearanceSection(
                      securityClearanceController: _securityClearanceController,
                      isReadOnly: widget.isReadOnly,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionHeader(
                    title: 'Bank Information',
                    icon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 16),
                  FormSectionContainer(
                    child: _EmployeeBankInfoSection(bankInfo: _employee.bankInfo),
                  ),
                  const SizedBox(height: 24),
                  FormSectionHeader(
                    title: 'Education',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 16),
                  FormSectionContainer(
                    child: _EmployeeEducationsSection(educations: _employee.educations),
                  ),
                  const SizedBox(height: 24),
                  FormSectionHeader(
                    title: 'Attachments',
                    icon: Icons.attach_file_rounded,
                  ),
                  const SizedBox(height: 16),
                  FormSectionContainer(
                    child: _EmployeeAttachmentsSection(attachments: _employee.attachments),
                  ),
                  const SizedBox(height: 24),
                  EmployeeProfileActions(
                    isLoading: _isSaving,
                    onSave: widget.isReadOnly ? null : _handleSave,
                    onViewAttendanceReport: _handleViewAttendanceReport,
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  final Employee employee;

  const _ProfileOverviewCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, String>>[
      MapEntry('Employee Code', employee.employeeCode ?? '--'),
      MapEntry('Department', employee.department ?? '--'),
      MapEntry('Position', employee.position ?? '--'),
      MapEntry(
        'Status',
        employee.isActive == null ? '--' : (employee.isActive! ? 'Active' : 'Inactive'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1734), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: entries
            .map(
              (entry) => Container(
                width: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmployeeDetailsGrid extends StatelessWidget {
  final Employee employee;

  const _EmployeeDetailsGrid({required this.employee});

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String?>>[
      MapEntry('National ID', employee.nationalId),
      MapEntry('Machine Code', employee.machineCode),
      MapEntry('Manager', employee.managerName),
      MapEntry('Marital Status', employee.maritalStatusName),
      MapEntry('Nationality', employee.nationalityName),
      MapEntry('Employment Mode', employee.employmentModeName),
      MapEntry('Branch', employee.branchName),
      MapEntry('Governorate', employee.governorateName),
      MapEntry('City', employee.cityName),
      MapEntry('Company Phone', employee.companyPhoneNumber),
      MapEntry('Company Email', employee.companyEmail),
      MapEntry('Passport', employee.passportNumber),
      MapEntry('Address', employee.addressAr ?? employee.addressEn),
      MapEntry(
        'Gross Salary',
        employee.grossSalary == null ? null : '${employee.grossSalary}',
      ),
      MapEntry(
        'Contract End',
        employee.contractEndDate == null
            ? null
            : '${employee.contractEndDate!.year}-${employee.contractEndDate!.month.toString().padLeft(2, '0')}-${employee.contractEndDate!.day.toString().padLeft(2, '0')}',
      ),
      MapEntry('Role', employee.role),
    ].where((entry) => entry.value != null && entry.value!.trim().isNotEmpty).toList();

    if (items.isEmpty) {
      return const _InfoPlaceholder(message: 'No additional details available');
    }

    return Column(
      children: items
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InfoRow(label: entry.key, value: entry.value!),
            ),
          )
          .toList(),
    );
  }
}

class _EmployeeBankInfoSection extends StatelessWidget {
  final EmployeeBankInfo? bankInfo;

  const _EmployeeBankInfoSection({required this.bankInfo});

  @override
  Widget build(BuildContext context) {
    if (bankInfo == null) {
      return const _InfoPlaceholder(message: 'No bank information available');
    }

    final items = <MapEntry<String, String?>>[
      MapEntry('Bank Name', bankInfo!.bankName),
      MapEntry('Account Number', bankInfo!.accountNumber),
      MapEntry('IBAN', bankInfo!.ibanNumber),
      MapEntry('SWIFT/BIC', bankInfo!.swiftBicCode),
      MapEntry('Branch Code', bankInfo!.branchCode),
    ].where((entry) => entry.value != null && entry.value!.trim().isNotEmpty).toList();

    if (items.isEmpty) {
      return const _InfoPlaceholder(message: 'No bank information available');
    }

    return Column(
      children: items
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InfoRow(label: entry.key, value: entry.value!),
            ),
          )
          .toList(),
    );
  }
}

class _EmployeeEducationsSection extends StatelessWidget {
  final List<EmployeeEducation> educations;

  const _EmployeeEducationsSection({required this.educations});

  @override
  Widget build(BuildContext context) {
    if (educations.isEmpty) {
      return const _InfoPlaceholder(message: 'No education records available');
    }

    return Column(
      children: educations
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.universityName ?? '--',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (item.degree?.isNotEmpty == true) 'Degree: ${item.degree}',
                        if (item.finalGrade?.isNotEmpty == true) 'Grade: ${item.finalGrade}',
                        if (item.graduationYear != null) 'Graduation: ${item.graduationYear!.year}',
                      ].join(' | '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmployeeAttachmentsSection extends StatelessWidget {
  final List<EmployeeAttachment> attachments;

  const _EmployeeAttachmentsSection({required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const _InfoPlaceholder(message: 'No attachments available');
    }

    return Column(
      children: attachments
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.originalFileName ?? 'Attachment',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (item.contentType?.isNotEmpty == true) item.contentType!,
                        if (item.fileSize != null) '${item.fileSize} bytes',
                      ].join(' | '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (item.fileUrl?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        item.fileUrl!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPlaceholder extends StatelessWidget {
  final String message;

  const _InfoPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

