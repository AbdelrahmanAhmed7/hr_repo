import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? errorText;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool readOnly;
  final Color? fillColor;
  final int? maxLength;

  const CustomTextField({
    super.key,
    required this.label,
    required this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.errorText,
    this.maxLines = 1,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.focusNode,
    this.nextFocusNode,
    this.readOnly = false,
    this.fillColor,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          readOnly: readOnly,
          enabled: !readOnly,
          onChanged: onChanged,
          onSubmitted: (value) {
            if (onSubmitted != null) {
              onSubmitted!(value);
            } else if (textInputAction == TextInputAction.next && nextFocusNode != null) {
              // Automatically move to next field
              nextFocusNode!.requestFocus();
            } else if (textInputAction == TextInputAction.done) {
              // Dismiss keyboard
              FocusScope.of(context).unfocus();
            }
          },
          style: TextStyle(
            color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary)
                : null,
            suffixIcon: suffixIcon,
            errorText: errorText,
            errorMaxLines: 3,
            filled: true,
            fillColor: fillColor ?? (readOnly ? AppColors.backgroundSecondary.withValues(alpha: 0.5) : Colors.white),
          ),
        ),
      ],
    );
  }
}