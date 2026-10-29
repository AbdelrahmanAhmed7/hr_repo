import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mediconsult_internal/src/core/services/attendance_auth_service.dart';
import 'package:mediconsult_internal/src/core/services/biometric_auth_service.dart';

class _FakeLocalAuthentication extends Fake implements LocalAuthentication {
  _FakeLocalAuthentication({this.result = true, this.error});

  final bool result;
  final PlatformException? error;
  Invocation? authenticateInvocation;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      authenticateInvocation = invocation;
      if (error != null) return Future<bool>.error(error!);
      return Future<bool>.value(result);
    }
    if (invocation.memberName == #stopAuthentication) {
      return Future<bool>.value(true);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  tearDown(BiometricAuthService.resetAuthForTesting);

  test('allows OS biometrics and device credential fallback', () async {
    final auth = _FakeLocalAuthentication();
    BiometricAuthService.authForTesting = auth;

    final result = await BiometricAuthService.authenticate(
      localizedReason: 'Authenticate attendance',
    );

    expect(result, BiometricResult.success);
    final options =
        auth.authenticateInvocation!.namedArguments[#options]
            as AuthenticationOptions;
    expect(options.biometricOnly, isFalse);
    expect(options.stickyAuth, isTrue);
  });

  test('accepts a successful face or fingerprint response', () async {
    final auth = _FakeLocalAuthentication(result: true);
    BiometricAuthService.authForTesting = auth;

    final result = await BiometricAuthService.authenticate(
      localizedReason: 'Authenticate attendance',
    );

    expect(result, BiometricResult.success);
  });

  test(
    'attendance opens the OS prompt without a biometric pre-check',
    () async {
      final auth = _FakeLocalAuthentication(result: false);
      BiometricAuthService.authForTesting = auth;

      final response = await AttendanceAuthService.authenticateForAttendance(
        isCheckIn: true,
      );

      expect(auth.authenticateInvocation, isNotNull);
      expect(response.result, AttendanceAuthResult.biometricCancelled);
    },
  );

  test(
    'maps an unavailable OS authenticator to hardware unavailable',
    () async {
      final auth = _FakeLocalAuthentication(
        error: PlatformException(code: 'NotAvailable'),
      );
      BiometricAuthService.authForTesting = auth;

      final result = await BiometricAuthService.authenticate(
        localizedReason: 'Authenticate attendance',
      );

      expect(result, BiometricResult.hardwareUnavailable);
    },
  );
}
