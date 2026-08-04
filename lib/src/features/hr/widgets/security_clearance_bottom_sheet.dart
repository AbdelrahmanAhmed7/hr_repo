import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/custom_toast.dart';
import '../../../shared/components/custom_text_field.dart';
import '../cubit/employees_cubit.dart';
import '../models/employee.dart';

class SecurityClearanceBottomSheet extends StatefulWidget {
  final Employee employee;

  const SecurityClearanceBottomSheet({
    super.key,
    required this.employee,
  });

  @override
  State<SecurityClearanceBottomSheet> createState() =>
      _SecurityClearanceBottomSheetState();
}

class _SecurityClearanceBottomSheetState
    extends State<SecurityClearanceBottomSheet> {
  final TextEditingController _securityClearanceController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _securityClearanceController.text = widget.employee.securityClearance ?? '';
  }

  @override
  void dispose() {
    _securityClearanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final employeesCubit = context.read<EmployeesCubit>();
      
      final securityClearance = _securityClearanceController.text.trim();
      
      await employeesCubit.updateEmployeeSecurityClearance(
        widget.employee.id,
        securityClearance.isEmpty ? null : securityClearance,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.of(context).pop(true); // Return true to indicate success
      
      CustomToast.showSuccess('تم تحديث العهدة بنجاح');
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      CustomToast.showError('حدث خطأ أثناء تحديث العهدة. يرجى المحاولة مرة أخرى');
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);

    try {
      final employeesCubit = context.read<EmployeesCubit>();
      
      await employeesCubit.updateEmployeeSecurityClearance(
        widget.employee.id,
        null,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.of(context).pop(true); // Return true to indicate success
      
      CustomToast.showSuccess('تم حذف العهدة بنجاح');
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      CustomToast.showError('حدث خطأ أثناء حذف العهدة. يرجى المحاولة مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            body: ListView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'إدارة العهدة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 24),

              // Employee Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات الموظف',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('الاسم الكامل', widget.employee.fullName),
                    _buildInfoRow('رقم الموبايل', widget.employee.phone),
                    _buildInfoRow('الإيميل', widget.employee.email),
                    if (widget.employee.department != null)
                      _buildInfoRow('القسم', widget.employee.department!),
                    if (widget.employee.position != null)
                      _buildInfoRow('المنصب', widget.employee.position!),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Security Clearance Field
              CustomTextField(
                label: 'تفاصيل العهدة',
                placeholder: 'أدخل تفاصيل العهدة (مثل: معاه عهدة لابتوب، معاه عهدة جهاز محمول...)',
                prefixIcon: Icons.shield_outlined,
                controller: _securityClearanceController,
                maxLines: 4,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (widget.employee.hasSecurityClearance)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleDelete,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text(
                          'حذف العهدة',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (widget.employee.hasSecurityClearance)
                    const SizedBox(width: 16),
                  Expanded(
                    flex: widget.employee.hasSecurityClearance ? 2 : 1,
                    child: PrimaryButton(
                      text: 'حفظ',
                      isLoading: _isLoading,
                      onPressed: _handleSave,
                    ),
                  ),
                ],
              ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

