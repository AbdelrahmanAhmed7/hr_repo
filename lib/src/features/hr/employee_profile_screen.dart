import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/form_section_container.dart';
import '../../shared/widgets/form_section_header.dart';
import 'cubit/employees_cubit.dart';
import 'employee_attendance_report_screen.dart';
import 'employee_edit_screen.dart';
import 'models/employee.dart';
import 'widgets/employee_profile_header.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeProfileScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  bool _isLoading = true;
  bool _isOpeningEdit = false;
  String? _error;
  Employee? _details;

  Employee get _employee => _details ?? widget.employee;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cubit = context.read<EmployeesCubit>();
      final employee = await cubit.getEmployeeDetails(widget.employee.id);

      if (!mounted) return;
      setState(() {
        _details = employee;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openEditScreen() async {
    if (_isOpeningEdit) return;
    setState(() => _isOpeningEdit = true);

    final cubit = context.read<EmployeesCubit>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: EmployeeEditScreen(employee: _employee),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isOpeningEdit = false);

    if (result == true) {
      await _loadEmployee();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  void _openAttendanceReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmployeeAttendanceReportScreen(employee: _employee),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatAmount(double? value) {
    if (value == null) return '--';
    final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return '$text EGP';
  }

  String _workTypeLabel(int? value) {
    switch (value) {
      case 1:
        return 'Onsite';
      case 2:
        return 'Remote';
      case 3:
        return 'Hybrid';
      case 4:
        return 'Part-time';
      default:
        return '--';
    }
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
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!, onRetry: _loadEmployee),
                    const SizedBox(height: 16),
                  ],
                  _OverviewCard(employee: _employee),
                  const SizedBox(height: 20),
                  FormSectionHeader(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  FormSectionContainer(
                    child: _KeyValueList(
                      items: [
                        MapEntry('Full Name', _employee.fullName),
                        MapEntry('Phone', _employee.phone),
                        MapEntry('Email', _employee.email),
                        MapEntry('National ID', _employee.nationalId ?? '--'),
                        MapEntry('Passport', _employee.passportNumber ?? '--'),
                        MapEntry('Gender', _employee.gender ?? '--'),
                        MapEntry('Birth Date', _formatDate(_employee.birthDate)),
                        MapEntry('Nationality', _employee.nationalityName ?? '--'),
                        MapEntry('Marital Status', _employee.maritalStatusName ?? '--'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FormSectionHeader(
                    title: 'Job Information',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 12),
                  FormSectionContainer(
                    child: _KeyValueList(
                      items: [
                        MapEntry('Employee ID', _employee.id),
                        MapEntry('Department', _employee.department ?? '--'),
                        MapEntry('Position', _employee.position ?? '--'),
                        MapEntry('Job Title Name', _employee.jobTitleName ?? '--'),
                        MapEntry('Manager', _employee.managerName ?? '--'),
                        MapEntry('Branch', _employee.branchName ?? '--'),
                        MapEntry('Employment Mode', _employee.employmentModeName ?? '--'),
                        MapEntry('Hire Date', _formatDate(_employee.hireDate)),
                        MapEntry('Contract End', _formatDate(_employee.contractEndDate)),
                        MapEntry('Work Type', _workTypeLabel(_employee.workType)),
                        MapEntry('Role', _employee.role ?? '--'),
                        MapEntry('Employee Code', _employee.employeeCode ?? '--'),
                        MapEntry('Machine Code', _employee.machineCode ?? '--'),
                        MapEntry('Fingerprint Key', _employee.fingerprintKey ?? '--'),
                        MapEntry('Security Clearance', _employee.securityClearance ?? '--'),
                        MapEntry(
                          'Status',
                          _employee.isActive == null
                              ? '--'
                              : (_employee.isActive! ? 'Active' : 'Inactive'),
                        ),
                        MapEntry(
                          'Registration',
                          _employee.isPending == null
                              ? '--'
                              : (_employee.isPending! ? 'Pending' : 'Approved'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FormSectionHeader(
                    title: 'Contact & Address',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  FormSectionContainer(
                    child: _KeyValueList(
                      items: [
                        MapEntry('Address (AR)', _employee.addressAr ?? '--'),
                        MapEntry('Address (EN)', _employee.addressEn ?? '--'),
                        MapEntry('Governorate', _employee.governorateName ?? '--'),
                        MapEntry('City', _employee.cityName ?? '--'),
                        MapEntry('Company Phone', _employee.companyPhoneNumber ?? '--'),
                        MapEntry('Company Email', _employee.companyEmail ?? '--'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FormSectionHeader(
                    title: 'Finance & Bank',
                    icon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 12),
                  FormSectionContainer(
                    child: _KeyValueList(
                      items: [
                        MapEntry('Gross Salary', _formatAmount(_employee.grossSalary)),
                        MapEntry('Bank Name', _employee.bankInfo?.bankName ?? '--'),
                        MapEntry('Account Number', _employee.bankInfo?.accountNumber ?? '--'),
                        MapEntry('IBAN', _employee.bankInfo?.ibanNumber ?? '--'),
                        MapEntry('SWIFT/BIC', _employee.bankInfo?.swiftBicCode ?? '--'),
                        MapEntry('Branch Code', _employee.bankInfo?.branchCode ?? '--'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FormSectionHeader(
                    title: 'Education',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 12),
                  FormSectionContainer(
                    child: _EducationList(educations: _employee.educations),
                  ),
                  const SizedBox(height: 20),
                  FormSectionHeader(
                    title: 'Attachments',
                    icon: Icons.attach_file_rounded,
                  ),
                  const SizedBox(height: 12),
                  FormSectionContainer(
                    child: _AttachmentList(attachments: _employee.attachments),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Edit Employee',
                    isLoading: _isOpeningEdit,
                    onPressed: _openEditScreen,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openAttendanceReport,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Attendance Report'),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Employee employee;

  const _OverviewCard({required this.employee});

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Expanded(
            child: _MiniMetric(
              label: 'Department',
              value: employee.department ?? '--',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniMetric(
              label: 'Position',
              value: employee.position ?? '--',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniMetric(
              label: 'Status',
              value: employee.isActive == true ? 'Active' : 'Inactive',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueList extends StatelessWidget {
  final List<MapEntry<String, String>> items;

  const _KeyValueList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      item.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EducationList extends StatelessWidget {
  final List<EmployeeEducation> educations;

  const _EducationList({required this.educations});

  @override
  Widget build(BuildContext context) {
    if (educations.isEmpty) {
      return const Text('No education records available');
    }

    return Column(
      children: educations
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.universityName ?? '--'),
              subtitle: Text(
                [
                  if (item.degree?.isNotEmpty == true) 'Degree: ${item.degree}',
                  if (item.finalGrade?.isNotEmpty == true) 'Grade: ${item.finalGrade}',
                  if (item.graduationYear != null) 'Year: ${item.graduationYear!.year}',
                ].join(' | '),
              ),
              leading: const Icon(Icons.school_outlined),
            ),
          )
          .toList(),
    );
  }
}

class _AttachmentList extends StatelessWidget {
  final List<EmployeeAttachment> attachments;

  const _AttachmentList({required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Text('No attachments available');
    }

    return Column(
      children: attachments
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.originalFileName ?? 'Attachment'),
              subtitle: Text(
                [
                  if (item.contentType?.isNotEmpty == true) item.contentType!,
                  if (item.fileSize != null) '${item.fileSize} bytes',
                ].join(' | '),
              ),
              trailing: item.fileUrl?.isNotEmpty == true
                  ? IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: item.fileUrl!));
                        if (!context.mounted) return;
                        CustomToast.showSuccess('Attachment URL copied');
                      },
                    )
                  : null,
              leading: const Icon(Icons.insert_drive_file_outlined),
            ),
          )
          .toList(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

