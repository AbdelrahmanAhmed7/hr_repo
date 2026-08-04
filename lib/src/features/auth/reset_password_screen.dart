import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/autofill_hints.dart' as app_autofill;
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/components/custom_text_field.dart';
import '../auth/repository/auth_repository.dart';
import 'auth_validators.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phone;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.phone,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final phoneError = AuthValidators.validatePhone(widget.phone);
    if (phoneError != null) {
      CustomToast.showError(phoneError);
      return;
    }

    final otpError = AuthValidators.validateOtp(widget.otp);
    if (otpError != null) {
      CustomToast.showError(otpError);
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() => _passwordError = 'أدخل كلمة المرور الجديدة');
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'أكد كلمة المرور الجديدة');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _confirmPasswordError = 'كلمة المرور غير متطابقة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final message = await getIt<AuthRepository>().resetPassword(
        phoneNumber: widget.phone,
        otp: widget.otp,
        newPassword: newPassword,
        confirmNewPassword: confirmPassword,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomToast.showSuccess(message);
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomToast.showError(
        'تعذر إعادة تعيين كلمة المرور. تأكد من الكود وحاول مرة أخرى.',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'كلمة مرور جديدة',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'أدخل كلمة المرور الجديدة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سيتم استخدام رقم ${widget.phone} والكود الذي تم التحقق منه تلقائيًا.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'كلمة المرور الجديدة',
                    placeholder: 'أدخل كلمة المرور الجديدة',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocus,
                    nextFocusNode: _confirmPasswordFocus,
                    textInputAction: TextInputAction.next,
                    autofillHints: app_autofill.AppAutofillHints.newPassword,
                    errorText: _passwordError,
                    fillColor: AppColors.background,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'تأكيد كلمة المرور',
                    placeholder: 'أعد إدخال كلمة المرور',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isConfirmPasswordVisible,
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    textInputAction: TextInputAction.done,
                    autofillHints: app_autofill.AppAutofillHints.newPassword,
                    errorText: _confirmPasswordError,
                    fillColor: AppColors.background,
                    onChanged: (_) {
                      if (_confirmPasswordError != null) {
                        setState(() => _confirmPasswordError = null);
                      }
                    },
                    onSubmitted: (_) => _handleResetPassword(),
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
                    text: 'تعيين كلمة المرور',
                    isLoading: _isLoading,
                    onPressed: _handleResetPassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
