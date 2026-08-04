import 'package:flutter/material.dart';
import '../../../shared/components/custom_text_field.dart';

/// Security clearance section for employee forms
class EmployeeSecurityClearanceSection extends StatelessWidget {
  final TextEditingController securityClearanceController;
  final bool isReadOnly;

  const EmployeeSecurityClearanceSection({
    super.key,
    required this.securityClearanceController,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'تفاصيل العهدة',
      placeholder:
          'أدخل تفاصيل العهدة (مثل: معاه عهدة لابتوب، معاه عهدة جهاز محمول...)',
      prefixIcon: Icons.shield_outlined,
      controller: securityClearanceController,
      maxLines: 4,
      textInputAction: TextInputAction.done,
      readOnly: isReadOnly,
    );
  }
}

