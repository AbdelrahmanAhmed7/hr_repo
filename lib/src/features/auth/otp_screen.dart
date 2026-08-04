import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_button.dart';
import '../../shared/components/custom_toast.dart';
import 'auth_validators.dart';
import 'repository/auth_repository.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with CodeAutoFill {
  static const bool _enableOtpAutofillLogs =
      bool.fromEnvironment('ENABLE_OTP_AUTOFILL_LOGS');

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<FocusNode> _keyFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResendEnabled = false;
  int _resendTimer = 60;
  Timer? _timer;

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _canSubmit => _otpCode.length == 6 && !_isLoading;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _startSmsAutofillListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  Future<void> _startSmsAutofillListener() async {
    // sms_autofill is Android-focused (SMS Retriever). Also, plugins can throw
    // MissingPluginException on hot-restart; we don't want the screen to crash.
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (kDebugMode || _enableOtpAutofillLogs) {
        final signature = await SmsAutoFill().getAppSignature;
        debugPrint('OTP autofill app signature: $signature');
      }
      listenForCode();
    } on MissingPluginException {
      // Hot restart / plugin not registered yet. Full restart fixes it.
    } catch (_) {
      // Don't block OTP screen if autofill fails.
    }
  }

  @override
  void dispose() {
    cancel();
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final node in _keyFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void codeUpdated() {
    final raw = code;
    if (raw == null) return;
    // SMS may contain other numbers (phone/date). Extract the first 6-digit code.
    final match = RegExp(r'\b\d{6}\b').firstMatch(raw);
    if (match == null) return;
    _applyOtpDigits(match.group(0)!);
  }

  void _applyOtpDigits(String digits) {
    final otpDigits = digits.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = i < otpDigits.length ? otpDigits[i] : '';
    }
    if (otpDigits.length >= _controllers.length) {
      _focusNodes.last.requestFocus();
    } else if (otpDigits.isNotEmpty) {
      _focusNodes[otpDigits.length.clamp(0, _focusNodes.length - 1)].requestFocus();
    }
    setState(() {});
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _isResendEnabled = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendTimer <= 1) {
        timer.cancel();
        setState(() {
          _resendTimer = 0;
          _isResendEnabled = true;
        });
        return;
      }

      setState(() {
        _resendTimer--;
      });
    });
  }

  void _showError(String message) {
    CustomToast.showError(message);
  }

  void _onOtpChanged(String value, int index) {
    // Support paste: if user pastes full OTP, distribute across fields.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 6) {
        _applyOtpDigits(digits);
        return;
      }
    }

    final digit = value.isEmpty ? '' : value.characters.last;

    if (_controllers[index].text != digit) {
      _controllers[index].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
    }

    if (digit.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digit.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  KeyEventResult _handleOtpKeyEvent(KeyEvent event, int index) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // UX: If current field is empty and user hits backspace, move back and clear previous.
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final current = _controllers[index].text;
      if (current.isEmpty && index > 0) {
        final prevIndex = index - 1;
        _controllers[prevIndex].clear();
        _focusNodes[prevIndex].requestFocus();
        setState(() {});
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  Future<void> _handleVerify() async {
    final phoneError = AuthValidators.validatePhone(widget.phone);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    final otp = _otpCode.trim();
    final otpError = AuthValidators.validateOtp(otp);
    if (otpError != null) {
      _showError(otpError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final message = await getIt<AuthRepository>().verifyResetOtp(
        phoneNumber: widget.phone,
        otp: otp,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomToast.showSuccess(message);
      context.push(
        '/reset-password?phone=${Uri.encodeComponent(widget.phone)}&otp=${Uri.encodeComponent(otp)}',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('كود التحقق غير صحيح أو منتهي الصلاحية');
    }
  }

  Future<void> _handleResend() async {
    if (!_isResendEnabled) return;

    final phoneError = AuthValidators.validatePhone(widget.phone);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final message = await getIt<AuthRepository>().forgotPassword(
        phoneNumber: widget.phone,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _startResendTimer();
      await _startSmsAutofillListener();
      CustomToast.showSuccess(message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('تعذر إعادة إرسال كود التحقق الآن');
    }
  }

  Widget _buildOtpField(BuildContext context, int index) {
    return Focus(
      focusNode: _keyFocusNodes[index],
      onKeyEvent: (_, event) => _handleOtpKeyEvent(event, index),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
        textInputAction:
            index == _controllers.length - 1 ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        onTap: () {
          // Ensure the key listener is active for physical keyboard/backspace.
          if (!_keyFocusNodes[index].hasFocus) {
            _keyFocusNodes[index].requestFocus();
          }
        },
        onChanged: (value) => _onOtpChanged(value, index),
        onSubmitted: (_) {
          if (index == _controllers.length - 1 && _canSubmit) {
            _handleVerify();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'التحقق من الكود',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      color: AppColors.primary,
                      size: 50,
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(duration: 400.ms),
                  const SizedBox(height: 32),
                  Text(
                    'أدخل كود التحقق',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      text: 'تم إرسال كود التحقق إلى رقم ',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      children: [
                        TextSpan(
                          text: widget.phone,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0; // 4 left + 4 right
                        final totalGaps = gap * (_controllers.length - 1);
                        final available = constraints.maxWidth - totalGaps;
                        final itemWidth = (available / _controllers.length)
                            .clamp(44.0, 58.0);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _controllers.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                right: index == _controllers.length - 1 ? 0 : gap,
                              ),
                              child: SizedBox(
                                width: itemWidth,
                                height: (itemWidth + 10).clamp(54.0, 70.0),
                                child: _buildOtpField(context, index),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'تحقق',
                    isLoading: _isLoading,
                    onPressed: _canSubmit ? _handleVerify : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لم تستلم الكود؟',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 4),
                      if (_isResendEnabled)
                        TextButton(
                          onPressed: _handleResend,
                          child: const Text('إعادة الإرسال'),
                        )
                      else
                        Text(
                          '$_resendTimer ثانية',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
