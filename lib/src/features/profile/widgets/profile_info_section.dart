import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_picker_helper.dart';
import '../../home/models/employee_info.dart';
import '../../../shared/components/custom_text_field.dart';
import '../../../shared/widgets/date_picker_field.dart';
import '../../attendance/utils/attendance_formatters.dart';

class ProfileInfoSection extends StatefulWidget {
  final EmployeeInfo employeeInfo;
  final bool isEditMode;
  final TextEditingController? nameController;
  final TextEditingController? phoneController;
  final TextEditingController? emailController;
  final TextEditingController? nationalIdController;
  final TextEditingController? genderController;
  final DateTime? birthDate;
  final Function(DateTime?)? onBirthDateChanged;

  const ProfileInfoSection({
    super.key,
    required this.employeeInfo,
    this.isEditMode = false,
    this.nameController,
    this.phoneController,
    this.emailController,
    this.nationalIdController,
    this.genderController,
    this.birthDate,
    this.onBirthDateChanged,
  });

  @override
  State<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _ProfileInfoSectionState extends State<ProfileInfoSection> {

  Future<void> _selectBirthDate() async {
    if (widget.onBirthDateChanged == null) return;

    final picked = await DatePickerHelper.showBirthDatePicker(context);
    if (picked != null && widget.onBirthDateChanged != null) {
      widget.onBirthDateChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'المعلومات الشخصية',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (widget.isEditMode) ...[
                  // Name (Editable)
                  CustomTextField(
                    label: 'الاسم الكامل',
                    placeholder: 'أدخل الاسم الكامل',
                    prefixIcon: Icons.person_outline,
                    controller: widget.nameController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Name (Read-only)
                  _buildInfoRow(
                    context,
                    icon: Icons.person_outline,
                    label: 'الاسم الكامل',
                    value: widget.employeeInfo.name,
                  ),
                  const Divider(height: 32),
                ],
                // National ID (Editable in edit mode)
                if (widget.isEditMode) ...[
                  CustomTextField(
                    label: 'رقم البطاقة',
                    placeholder: 'أدخل رقم البطاقة',
                    prefixIcon: Icons.badge_outlined,
                    controller: widget.nationalIdController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildInfoRow(
                    context,
                    icon: Icons.badge_outlined,
                    label: 'رقم البطاقة',
                    value: widget.employeeInfo.nationalId ?? 'غير محدد',
                  ),
                  const Divider(height: 32),
                ],
                // Phone (Editable in edit mode)
                if (widget.isEditMode) ...[
                  CustomTextField(
                    label: 'رقم التليفون',
                    placeholder: 'أدخل رقم التليفون',
                    prefixIcon: Icons.phone_outlined,
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildInfoRow(
                    context,
                    icon: Icons.phone_outlined,
                    label: 'رقم التليفون',
                    value: widget.employeeInfo.phone ?? 'غير محدد',
                  ),
                  const Divider(height: 32),
                ],
                // Email (Editable in edit mode)
                if (widget.isEditMode) ...[
                  CustomTextField(
                    label: 'البريد الإلكتروني',
                    placeholder: 'أدخل البريد الإلكتروني',
                    prefixIcon: Icons.email_outlined,
                    controller: widget.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildInfoRow(
                    context,
                    icon: Icons.email_outlined,
                    label: 'البريد الإلكتروني',
                    value: widget.employeeInfo.email ?? 'غير محدد',
                  ),
                  const Divider(height: 32),
                ],
                // Gender (Editable in edit mode)
                if (widget.isEditMode) ...[
                  CustomTextField(
                    label: 'النوع',
                    placeholder: 'أدخل النوع',
                    prefixIcon: Icons.person_outline,
                    controller: widget.genderController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  if (widget.employeeInfo.gender != null) ...[
                    _buildInfoRow(
                      context,
                      icon: Icons.person_outline,
                      label: 'النوع',
                      value: widget.employeeInfo.gender!,
                    ),
                    const Divider(height: 32),
                  ],
                ],
                // Birth Date (Editable in edit mode)
                if (widget.isEditMode) ...[
                  DatePickerField(
                    label: 'تاريخ الميلاد',
                    value: (widget.birthDate ?? widget.employeeInfo.birthDate) != null
                        ? formatDate(widget.birthDate ?? widget.employeeInfo.birthDate!)
                        : null,
                    onTap: _selectBirthDate,
                    icon: Icons.calendar_today_outlined,
                    enabled: true,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'تاريخ الميلاد',
                    value: widget.employeeInfo.birthDate != null
                        ? formatDate(widget.employeeInfo.birthDate!)
                        : 'غير محدد',
                  ),
                  const Divider(height: 32),
                ],
                // Start Date (Read-only - Company info)
                _buildInfoRow(
                  context,
                  icon: Icons.work_outline,
                  label: 'تاريخ البداية',
                  value: (widget.employeeInfo.startDate ?? widget.employeeInfo.hireDate) != null
                      ? formatDate(widget.employeeInfo.startDate ?? widget.employeeInfo.hireDate!)
                      : 'غير محدد',
                ),
                // Address
                if (widget.employeeInfo.address != null && widget.employeeInfo.address!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'العنوان',
                    value: widget.employeeInfo.address!,
                  ),
                ],
                // City / Governorate
                if (widget.employeeInfo.city != null || widget.employeeInfo.governorate != null) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.location_city_outlined,
                    label: 'المدينة / المحافظة',
                    value: [widget.employeeInfo.city, widget.employeeInfo.governorate]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' - '),
                  ),
                ],
                // Nationality
                if (widget.employeeInfo.nationality != null && widget.employeeInfo.nationality!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.flag_outlined,
                    label: 'الجنسية',
                    value: widget.employeeInfo.nationality!,
                  ),
                ],
                // Marital Status
                if (widget.employeeInfo.maritalStatus != null && widget.employeeInfo.maritalStatus!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.family_restroom_outlined,
                    label: 'الحالة الاجتماعية',
                    value: widget.employeeInfo.maritalStatus!,
                  ),
                ],
                // Employee Code
                if (widget.employeeInfo.employeeCode != null && widget.employeeInfo.employeeCode!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.qr_code_outlined,
                    label: 'كود الموظف',
                    value: widget.employeeInfo.employeeCode!,
                  ),
                ],
                // Branch Name
                if (widget.employeeInfo.branchName != null && widget.employeeInfo.branchName!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.business_outlined,
                    label: 'الفرع',
                    value: widget.employeeInfo.branchName!,
                  ),
                ],
                // Manager Name
                if (widget.employeeInfo.managerName != null && widget.employeeInfo.managerName!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.supervisor_account_outlined,
                    label: 'المدير المباشر',
                    value: widget.employeeInfo.managerName!,
                  ),
                ],
                // Machine Code
                if (widget.employeeInfo.machineCode != null && widget.employeeInfo.machineCode!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.fingerprint_outlined,
                    label: 'كود الماكينة',
                    value: widget.employeeInfo.machineCode!,
                  ),
                ],
                // Address En
                if (widget.employeeInfo.addressEn != null && widget.employeeInfo.addressEn!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    icon: Icons.translate_outlined,
                    label: 'العنوان (EN)',
                    value: widget.employeeInfo.addressEn!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
