import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/autofill_hints.dart' as app_autofill;
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/components/custom_text_field.dart';
import '../../shared/mixins/keyboard_dismiss_mixin.dart';
import 'auth_validators.dart';
import 'cubit/auth_cubit.dart';
import 'services/auth_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with KeyboardDismissMixin {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _phoneError;
  String? _passError;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn();
  }

  Future<void> _checkIfAlreadyLoggedIn() async {
    final authCubit = getIt<AuthCubit>();
    if (authCubit.state.isAuthenticated && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/main');
      });
    }
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final passError = AuthValidators.validatePassword(_passController.text);
    setState(() {
      _phoneError = null;
      _passError = passError;
    });
    return passError == null;
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final authCubit = getIt<AuthCubit>();
      await authCubit.login(
        nationalId: _phoneController.text.trim(),
        password: _passController.text,
      );

      if (!mounted) return;
      final authState = await AuthStorageService.loadAuthState();
      if (!mounted) return;
      if (!authState.isAuthenticated) throw Exception('Authentication failed');

      setState(() => _isLoading = false);
      context.go('/main');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      var errorMessage = 'حدث خطأ أثناء تسجيل الدخول.';

      if (e is DioException && e.response?.data is Map) {
        final responseData = e.response!.data as Map<String, dynamic>;
        errorMessage = responseData['title'] ?? errorMessage;
      } else if (e.toString().contains('pending_account')) {
        errorMessage = 'حسابك ما زال تحت المراجعة.';
      } else if (e.toString().contains('rejected_account')) {
        errorMessage = 'تم رفض طلب تسجيلك.';
      } else if (e.toString().contains('invalid_credentials')) {
        errorMessage = 'رقم الموبايل أو كلمة المرور غير صحيحين.';
      } else if (e.toString().contains('user_not_found')) {
        errorMessage = 'لم نعثر على حساب مطابق.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال.';
      } else if (e.toString().contains('network_error')) {
        errorMessage = 'تأكد من اتصال الإنترنت.';
      }

      CustomToast.showError(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 100;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1734),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Hero layer: fills entire screen ──
          const Positioned.fill(child: _HeroBackground()),

          // ── Content ──
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: screenHeight - MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // Hero area — shrinks when keyboard opens
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    height: isKeyboardOpen ? 80 : screenHeight * 0.40,
                    child: _HeroSection(compact: isKeyboardOpen)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.06, end: 0, duration: 500.ms),
                  ),

                  // Form bottom sheet — takes remaining space
                  Expanded(
                    child:
                        _LoginBottomSheet(
                              isLoading: _isLoading,
                              isPasswordVisible: _isPasswordVisible,
                              phoneController: _phoneController,
                              passController: _passController,
                              phoneFocusNode: _phoneFocusNode,
                              passwordFocusNode: _passwordFocusNode,
                              phoneError: _phoneError,
                              passError: _passError,
                              onTogglePassword: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                              onPhoneChanged: (_) {
                                if (_phoneError != null) {
                                  setState(() => _phoneError = null);
                                }
                              },
                              onPasswordChanged: (_) {
                                if (_passError != null) {
                                  setState(() => _passError = null);
                                }
                              },
                              onForgotPassword: () =>
                                  context.push('/forgot-password'),
                              onSubmit: (_) => _handleLogin(),
                              onLogin: _handleLogin,
                            )
                            .animate()
                            .fadeIn(duration: 560.ms, delay: 100.ms)
                            .slideY(
                              begin: 0.10,
                              end: 0,
                              duration: 560.ms,
                              delay: 100.ms,
                            ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading overlay ──
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Hero background — subtle geometric pattern
// ─────────────────────────────────────────────
class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1734), Color(0xFF102048), Color(0xFF162C5C)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle top-right glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2152A3).withValues(alpha: 0.18),
              ),
            ),
          ),
          // Bottom-left glow
          Positioned(
            bottom: 200,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A3E80).withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Hero Section — Khusm logo + tagline
// ─────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool compact;

  const _HeroSection({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: compact ? 0 : 0),
      child: compact
          // ── Compact mode: logo only, centered ──
          ? Center(child: _KhusmLogo(height: 48))
          // ── Full mode: logo + headline + badges ──
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KhusmLogo(height: 44),
                  const SizedBox(height: 20),
                  Text(
                    'أهلاً بك',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سجّل دخولك للوصول إلى\nالحضور والإجازات والأذونات.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.60),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _TrustBadge(
                        icon: Icons.verified_user_outlined,
                        label: 'آمن ومشفّر',
                      ),
                      const SizedBox(width: 10),
                      _TrustBadge(icon: Icons.bolt_rounded, label: 'وصول فوري'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _KhusmLogo extends StatelessWidget {
  final double height;

  const _KhusmLogo({this.height = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Image.asset(
        'assets/images/Khusm Logo.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business_center_rounded,
                size: 16,
                color: Color(0xFF0B1734),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'خُصم',
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Login Bottom Sheet
// ─────────────────────────────────────────────
class _LoginBottomSheet extends StatelessWidget {
  final bool isLoading;
  final bool isPasswordVisible;
  final TextEditingController phoneController;
  final TextEditingController passController;
  final FocusNode phoneFocusNode;
  final FocusNode passwordFocusNode;
  final String? phoneError;
  final String? passError;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onForgotPassword;
  final ValueChanged<String> onSubmit;
  final VoidCallback onLogin;

  const _LoginBottomSheet({
    required this.isLoading,
    required this.isPasswordVisible,
    required this.phoneController,
    required this.passController,
    required this.phoneFocusNode,
    required this.passwordFocusNode,
    required this.phoneError,
    required this.passError,
    required this.onTogglePassword,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onForgotPassword,
    required this.onSubmit,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: AbsorbPointer(
        absorbing: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Title
              Text(
                'تسجيل الدخول',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'أدخل بياناتك للمتابعة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Phone field
              CustomTextField(
                label: 'رقم الموبايل',
                placeholder: 'أدخل رقم الموبايل',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                controller: phoneController,
                focusNode: phoneFocusNode,
                nextFocusNode: passwordFocusNode,
                textInputAction: TextInputAction.next,
                autofillHints: app_autofill.AppAutofillHints.telephone,
                errorText: phoneError,
                onChanged: onPhoneChanged,
              ),

              const SizedBox(height: 14),

              // Password field
              CustomTextField(
                label: 'كلمة المرور',
                placeholder: 'أدخل كلمة المرور',
                prefixIcon: Icons.lock_outline,
                obscureText: !isPasswordVisible,
                controller: passController,
                focusNode: passwordFocusNode,
                textInputAction: TextInputAction.done,
                autofillHints: app_autofill.AppAutofillHints.password,
                errorText: passError,
                onChanged: onPasswordChanged,
                onSubmitted: onSubmit,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),

              // Forgot password
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Login button
              PrimaryButton(
                text: 'دخول',
                isLoading: isLoading,
                onPressed: onLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
