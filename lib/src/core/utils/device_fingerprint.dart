import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../constants/storage_keys.dart';

/// Singleton service for stable device fingerprint (per-device, not per-user)
class DeviceFingerprintService {
  // Singleton
  static final DeviceFingerprintService _instance =
      DeviceFingerprintService._internal();
  factory DeviceFingerprintService() => _instance;
  DeviceFingerprintService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyDeviceFingerprint = 'device_global_fingerprint';
  static const _keyGeneratedAt = 'device_fp_generated_at';
  static const _keySource = 'device_fp_source';

  // Cached value to avoid repeated storage reads
  String? _cachedFingerprint;
  String? _cachedSource;
  DateTime? _cachedGeneratedAt;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  /// Initialize the service (call at app startup)
  Future<void> initialize() async {
    if (_isInitialized) {
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        await _initCompleter!.future;
      }
      return;
    }

    _initCompleter = Completer<void>();
    try {
      debugPrint('[DeviceFingerprintService] Initializing...');

      // First, try to load from storage
      final stored = await _storage.read(key: _keyDeviceFingerprint);
      final storedSource = await _storage.read(key: _keySource);
      final storedGeneratedAt = await _storage.read(key: _keyGeneratedAt);

      if (stored != null && stored.isNotEmpty) {
        // Load existing
        _cachedFingerprint = stored;
        _cachedSource = storedSource ?? 'stored_secure_storage';
        if (storedGeneratedAt != null) {
          try {
            _cachedGeneratedAt = DateTime.parse(storedGeneratedAt);
          } catch (_) {}
        }
        debugPrint(
            '[DeviceFingerprintService] Loaded existing fingerprint from $_cachedSource: ${_cachedFingerprint!.substring(0, 10)}...');
      } else {
        // Try to migrate from old per-user fingerprints first
        final oldFingerprint = await _tryMigrateOldFingerprint();
        if (oldFingerprint != null) {
          // Use migrated
          _cachedFingerprint = oldFingerprint;
          _cachedSource = 'migrated_per_user';
          _cachedGeneratedAt = DateTime.now();
          await _saveToStorage();
          debugPrint(
              '[DeviceFingerprintService] Migrated old fingerprint: ${_cachedFingerprint!.substring(0, 10)}...');
        } else {
          // Generate new, try to use device identifiers first
          final (fingerprint, source) = await _generateNewFingerprint();
          _cachedFingerprint = fingerprint;
          _cachedSource = source;
          _cachedGeneratedAt = DateTime.now();
          await _saveToStorage();
          debugPrint(
              '[DeviceFingerprintService] Generated new fingerprint from $_cachedSource: ${_cachedFingerprint!.substring(0, 10)}...');
        }
      }

      _isInitialized = true;
      _initCompleter?.complete();
    } catch (e) {
      debugPrint('[DeviceFingerprintService] Initialization error: $e');
      _initCompleter?.completeError(e);
      rethrow;
    }
  }

  /// Get the stable device fingerprint
  Future<String> getFingerprint() async {
    await initialize();
    if (_cachedFingerprint == null) {
      // Fallback (should not happen if initialize succeeded)
      throw StateError('Device fingerprint not initialized');
    }
    return _cachedFingerprint!;
  }

  /// Diagnostic info for debugging
  Future<Map<String, dynamic>> getDiagnostics() async {
    await initialize();
    return {
      'fingerprint': _cachedFingerprint,
      'source': _cachedSource,
      'generatedAt': _cachedGeneratedAt?.toIso8601String(),
      'isInitialized': _isInitialized,
    };
  }

  /// Try to migrate an old per-user fingerprint if exists
  Future<String?> _tryMigrateOldFingerprint() async {
    try {
      final allKeys = await _storage.readAll();
      final oldKeys = allKeys.keys
          .where((key) => key.startsWith(StorageKeys.fingerprintPrefix))
          .toList();

      if (oldKeys.isNotEmpty) {
        // Take the first one (any of them is fine since we just need a stable value)
        final oldValue = allKeys[oldKeys.first];
        if (oldValue != null && oldValue.isNotEmpty) {
          return oldValue;
        }
      }
    } catch (e) {
      debugPrint('[DeviceFingerprintService] Migration error: $e');
    }
    return null;
  }

  /// Generate a new fingerprint, preferring stable device identifiers
  Future<(String fingerprint, String source)> _generateNewFingerprint() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        final androidId = androidInfo.id;
        if (androidId.isNotEmpty) {
          // Use Android ID (stable for same device)
          return (
            _formatFingerprint('$androidId-${androidInfo.model}'),
            'android_id'
          );
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        final identifierForVendor = iosInfo.identifierForVendor;
        if (identifierForVendor != null && identifierForVendor.isNotEmpty) {
          // Use iOS identifierForVendor (stable for same device)
          return (
            _formatFingerprint('$identifierForVendor-${iosInfo.model}'),
            'ios_identifier_for_vendor'
          );
        }
      }
    } catch (e) {
      debugPrint('[DeviceFingerprintService] Error getting device info: $e');
    }

    // Fallback: generate a stable UUID (random but persistent once stored)
    final uuid = const Uuid().v4();
    return (_formatFingerprint(uuid), 'generated_uuid');
  }

  /// Format the fingerprint consistently
  String _formatFingerprint(String raw) {
    return raw
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase()
        .substring(0, raw.length > 16 ? 16 : raw.length)
        .padLeft(16, '0');
  }

  /// Save fingerprint to secure storage
  Future<void> _saveToStorage() async {
    if (_cachedFingerprint == null) return;
    await _storage.write(key: _keyDeviceFingerprint, value: _cachedFingerprint);
    if (_cachedSource != null) {
      await _storage.write(key: _keySource, value: _cachedSource);
    }
    if (_cachedGeneratedAt != null) {
      await _storage.write(
        key: _keyGeneratedAt,
        value: _cachedGeneratedAt!.toUtc().toIso8601String(),
      );
    }
  }

  /// Clear fingerprint (ONLY for TESTING/DIAGNOSTIC USE!)
  /// This will generate a new fingerprint next time initialize() is called
  Future<void> clearFingerprint() async {
    await _storage.delete(key: _keyDeviceFingerprint);
    await _storage.delete(key: _keySource);
    await _storage.delete(key: _keyGeneratedAt);
    _cachedFingerprint = null;
    _cachedSource = null;
    _cachedGeneratedAt = null;
    _isInitialized = false;
    _initCompleter = null;
  }
}

/// Legacy compatibility wrapper (for existing code that uses DeviceFingerprint)
class DeviceFingerprint {
  @Deprecated('Use DeviceFingerprintService() instead')
  static Future<String> getFingerprintKey(String userId) async {
    return await DeviceFingerprintService().getFingerprint();
  }

  @Deprecated('Use DeviceFingerprintService() instead')
  static Future<void> clearFingerprint(String userId) async {
    // No-op for backward compatibility
    debugPrint('[DeviceFingerprint] Ignoring clearFingerprint call (deprecated)');
  }

  @Deprecated('Use DeviceFingerprintService() instead')
  static Future<void> clearAllFingerprints() async {
    // No-op for backward compatibility
    debugPrint('[DeviceFingerprint] Ignoring clearAllFingerprints call (deprecated)');
  }
}
