import 'package:flutter_test/flutter_test.dart';
import 'package:mediconsult_internal/src/core/constants/storage_keys.dart';
import 'package:mediconsult_internal/src/core/services/app_update_reauthentication_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps the session when the exact app build is unchanged', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.authenticatedAppBuild: '1.0.7+20',
    });
    var logoutCount = 0;

    final invalidated = await AppUpdateReauthenticationService.enforce(
      currentBuildIdentifier: '1.0.7+20',
      clearAuthState: () async => logoutCount++,
    );

    expect(invalidated, isFalse);
    expect(logoutCount, 0);
  });

  test('invalidates the session when the TestFlight build changes', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.authenticatedAppBuild: '1.0.7+20',
    });
    var logoutCount = 0;

    final invalidated = await AppUpdateReauthenticationService.enforce(
      currentBuildIdentifier: '1.0.7+21',
      clearAuthState: () async => logoutCount++,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(invalidated, isTrue);
    expect(logoutCount, 1);
    expect(prefs.getString(StorageKeys.authenticatedAppBuild), '1.0.7+21');
  });

  test(
    'missing marker invalidates sessions created by older app builds',
    () async {
      SharedPreferences.setMockInitialValues({});
      var logoutCount = 0;

      final invalidated = await AppUpdateReauthenticationService.enforce(
        currentBuildIdentifier: '1.0.7+21',
        clearAuthState: () async => logoutCount++,
      );

      expect(invalidated, isTrue);
      expect(logoutCount, 1);
    },
  );

  test('does not accept the new build marker when logout fails', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.authenticatedAppBuild: '1.0.7+20',
    });

    await expectLater(
      AppUpdateReauthenticationService.enforce(
        currentBuildIdentifier: '1.0.7+21',
        clearAuthState: () async => throw StateError('logout failed'),
      ),
      throwsStateError,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(StorageKeys.authenticatedAppBuild), '1.0.7+20');
  });
}
