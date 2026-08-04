import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/components/custom_text_field.dart';
import 'auth_validators.dart';
import 'repository/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final phone = _phoneController.text.trim();
    final error = AuthValidators.validatePhone(phone);

    setState(() {
      _phoneError = error;
    });

    if (error != null) return;

    setState(() => _isLoading = true);

    try {
      final message = await getIt<AuthRepository>().forgotPassword(
        phoneNumber: phone,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      CustomToast.showSuccess(message);
      context.push('/otp-verification?phone=${Uri.encodeComponent(phone)}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomToast.showError(
        'تعذر إرسال كود التحقق. تأكد من رقم الموبايل وحاول مرة أخرى.',
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
          'نسيت كلمة المرور',
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
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'استعادة كلمة المرور',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أدخل رقم الموبايل المسجل وسنرسل لك كود التحقق.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'رقم الموبايل',
                    placeholder: 'أدخل رقم الموبايل',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    controller: _phoneController,
                    errorText: _phoneError,
                    fillColor: AppColors.background,
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() {
                          _phoneError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    text: 'إرسال كود التحقق',
                    isLoading: _isLoading,
                    onPressed: _handleVerify,
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
