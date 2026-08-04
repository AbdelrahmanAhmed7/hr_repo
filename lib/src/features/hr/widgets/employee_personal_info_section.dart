import 'package:flutter/material.dart';

import '../../../shared/components/custom_text_field.dart';
import '../../../shared/widgets/date_picker_field.dart';
import '../../attendance/utils/attendance_formatters.dart';

/// Personal information section for employee forms
class EmployeePersonalInfoSection extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController nationalIdController;
  final TextEditingController genderController;
  final TextEditingController? passwordController;
  final bool showPasswordField;
  final DateTime? birthDate;
  final VoidCallback onBirthDateSelected;
  final bool isReadOnly;

  const EmployeePersonalInfoSection({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    required this.emailController,
    required this.nationalIdController,
    required this.genderController,
    this.passwordController,
    this.showPasswordField = false,
    required this.birthDate,
    required this.onBirthDateSelected,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          label: 'Full name',
          placeholder: 'Enter full name',
          prefixIcon: Icons.person_outline,
          controller: fullNameController,
          textInputAction: TextInputAction.next,
          nextFocusNode: FocusNode(),
          readOnly: isReadOnly,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Phone number',
          placeholder: 'Enter phone number',
          prefixIcon: Icons.phone_outlined,
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          nextFocusNode: FocusNode(),
          readOnly: isReadOnly,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Email',
          placeholder: 'Enter email',
          prefixIcon: Icons.email_outlined,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          nextFocusNode: FocusNode(),
          readOnly: isReadOnly,
        ),
        if (showPasswordField) ...[
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Password',
            placeholder: 'Enter password',
            prefixIcon: Icons.lock_outline,
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            nextFocusNode: FocusNode(),
            readOnly: isReadOnly,
          ),
        ],
        const SizedBox(height: 16),
        CustomTextField(
          label: 'National ID',
          placeholder: 'Enter national ID',
          prefixIcon: Icons.badge_outlined,
          controller: nationalIdController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          nextFocusNode: FocusNode(),
          readOnly: isReadOnly,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Gender',
          placeholder: 'Enter gender',
          prefixIcon: Icons.person_outline,
          controller: genderController,
          textInputAction: TextInputAction.next,
          nextFocusNode: FocusNode(),
          readOnly: isReadOnly,
        ),
        const SizedBox(height: 16),
        DatePickerField(
          label: 'Birth date',
          value: birthDate != null ? formatDate(birthDate!) : null,
          onTap: onBirthDateSelected,
          icon: Icons.cake_outlined,
          enabled: !isReadOnly,
        ),
      ],
    );
  }
}
