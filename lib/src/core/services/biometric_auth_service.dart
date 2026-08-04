import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

// ─── Result types ─────────────────────────────────────────────────────────────

/// The outcome of a single biometric authentication attempt.
enum BiometricResult {
  /// Authentication succeeded.
  success,

  /// User cancelled the prompt (pressed back / dismissed).
  userCancelled,

  /// Biometric hardware exists but no credentials are enrolled.
  notEnrolled,

  /// The hardware sensor is temporarily locked after too many failures.
  lockedOut,

  /// The hardware sensor is permanently locked; requires a device PIN reset.
  permanentlyLockedOut,

  /// The device has no biometric hardware at all.
  hardwareUnavailable,

  /// Authentication matched but the challenge failed.
  authenticationFailed,

  /// Any other unexpected platform error.
  unknownError,
}

/// Capability snapshot of the device's biometric support.
enum BiometricCapability {
  /// At least one biometric is enrolled and the sensor is available.
  available,

  /// Device supports biometrics but nothing is enrolled.
  notEnrolled,

  /// Device has no biometric hardware (or OS doesn't support it).
  noHardware,
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Encapsulates all local_auth interactions.
///
/// - Detects what biometric types are available.
/// - Runs authentication using the OS-preferred method (do NOT force
///   fingerprint; Face ID / Fingerprint choice is the platform's job).
/// - Translates every PlatformException into a typed [BiometricResult] so
///   callers never have to inspect raw error-code strings.
class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Guard against concurrent authenticate() calls.
  static bool _isAuthenticating = false;

  // ── Capability detection ───────────────────────────────────────────────────

  /// Returns a [BiometricCapability] describing what the device can do.
  /// Never throws.
  static Future<BiometricCapability> getCapability() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return BiometricCapability.noHardware;

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return BiometricCapability.noHardware;

      final available = await _auth.getAvailableBiometrics();
      if (available.isEmpty) return BiometricCapability.notEnrolled;

      return BiometricCapability.available;
    } catch (_) {
      return BiometricCapability.noHardware;
    }
  }

  /// Convenience shortcut — true only when a biometric is enrolled & usable.
  static Future<bool> isAvailable() async =>
      (await getCapability()) == BiometricCapability.available;

  /// Returns the list of enrolled biometric types.
  /// Use only for display purposes (e.g. icon selection).
  /// Do NOT use this to decide which type to authenticate with — the OS handles that.
  static Future<List<BiometricType>> getEnrolledTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Requests biometric authentication using the OS-preferred method.
  ///
  /// Returns a typed [BiometricResult] — never throws.
  ///
  /// Notes:
  ///   - [biometricOnly] is `true` to prevent the OS from falling back to
  ///     PIN/pattern. We provide our own "Use another method" UX instead.
  ///   - [stickyAuth] keeps the dialog alive if the app is briefly backgrounded.
  ///   - When the user cancels or dismisses, `authenticate()` returns `false`
  ///     (no PlatformException) → maps to [BiometricResult.userCancelled].
  static Future<BiometricResult> authenticate({
    required String localizedReason,
  }) async {
    if (_isAuthenticating) {
      // Prevent stacking duplicate dialogs.
      return BiometricResult.unknownError;
    }

    _isAuthenticating = true;
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      // `false` without a PlatformException means the user cancelled/dismissed.
      return authenticated
          ? BiometricResult.success
          : BiometricResult.userCancelled;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[BiometricAuthService] PlatformException: '
          'code=${e.code}  message=${e.message}',
        );
      }
      return _mapPlatformException(e);
    } catch (e) {
      if (kDebugMode) debugPrint('[BiometricAuthService] unexpected error: $e');
      return BiometricResult.unknownError;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Cancels any in-progress authentication prompt.
  static Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Translate a [PlatformException] from local_auth into a [BiometricResult].
  static BiometricResult _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
      case auth_error.otherOperatingSystem:
        return BiometricResult.hardwareUnavailable;

      case auth_error.notEnrolled:
      case auth_error.passcodeNotSet:
        // No credential enrolled → we cannot authenticate, but attendance
        // must not be blocked. Caller will offer fallback.
        return BiometricResult.notEnrolled;

      case auth_error.lockedOut:
        return BiometricResult.lockedOut;

      case auth_error.permanentlyLockedOut:
        return BiometricResult.permanentlyLockedOut;

      default:
        // biometricOnlyNotSupported and any other codes → unknown.
        return BiometricResult.unknownError;
    }
  }

  /// Human-readable Arabic message for a given [BiometricResult].
  /// Used in the fallback bottom sheet to inform the user.
  static String arabicMessageFor(BiometricResult result) {
    switch (result) {
      case BiometricResult.success:
        return 'تمت المصادقة بنجاح';
      case BiometricResult.userCancelled:
        return 'تم إلغاء المصادقة البيومترية';
      case BiometricResult.notEnrolled:
        return 'لم يتم تسجيل بصمة أو وجه على هذا الجهاز';
      case BiometricResult.lockedOut:
        return 'الاستشعار مقفل مؤقتًا بسبب محاولات فاشلة متعددة';
      case BiometricResult.permanentlyLockedOut:
        return 'الاستشعار مقفل بشكل دائم، يرجى فتح الجهاز بالـ PIN أولًا';
      case BiometricResult.hardwareUnavailable:
        return 'لا يدعم هذا الجهاز المصادقة البيومترية';
      case BiometricResult.authenticationFailed:
        return 'لم تتطابق البيانات البيومترية';
      case BiometricResult.unknownError:
        return 'تعذّرت المصادقة البيومترية';
    }
  }
}
