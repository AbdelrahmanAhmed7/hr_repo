import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/shared/components/custom_toast.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_exception.dart';
import 'attendance_auth_service.dart';
import 'biometric_auth_service.dart';
import 'location_service.dart';

/// Top-level handler for attendance check-in / check-out.
///
/// Responsibilities:
///   1. Drive the biometric → location → API call pipeline.
///   2. On biometric failure, show a bottom sheet offering "Use another method"
///      so the user can proceed via fallback without being blocked.
///   3. Surface all location / network errors as user-friendly toasts.
///   4. Pass [authMethod] through to [onSuccess] so the API can record it.
///
/// Usage is identical to the old API — all call sites remain unchanged.
class AttendanceHandler {
  /// Attempt attendance registration.
  ///
  /// [isCheckIn]  – true for check-in, false for check-out.
  /// [onSuccess]  – called with (isCheckIn, location, authMethod) on success.
  /// Returns true on success, false on any failure.
  static Future<bool> handleAttendance({
    required BuildContext context,
    required bool isCheckIn,
    Future<void> Function(
      bool isCheckIn,
      LocationData? location, {
      String authMethod,
    })?
    onSuccess,
  }) async {
    if (!context.mounted) return false;

    try {
      final response = await AttendanceAuthService.authenticateForAttendance(
        isCheckIn: isCheckIn,
      );

      if (!context.mounted) return false;

      // ── Success (biometric or capability-skipped) ──────────────────────
      if (response.isSuccess) {
        await onSuccess?.call(
          isCheckIn,
          response.location,
          authMethod: response.authMethod.name,
        );
        if (!context.mounted) return false;
        CustomToast.showSuccess(
          response.message ??
              (isCheckIn ? 'تم تسجيل الدخول بنجاح' : 'تم تسجيل الخروج بنجاح'),
        );
        return true;
      }

      // ── Biometric failed / cancelled → offer fallback ──────────────────
      if (response.canUseFallback) {
        final useFallback = await _showBiometricFallbackSheet(
          context: context,
          isCheckIn: isCheckIn,
          biometricMessage: response.message,
          biometricResult: response.biometricResult,
        );

        if (!context.mounted) return false;
        if (!useFallback) return false; // user dismissed without choosing

        // User confirmed fallback → run without biometric
        final fallbackResponse =
            await AttendanceAuthService.authenticateWithFallback(
              isCheckIn: isCheckIn,
            );

        if (!context.mounted) return false;

        if (fallbackResponse.isSuccess) {
          await onSuccess?.call(
            isCheckIn,
            fallbackResponse.location,
            authMethod: AttendanceAuthMethod.fallback.name,
          );
          if (!context.mounted) return false;
          CustomToast.showSuccess(
            fallbackResponse.message ??
                (isCheckIn ? 'تم تسجيل الدخول بنجاح' : 'تم تسجيل الخروج بنجاح'),
          );
          return true;
        }

        // Fallback also failed (e.g. location error)
        _showLocationError(fallbackResponse);
        return false;
      }

      // ── Location / permission errors ───────────────────────────────────
      _showLocationError(response);
      return false;
    } catch (e) {
      if (!context.mounted) return false;

      String errorMessage = 'حدث خطأ غير متوقع';
      if (e is String) {
        errorMessage = e;
      } else {
        errorMessage = AppException.from(e).message;
      }

      CustomToast.showError(errorMessage);
      return false;
    }
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  /// Shows a non-dismissible bottom sheet explaining the biometric failure and
  /// offering two options:
  ///   - "Use another method"  → returns true
  ///   - "Cancel"              → returns false
  ///
  /// The sheet is kept simple — no retry loop.
  static Future<bool> _showBiometricFallbackSheet({
    required BuildContext context,
    required bool isCheckIn,
    String? biometricMessage,
    BiometricResult? biometricResult,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false, // prevent accidental dismissal
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BiometricFallbackSheet(
        isCheckIn: isCheckIn,
        biometricMessage: biometricMessage,
        biometricResult: biometricResult,
      ),
    );
    return result ?? false;
  }

  // ── Toast helpers ──────────────────────────────────────────────────────────

  static void _showLocationError(AttendanceAuthResponse response) {
    final message =
        response.message ??
        (response.result == AttendanceAuthResult.gpsDisabled
            ? 'يرجى تفعيل GPS'
            : 'فشل الحصول على الموقع');
    CustomToast.showError(message);
  }
}

// ─── Biometric Fallback Bottom Sheet ─────────────────────────────────────────

class _BiometricFallbackSheet extends StatelessWidget {
  final bool isCheckIn;
  final String? biometricMessage;
  final BiometricResult? biometricResult;

  const _BiometricFallbackSheet({
    required this.isCheckIn,
    this.biometricMessage,
    this.biometricResult,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(biometricResult);
    final title = _titleFor(biometricResult);
    final detail = biometricMessage ?? 'تعذّرت المصادقة البيومترية';
    final action = isCheckIn ? 'الدخول' : 'الخروج';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.warning, size: 30),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Detail message
          Text(
            detail,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Primary CTA — use fallback
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.location_on_rounded),
              label: Text(
                'استخدام طريقة أخرى وتسجيل $action',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary — cancel
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(BiometricResult? result) {
    switch (result) {
      case BiometricResult.notEnrolled:
        return Icons.fingerprint_rounded;
      case BiometricResult.lockedOut:
      case BiometricResult.permanentlyLockedOut:
        return Icons.lock_rounded;
      case BiometricResult.hardwareUnavailable:
        return Icons.sensors_off_rounded;
      case BiometricResult.userCancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _titleFor(BiometricResult? result) {
    switch (result) {
      case BiometricResult.notEnrolled:
        return 'لا توجد بصمة مسجلة';
      case BiometricResult.lockedOut:
        return 'الاستشعار مقفل مؤقتًا';
      case BiometricResult.permanentlyLockedOut:
        return 'الاستشعار مقفل بشكل دائم';
      case BiometricResult.hardwareUnavailable:
        return 'البصمة غير متاحة';
      case BiometricResult.userCancelled:
        return 'تم إلغاء المصادقة';
      case BiometricResult.authenticationFailed:
        return 'لم تتطابق البصمة';
      default:
        return 'تعذّرت المصادقة البيومترية';
    }
  }
}
