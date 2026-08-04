import 'package:flutter/material.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/autofill_hints.dart' as app_autofill;
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_text_field.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/mixins/keyboard_dismiss_mixin.dart';
import '../auth/auth_validators.dart';
import '../auth/repository/auth_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with KeyboardDismissMixin {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _oldPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _oldPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _validateOldPassword(String value) {
    _oldPasswordError = value.trim().isEmpty ? 'أدخل كلمة المرور الحالية' : null;
  }

  void _validateNewPassword(String value) {
    _newPasswordError = AuthValidators.validatePassword(value);

    if (value.trim().isNotEmpty &&
        value.trim() == _oldPasswordController.text.trim()) {
      _newPasswordError = 'كلمة المرور الجديدة يجب أن تختلف عن الحالية';
    }
  }

  void _validateConfirmPassword(String value) {
    if (value.trim().isEmpty) {
      _confirmPasswordError = 'أكد كلمة المرور الجديدة';
      return;
    }

    if (value.trim() != _newPasswordController.text.trim()) {
      _confirmPasswordError = 'كلمة المرور الجديدة وتأكيدها غير متطابقين';
      return;
    }

    _confirmPasswordError = null;
  }

  bool _validateForm() {
    setState(() {
      _validateOldPassword(_oldPasswordController.text);
      _validateNewPassword(_newPasswordController.text);
      _validateConfirmPassword(_confirmPasswordController.text);
    });

    return _oldPasswordError == null &&
        _newPasswordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> _handleChangePassword() async {
    FocusScope.of(context).unfocus();

    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final message = await getIt<AuthRepository>().changePassword(
        currentPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        confirmNewPassword: _confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _oldPasswordError = null;
        _newPasswordError = null;
        _confirmPasswordError = null;
      });

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      CustomToast.showSuccess(message);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      final message = e.toString();
      if (message.contains('incorrect_current_password')) {
        setState(() {
          _oldPasswordError = 'كلمة المرور الحالية غير صحيحة';
        });
        return;
      }

      if (message.contains('password_mismatch')) {
        setState(() {
          _confirmPasswordError = 'كلمة المرور الجديدة وتأكيدها غير متطابقين';
        });
        return;
      }

      CustomToast.showError(
        'تعذر تغيير كلمة المرور الآن. حاول مرة أخرى.'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'تغيير كلمة المرور',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تحديث كلمة المرور',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أدخل كلمة المرور الحالية ثم الجديدة وأكدها مرة أخرى.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'كلمة المرور الحالية',
                  placeholder: 'أدخل كلمة المرور الحالية',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: !_isOldPasswordVisible,
                  controller: _oldPasswordController,
                  focusNode: _oldPasswordFocus,
                  nextFocusNode: _newPasswordFocus,
                  textInputAction: TextInputAction.next,
                  autofillHints: app_autofill.AppAutofillHints.password,
                  errorText: _oldPasswordError,
                  fillColor: AppColors.background,
                  onChanged: (value) {
                    setState(() {
                      _validateOldPassword(value);
                    });
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isOldPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isOldPasswordVisible = !_isOldPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'كلمة المرور الجديدة',
                  placeholder: 'أدخل كلمة المرور الجديدة',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: !_isNewPasswordVisible,
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocus,
                  nextFocusNode: _confirmPasswordFocus,
                  textInputAction: TextInputAction.next,
                  autofillHints: app_autofill.AppAutofillHints.newPassword,
                  errorText: _newPasswordError,
                  fillColor: AppColors.background,
                  onChanged: (value) {
                    setState(() {
                      _validateNewPassword(value);
                      if (_confirmPasswordController.text.isNotEmpty) {
                        _validateConfirmPassword(
                          _confirmPasswordController.text,
                        );
                      }
                    });
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'تأكيد كلمة المرور الجديدة',
                  placeholder: 'أعد إدخال كلمة المرور الجديدة',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: !_isConfirmPasswordVisible,
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  textInputAction: TextInputAction.done,
                  autofillHints: app_autofill.AppAutofillHints.newPassword,
                  errorText: _confirmPasswordError,
                  fillColor: AppColors.background,
                  onChanged: (value) {
                    setState(() {
                      _validateConfirmPassword(value);
                    });
                  },
                  onSubmitted: (_) => _handleChangePassword(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  text: 'حفظ كلمة المرور الجديدة',
                  isLoading: _isLoading,
                  onPressed: _handleChangePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
