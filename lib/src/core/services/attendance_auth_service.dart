import 'biometric_auth_service.dart';
import 'location_errors.dart';
import 'location_service.dart';

// ─── Auth method ──────────────────────────────────────────────────────────────

/// How the attendance record was authenticated.
enum AttendanceAuthMethod {
  /// Biometric check succeeded (fingerprint / Face ID).
  biometric,

  /// User chose "Use another method" or biometric was unavailable.
  fallback,
}

// ─── Result types ─────────────────────────────────────────────────────────────

enum AttendanceAuthResult {
  success,
  biometricFailed,
  biometricCancelled,
  locationFailed,
  outOfRange,
  permissionDenied,
  gpsDisabled,
  unknownError,
}

class AttendanceAuthResponse {
  final AttendanceAuthResult result;
  final String? message;
  final LocationData? location;
  final double? distanceFromOffice;

  /// How the session was authenticated — only meaningful when [result] is
  /// [AttendanceAuthResult.success].
  final AttendanceAuthMethod authMethod;

  /// The underlying biometric result when [result] is
  /// [AttendanceAuthResult.biometricFailed] or [biometricCancelled].
  /// Null for all other results.
  final BiometricResult? biometricResult;

  const AttendanceAuthResponse({
    required this.result,
    required this.authMethod,
    this.message,
    this.location,
    this.distanceFromOffice,
    this.biometricResult,
  });

  bool get isSuccess => result == AttendanceAuthResult.success;

  /// True when the caller should offer a "Use another method" fallback action.
  bool get canUseFallback =>
      result == AttendanceAuthResult.biometricFailed ||
      result == AttendanceAuthResult.biometricCancelled;
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Orchestrates biometric authentication + location retrieval for attendance.
///
/// Decision tree:
/// 1. Check biometric capability.
///    - noHardware / notEnrolled  → skip biometric, proceed as fallback.
///    - available                 → attempt biometric authentication.
///       • success   → proceed, mark authMethod = biometric.
///       • any other → return biometricFailed/biometricCancelled so the UI
///                     can offer "Use another method".
/// 2. Get location.
/// 3. Return success with the resolved location + authMethod.
class AttendanceAuthService {
  /// Primary entry point: try biometric, get location, return typed response.
  ///
  /// When biometric fails the caller receives a response with
  /// [canUseFallback] == true and should present a "Use another method"
  /// button that calls [authenticateWithFallback].
  static Future<AttendanceAuthResponse> authenticateForAttendance({
    required bool isCheckIn,
  }) async {
    final reason = isCheckIn
        ? 'يرجى المصادقة لتسجيل الدخول'
        : 'يرجى المصادقة لتسجيل الخروج';

    // ── Step 1: Biometric gate ─────────────────────────────────────────────
    final capability = await BiometricAuthService.getCapability();

    if (capability == BiometricCapability.available) {
      // Device has enrolled biometrics — require verification.
      final biometricResult = await BiometricAuthService.authenticate(
        localizedReason: reason,
      );

      if (biometricResult != BiometricResult.success) {
        // Biometric could not complete → let the UI offer a fallback.
        final isCancelled = biometricResult == BiometricResult.userCancelled;
        return AttendanceAuthResponse(
          result: isCancelled
              ? AttendanceAuthResult.biometricCancelled
              : AttendanceAuthResult.biometricFailed,
          authMethod: AttendanceAuthMethod.fallback,
          message: BiometricAuthService.arabicMessageFor(biometricResult),
          biometricResult: biometricResult,
        );
      }

      // Biometric OK → get location and succeed.
      return await _fetchLocationAndSucceed(
        isCheckIn: isCheckIn,
        authMethod: AttendanceAuthMethod.biometric,
      );
    }

    // No hardware or nothing enrolled → proceed directly as fallback.
    return await _fetchLocationAndSucceed(
      isCheckIn: isCheckIn,
      authMethod: AttendanceAuthMethod.fallback,
    );
  }

  /// Fallback path: skip biometric entirely and proceed to location.
  ///
  /// Call this when the user taps "Use another method" after a biometric
  /// failure, or whenever [AttendanceAuthResponse.canUseFallback] is true.
  static Future<AttendanceAuthResponse> authenticateWithFallback({
    required bool isCheckIn,
  }) async {
    return await _fetchLocationAndSucceed(
      isCheckIn: isCheckIn,
      authMethod: AttendanceAuthMethod.fallback,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<AttendanceAuthResponse> _fetchLocationAndSucceed({
    required bool isCheckIn,
    required AttendanceAuthMethod authMethod,
  }) async {
    try {
      final location = await LocationService.getCurrentLocation();
      return AttendanceAuthResponse(
        result: AttendanceAuthResult.success,
        authMethod: authMethod,
        message: isCheckIn ? 'تم تسجيل الدخول بنجاح' : 'تم تسجيل الخروج بنجاح',
        location: location,
      );
    } on LocationException catch (e) {
      return _mapLocationException(e, authMethod);
    } catch (_) {
      return AttendanceAuthResponse(
        result: AttendanceAuthResult.unknownError,
        authMethod: authMethod,
        message: 'حدث خطأ غير متوقع أثناء الحصول على الموقع',
      );
    }
  }

  static AttendanceAuthResponse _mapLocationException(
    LocationException e,
    AttendanceAuthMethod authMethod,
  ) {
    return switch (e.error) {
      LocationError.gpsDisabled => AttendanceAuthResponse(
        result: AttendanceAuthResult.gpsDisabled,
        authMethod: authMethod,
        message: 'يرجى تفعيل GPS لتسجيل الحضور',
      ),
      LocationError.permanentlyDenied => AttendanceAuthResponse(
        result: AttendanceAuthResult.permissionDenied,
        authMethod: authMethod,
        message: 'يرجى السماح بالوصول للموقع من إعدادات التطبيق',
      ),
      LocationError.permissionDenied => AttendanceAuthResponse(
        result: AttendanceAuthResult.permissionDenied,
        authMethod: authMethod,
        message: 'يرجى السماح بالوصول للموقع',
      ),
      _ => AttendanceAuthResponse(
        result: AttendanceAuthResult.locationFailed,
        authMethod: authMethod,
        message: 'فشل الحصول على الموقع، يرجى المحاولة مرة أخرى',
      ),
    };
  }
}
