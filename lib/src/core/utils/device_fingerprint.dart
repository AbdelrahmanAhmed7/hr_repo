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

  // ─── DIAGNOSTIC HELPERS ───────────────────────────────────────────────────

  /// Log a diagnostic line with a consistent prefix so it's easy to grep.
  void _diag(String msg) => debugPrint('[FP_DIAG] $msg');

  /// Log an exception with full stack trace so nothing is silently swallowed.
  void _diagException(String site, Object e, StackTrace st) {
    _diag('EXCEPTION in $site');
    _diag('  Type      : ${e.runtimeType}');
    _diag('  Message   : $e');
    _diag('  StackTrace:\n$st');
  }

  // ─── INITIALIZATION ───────────────────────────────────────────────────────

  /// Initialize the service (call at app startup)
  Future<void> initialize() async {
    _diag('initialize() called — _isInitialized=$_isInitialized');

    if (_isInitialized) {
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _diag('initialize() — already in-flight, awaiting existing Completer');
        await _initCompleter!.future;
      } else {
        _diag('initialize() — already done, returning cached value');
      }
      return;
    }

    _initCompleter = Completer<void>();
    try {
      _diag('--- BEGIN FINGERPRINT INITIALIZATION ---');

      // ── Step 1: Try to load from secure storage ──────────────────────────
      _diag(
        'STEP 1: Reading FlutterSecureStorage key "$_keyDeviceFingerprint"',
      );
      String? stored;
      String? storedSource;
      String? storedGeneratedAt;

      try {
        stored = await _storage.read(key: _keyDeviceFingerprint);
        storedSource = await _storage.read(key: _keySource);
        storedGeneratedAt = await _storage.read(key: _keyGeneratedAt);
      } catch (e, st) {
        _diagException('_storage.read() in initialize()', e, st);
        rethrow;
      }

      _diag(
        '  stored value       : ${stored == null ? 'NULL' : (stored.isEmpty ? 'EMPTY STRING' : '"$stored"')}',
      );
      _diag('  stored source      : ${storedSource ?? 'NULL'}');
      _diag('  stored generatedAt : ${storedGeneratedAt ?? 'NULL'}');

      if (stored != null && stored.isNotEmpty) {
        // ── Path A: Load existing ─────────────────────────────────────────
        _diag('PATH: Loaded from SecureStorage (no generation needed)');
        _cachedFingerprint = stored;
        _cachedSource = storedSource ?? 'stored_secure_storage';
        if (storedGeneratedAt != null) {
          try {
            _cachedGeneratedAt = DateTime.parse(storedGeneratedAt);
          } catch (e, st) {
            _diagException('DateTime.parse(storedGeneratedAt)', e, st);
          }
        }
        _diag('  RESULT fingerprint : $_cachedFingerprint');
        _diag('  RESULT source      : $_cachedSource');
        _diag('  RESULT generatedAt : $_cachedGeneratedAt');
      } else {
        // ── Step 2: Try migration ─────────────────────────────────────────
        _diag(
          'STEP 2: SecureStorage empty — attempting migration from old per-user keys',
        );
        final oldFingerprint = await _tryMigrateOldFingerprint();

        if (oldFingerprint != null) {
          // ── Path B: Migrated ──────────────────────────────────────────
          _diag('PATH: Migrated from old per-user key');
          _diag('  Migrated value : $oldFingerprint');
          _cachedFingerprint = oldFingerprint;
          _cachedSource = 'migrated_per_user';
          _cachedGeneratedAt = DateTime.now();
          try {
            await _saveToStorage();
          } catch (e, st) {
            _diagException('_saveToStorage() after migration', e, st);
            rethrow;
          }
          _diag('  RESULT fingerprint : $_cachedFingerprint');
          _diag('  RESULT source      : $_cachedSource');
        } else {
          // ── Step 3: Generate new ──────────────────────────────────────
          _diag('STEP 3: No migration found — generating new fingerprint');
          final (fingerprint, source) = await _generateNewFingerprint();
          _cachedFingerprint = fingerprint;
          _cachedSource = source;
          _cachedGeneratedAt = DateTime.now();
          try {
            await _saveToStorage();
          } catch (e, st) {
            _diagException('_saveToStorage() after generation', e, st);
            rethrow;
          }
          _diag('  RESULT fingerprint : $_cachedFingerprint');
          _diag('  RESULT source      : $_cachedSource');
          _diag('  RESULT generatedAt : $_cachedGeneratedAt');
        }
      }

      _isInitialized = true;
      _initCompleter?.complete();
      _diag('--- END FINGERPRINT INITIALIZATION (success) ---');
    } catch (e, st) {
      _diagException('initialize()', e, st);
      _initCompleter?.completeError(e);
      rethrow;
    }
  }

  // ─── PUBLIC API ───────────────────────────────────────────────────────────

  /// Get the stable device fingerprint
  Future<String> getFingerprint() async {
    await initialize();
    if (_cachedFingerprint == null) {
      _diag(
        'ERROR: getFingerprint() — _cachedFingerprint is null after initialization',
      );
      throw StateError('Device fingerprint not initialized');
    }
    _diag(
      'getFingerprint() returning: $_cachedFingerprint (source: $_cachedSource)',
    );
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

  // ─── PRIVATE: MIGRATION ───────────────────────────────────────────────────

  /// Try to migrate an old per-user fingerprint if exists
  Future<String?> _tryMigrateOldFingerprint() async {
    _diag('_tryMigrateOldFingerprint() — reading all secure storage keys');
    try {
      final allKeys = await _storage.readAll();
      final oldKeys = allKeys.keys
          .where((key) => key.startsWith(StorageKeys.fingerprintPrefix))
          .toList();

      _diag('  Keys with prefix "${StorageKeys.fingerprintPrefix}": $oldKeys');

      if (oldKeys.isNotEmpty) {
        // Take the first one (any of them is fine since we just need a stable value)
        final pickedKey = oldKeys.first;
        final oldValue = allKeys[pickedKey];
        _diag('  Picked key : $pickedKey');
        _diag(
          '  Picked value: ${oldValue == null ? 'NULL' : (oldValue.isEmpty ? 'EMPTY' : '"$oldValue"')}',
        );
        if (oldValue != null && oldValue.isNotEmpty) {
          return oldValue;
        }
      } else {
        _diag('  No old per-user keys found');
      }
    } catch (e, st) {
      _diagException('_tryMigrateOldFingerprint()', e, st);
    }
    return null;
  }

  // ─── PRIVATE: GENERATION ─────────────────────────────────────────────────

  /// Generate a new fingerprint, preferring stable device identifiers
  Future<(String fingerprint, String source)> _generateNewFingerprint() async {
    _diag('_generateNewFingerprint() — platform: $defaultTargetPlatform');

    // ── Android ────────────────────────────────────────────────────────────
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final deviceInfoPlugin = DeviceInfoPlugin();
        final androidInfo = await deviceInfoPlugin.androidInfo;

        // Log every field that could affect uniqueness
        _diag('--- ANDROID DEVICE INFO ---');
        _diag('  Android ID          : "${androidInfo.id}"');
        _diag('  Manufacturer        : "${androidInfo.manufacturer}"');
        _diag('  Brand               : "${androidInfo.brand}"');
        _diag('  Device              : "${androidInfo.device}"');
        _diag('  Model               : "${androidInfo.model}"');
        _diag('  Hardware            : "${androidInfo.hardware}"');
        _diag('  Product             : "${androidInfo.product}"');
        _diag('  Board               : "${androidInfo.board}"');
        _diag('  Build Fingerprint   : "${androidInfo.fingerprint}"');
        _diag('  SDK Version         : ${androidInfo.version.sdkInt}');
        _diag('--- END ANDROID DEVICE INFO ---');

        final androidId = androidInfo.id;

        // ── Warn about known problematic Android ID values ──────────────
        if (androidId.isEmpty) {
          _diag('WARNING: androidInfo.id is EMPTY — falling back to UUID');
        } else if (androidId == '9774d56d682e549c') {
          _diag(
            'WARNING: androidInfo.id is the well-known default "9774d56d682e549c" — '
            'this value is shared by many old/emulator devices and will cause collisions',
          );
        } else if (androidId.toLowerCase() == 'unknown' ||
            androidId.toLowerCase() == 'null' ||
            androidId == '0000000000000000') {
          _diag(
            'WARNING: androidInfo.id is a known placeholder value: "$androidId" — '
            'this may be shared across devices and cause collisions',
          );
        } else {
          _diag(
            '  Android ID appears unique (no known placeholder pattern detected)',
          );
        }

        if (androidId.isNotEmpty) {
          final rawInput = '$androidId-${androidInfo.model}';
          _diag('  Raw fingerprint input : "$rawInput"');
          final formatted = _formatFingerprint(rawInput);
          _diag('  Formatted fingerprint : "$formatted"');
          _diag('  Generation source     : android_id');
          return (formatted, 'android_id');
        }
      } catch (e, st) {
        _diagException(
          '_generateNewFingerprint() — Android DeviceInfoPlugin',
          e,
          st,
        );
        // fall through to UUID fallback below
      }
    }
    // ── iOS ────────────────────────────────────────────────────────────────
    else if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final deviceInfoPlugin = DeviceInfoPlugin();
        final iosInfo = await deviceInfoPlugin.iosInfo;

        _diag('--- IOS DEVICE INFO ---');
        _diag('  identifierForVendor : "${iosInfo.identifierForVendor}"');
        _diag('  Model               : "${iosInfo.model}"');
        _diag('  Name                : "${iosInfo.name}"');
        _diag('  System Version      : "${iosInfo.systemVersion}"');
        _diag('--- END IOS DEVICE INFO ---');

        final identifierForVendor = iosInfo.identifierForVendor;

        if (identifierForVendor == null || identifierForVendor.isEmpty) {
          _diag(
            'WARNING: identifierForVendor is ${identifierForVendor == null ? 'NULL' : 'EMPTY'} — '
            'this happens after app uninstall+reinstall on iOS. Falling back to UUID.',
          );
        } else {
          final rawInput = '$identifierForVendor-${iosInfo.model}';
          _diag('  Raw fingerprint input : "$rawInput"');
          final formatted = _formatFingerprint(rawInput);
          _diag('  Formatted fingerprint : "$formatted"');
          _diag('  Generation source     : ios_identifier_for_vendor');
          return (formatted, 'ios_identifier_for_vendor');
        }
      } catch (e, st) {
        _diagException(
          '_generateNewFingerprint() — iOS DeviceInfoPlugin',
          e,
          st,
        );
        // fall through to UUID fallback below
      }
    } else {
      _diag(
        'Platform is neither Android nor iOS ($defaultTargetPlatform) — skipping device info',
      );
    }

    // ── UUID Fallback ──────────────────────────────────────────────────────
    _diag('PATH: UUID fallback — generating Uuid().v4()');
    final uuid = const Uuid().v4();
    _diag('  Raw UUID              : "$uuid"');
    final formatted = _formatFingerprint(uuid);
    _diag('  Formatted fingerprint : "$formatted"');
    _diag('  Generation source     : generated_uuid');
    return (formatted, 'generated_uuid');
  }

  // ─── PRIVATE: FORMAT ─────────────────────────────────────────────────────

  /// Format the fingerprint consistently.
  ///
  /// ⚠ DIAGNOSTIC NOTE: This method uses `raw.length` (the original input
  /// length) as the substring limit, but it operates on the already-stripped
  /// string. If the stripped string is shorter than `raw.length` this will
  /// throw a RangeError, which in _generateNewFingerprint is caught and causes
  /// a silent fallback to UUID. Log output below will reveal if this happens.
  String _formatFingerprint(String raw) {
    final stripped = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final substringEnd = raw.length > 16 ? 16 : raw.length;

    _diag('  _formatFingerprint() ---');
    _diag('    raw input        : "$raw" (length=${raw.length})');
    _diag('    stripped         : "$stripped" (length=${stripped.length})');
    _diag(
      '    substringEnd     : $substringEnd  ← uses raw.length, NOT stripped.length',
    );

    if (substringEnd > stripped.length) {
      _diag(
        '    ⚠ BUG TRIGGERED: substringEnd ($substringEnd) > stripped.length (${stripped.length})',
      );
      _diag(
        '    ⚠ This will throw RangeError — causing silent UUID fallback in _generateNewFingerprint()',
      );
    }

    final truncated = stripped.substring(0, substringEnd);
    final padded = truncated.padLeft(16, '0');

    _diag('    truncated        : "$truncated"');
    _diag('    final (padded)   : "$padded"');
    _diag('  --- end _formatFingerprint()');

    return padded;
  }

  // ─── PRIVATE: STORAGE ─────────────────────────────────────────────────────

  /// Save fingerprint to secure storage
  Future<void> _saveToStorage() async {
    if (_cachedFingerprint == null) {
      _diag('_saveToStorage() skipped — _cachedFingerprint is null');
      return;
    }
    _diag('_saveToStorage() writing fingerprint to SecureStorage...');
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
    _diag('_saveToStorage() done');
  }

  /// Clear fingerprint (ONLY for TESTING/DIAGNOSTIC USE!)
  /// This will generate a new fingerprint next time initialize() is called
  Future<void> clearFingerprint() async {
    _diag('clearFingerprint() called — wiping all cached + stored values');
    await _storage.delete(key: _keyDeviceFingerprint);
    await _storage.delete(key: _keySource);
    await _storage.delete(key: _keyGeneratedAt);
    _cachedFingerprint = null;
    _cachedSource = null;
    _cachedGeneratedAt = null;
    _isInitialized = false;
    _initCompleter = null;
    _diag('clearFingerprint() done — next initialize() will regenerate');
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
    debugPrint(
      '[DeviceFingerprint] Ignoring clearFingerprint call (deprecated)',
    );
  }

  @Deprecated('Use DeviceFingerprintService() instead')
  static Future<void> clearAllFingerprints() async {
    // No-op for backward compatibility
    debugPrint(
      '[DeviceFingerprint] Ignoring clearAllFingerprints call (deprecated)',
    );
  }
}
