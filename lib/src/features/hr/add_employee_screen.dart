import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/departments.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/mixins/form_controller_mixin.dart';
import '../../shared/widgets/form_section_container.dart';
import '../../shared/widgets/form_section_header.dart';
import '../organization/cubit/organization_chart_cubit.dart';
import 'cubit/employees_cubit.dart';
import 'widgets/add_employee_header.dart';
import 'widgets/employee_job_info_section.dart';
import 'widgets/employee_personal_info_section.dart';
import 'widgets/employee_security_clearance_section.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen>
    with FormControllerMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _positionController;
  late TextEditingController _nationalIdController;
  late TextEditingController _securityClearanceController;
  late TextEditingController _genderController;

  List<String> _departments = Departments.mockDepartments;
  String? _selectedDepartment;
  DateTime? _birthDate;
  DateTime? _hireDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _positionController = TextEditingController();
    _nationalIdController = TextEditingController();
    _securityClearanceController = TextEditingController();
    _genderController = TextEditingController();

    _loadDepartments();

    registerControllers([
      _fullNameController,
      _phoneController,
      _emailController,
      _passwordController,
      _positionController,
      _nationalIdController,
      _securityClearanceController,
      _genderController,
    ]);
  }

  void _loadDepartments() {
    try {
      final orgCubit = context.read<OrganizationChartCubit>();
      final orgData = orgCubit.state.organizationData;
      if (orgData != null && orgData.departments.isNotEmpty) {
        setState(() {
          _departments = orgData.departments.map((d) => d.name).toList();
        });
      }
    } catch (_) {
      // Keep fallback mock departments.
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    if (!_formKey.currentState!.validate()) return;

    if (_fullNameController.text.trim().isEmpty) {
      CustomToast.showError('Full name is required');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      CustomToast.showError('Phone number is required');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      CustomToast.showError('Password is required');
      return;
    }

    setState(() => _isLoading = true);

    final employeesCubit = context.read<EmployeesCubit>();
    final success = await employeesCubit.createEmployee(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      email: _emailController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      gender: _genderController.text.trim(),
      departmentName: _selectedDepartment,
      positionName: _positionController.text.trim(),
      startDate: _hireDate ?? DateTime.now(),
      birthday: _birthDate,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      CustomToast.showError(
        employeesCubit.state.error ?? 'Failed to add employee',
      );
      return;
    }

    CustomToast.showSuccess('Employee added successfully');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AddEmployeeHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                          passwordController: _passwordController,
                          showPasswordField: true,
                          nationalIdController: _nationalIdController,
                          genderController: _genderController,
                          birthDate: _birthDate,
                          onBirthDateSelected: _selectBirthDate,
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
                            setState(() => _selectedDepartment = value);
                          },
                          positionController: _positionController,
                          hireDate: _hireDate,
                          onHireDateSelected: _selectHireDate,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FormSectionHeader(
                        title: 'Security Clearance',
                        icon: Icons.shield_outlined,
                      ),
                      const SizedBox(height: 16),
                      FormSectionContainer(
                        child: EmployeeSecurityClearanceSection(
                          securityClearanceController:
                              _securityClearanceController,
                        ),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: 'Add Employee',
                        isLoading: _isLoading,
                        onPressed: _handleSave,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
