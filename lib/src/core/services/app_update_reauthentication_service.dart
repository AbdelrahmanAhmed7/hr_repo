import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/services/auth_storage_service.dart';
import '../constants/storage_keys.dart';

/// Invalidates a persisted login whenever the installed app build changes.
///
/// TestFlight can publish multiple builds with the same marketing version, so
/// both [PackageInfo.version] and [PackageInfo.buildNumber] are compared.
class AppUpdateReauthenticationService {
  const AppUpdateReauthenticationService._();

  /// Returns `true` when the stored session was invalidated.
  ///
  /// A missing build marker is intentionally treated as an update. This makes
  /// the first release containing this protection invalidate sessions created
  /// by older releases that did not save a marker yet.
  static Future<bool> enforce({
    String? currentBuildIdentifier,
    Future<void> Function()? clearAuthState,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBuild =
        currentBuildIdentifier ?? await _readCurrentBuildIdentifier();
    final authenticatedBuild = prefs.getString(
      StorageKeys.authenticatedAppBuild,
    );

    if (authenticatedBuild == currentBuild) return false;

    // Do not trust an old session until its build marker matches. Persist the
    // new marker only after logout succeeds, so a failure is retried on the
    // next launch instead of silently restoring the old token.
    await (clearAuthState ?? AuthStorageService.clearAuthState)();
    await prefs.setString(StorageKeys.authenticatedAppBuild, currentBuild);

    if (kDebugMode) {
      debugPrint(
        '[AUTH] App build changed ($authenticatedBuild -> $currentBuild) '
        '— login required.',
      );
    }
    return true;
  }

  static Future<String> _readCurrentBuildIdentifier() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }
}
