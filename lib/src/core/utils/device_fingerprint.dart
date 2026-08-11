import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';
import '../../features/auth/services/auth_storage_service.dart';

/// Singleton service for deterministic user-based fingerprint generation.
///
/// The fingerprint is derived directly from the authenticated user's:
///   {userId}_{normalizedPhoneNumber}
///
/// It is NOT based on device identifiers and must only be generated AFTER
/// the authenticated user's identity (User ID + Phone Number) is available.
class DeviceFingerprintService {
  // Singleton
  static final DeviceFingerprintService _instance =
      DeviceFingerprintService._internal();
  factory DeviceFingerprintService() => _instance;
  DeviceFingerprintService._internal();

  static const _storage = FlutterSecureStorage();
  static const _fingerprintSource = 'user_id_phone';

  String? _cachedFingerprint;
  String? _cachedForUserId;
  String? _cachedForPhone;
  DateTime? _cachedGeneratedAt;

  Completer<void>? _pendingResolve;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Legacy no-op initializer retained for existing call sites.
  /// The fingerprint now depends on authenticated user data and is resolved
  /// lazily on first use (via [getFingerprint]).
  Future<void> initialize() async {
    debugPrint('[FP_AUDIT] initialize() called — no-op; fingerprint is resolved per authenticated user.');
  }

  /// Return the deterministic fingerprint for the currently authenticated user.
  ///
  /// Throws a [StateError] if the user is not authenticated (no User ID or
  /// Phone Number available from [AuthStorageService]).
  Future<String> getFingerprint() async {
    final resolve = _pendingResolve;
    if (resolve != null && !resolve.isCompleted) {
      await resolve.future;
    }

    final userId = await AuthStorageService.loadUserId();
    final phone = await AuthStorageService.getCurrentUserPhone();

    if (userId == null || userId.isEmpty) {
      throw StateError(
        '[DeviceFingerprintService] Cannot generate fingerprint: no authenticated User ID available.',
      );
    }
    if (phone == null || phone.isEmpty) {
      throw StateError(
        '[DeviceFingerprintService] Cannot generate fingerprint: no authenticated Phone Number available.',
      );
    }

    if (_cachedFingerprint != null &&
        _cachedForUserId == userId &&
        _cachedForPhone == phone) {
      debugPrint(
        '[FP_AUDIT] Cache hit for user $userId — fingerprint=${_fingerprintPreview(_cachedFingerprint!)}',
      );
      return _cachedFingerprint!;
    }

    final completer = Completer<void>();
    _pendingResolve = completer;
    try {
      final fingerprint = generateFingerprint(userId: userId, phoneNumber: phone);

      debugPrint('[FP_AUDIT] User ID: $userId');
      debugPrint('[FP_AUDIT] Phone Number: ${_maskPhone(phone)}');
      debugPrint('[FP_AUDIT] Normalized User ID: $userId');
      debugPrint('[FP_AUDIT] Normalized Phone: ${_maskPhone(phone)}');
      debugPrint('[FP_AUDIT] Fingerprint Source: $_fingerprintSource');
      debugPrint('[FP_AUDIT] Fingerprint: ${_fingerprintPreview(fingerprint)}');

      _cachedFingerprint = fingerprint;
      _cachedForUserId = userId;
      _cachedForPhone = phone;
      _cachedGeneratedAt = DateTime.now();

      await _saveUserScopedFingerprint(userId, fingerprint);

      return fingerprint;
    } finally {
      completer.complete();
      if (identical(_pendingResolve, completer)) _pendingResolve = null;
    }
  }

  /// Diagnostic info for debugging / diagnostic screen.
  Future<Map<String, dynamic>> getDiagnostics() async {
    final userId = await AuthStorageService.loadUserId();
    final phone = await AuthStorageService.getCurrentUserPhone();

    String? fingerprint;
    String? source = 'not_authenticated';
    try {
      fingerprint = await getFingerprint();
      source = _fingerprintSource;
    } catch (_) {}

    return {
      'fingerprint': fingerprint,
      'source': source,
      'generatedAt': _cachedGeneratedAt?.toIso8601String(),
      'isAuthenticated': userId != null && phone != null,
      'userId': userId,
      'phone': phone != null ? _maskPhone(phone) : null,
      'fingerprintFormat': '{userId}_{normalizedPhoneNumber}',
    };
  }

  /// Invalidate cached fingerprint and (optionally) clear user-scoped storage.
  ///
  /// This MUST be called on logout to prevent cross-user fingerprint reuse.
  /// The [userId] parameter identifies whose storage to clear; if omitted
  /// the in-memory cache is simply invalidated.
  Future<void> clearFingerprint({String? userId}) async {
    debugPrint('[FP_AUDIT] clearFingerprint() called. userId=$userId');

    _cachedFingerprint = null;
    _cachedForUserId = null;
    _cachedForPhone = null;
    _cachedGeneratedAt = null;

    if (userId != null && userId.isNotEmpty) {
      await _storage.delete(key: _userScopedStorageKey(userId));
    }
  }

  // ── Core deterministic generation ────────────────────────────────────────

  /// Centralized pure function: `{userId}_{normalizedPhoneNumber}`
  ///
  /// This is the single source of truth for fingerprint format.
  /// Do not duplicate this logic anywhere else.
  static String generateFingerprint({
    required String userId,
    required String phoneNumber,
  }) {
    final normalizedUserId = _normalizeUserId(userId);
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    return '${normalizedUserId}_$normalizedPhone';
  }

  // ── Normalization helpers ────────────────────────────────────────────────

  static String _normalizeUserId(String userId) {
    return userId.trim();
  }

  /// Normalize the phone number to the application's canonical representation.
  ///
  /// Project convention (Egyptian numbers): 11 digits starting with 01.
  /// We trim whitespace, remove `+20` prefix if present, ensure leading 0,
  /// and strip non-digit characters.
  static String _normalizePhoneNumber(String phone) {
    var cleaned = phone.trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.startsWith('+20')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('20') && cleaned.length == 12) {
      cleaned = '0${cleaned.substring(2)}';
    }

    return cleaned;
  }

  // ── Phone masking for logs ───────────────────────────────────────────────

  static String _maskPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 7) {
      return '****';
    }
    final prefix = clean.substring(0, 3);
    final suffix = clean.substring(clean.length - 4);
    return '$prefix****$suffix';
  }

  static String _fingerprintPreview(String fp) {
    if (fp.length <= 12) return fp;
    return '${fp.substring(0, 6)}...${fp.substring(fp.length - 6)}';
  }

  // ── Storage helpers (user-scoped) ────────────────────────────────────────

  static String _userScopedStorageKey(String userId) {
    return '${StorageKeys.fingerprintPrefix}_$userId';
  }

  Future<void> _saveUserScopedFingerprint(String userId, String fingerprint) async {
    try {
      await _storage.write(key: _userScopedStorageKey(userId), value: fingerprint);
    } catch (e) {
      debugPrint('[FP_AUDIT] Warning: failed to persist fingerprint to storage: $e');
    }
  }
}

// ─── Legacy compatibility wrapper ───────────────────────────────────────────

@Deprecated('Use DeviceFingerprintService() instead')
class DeviceFingerprint {
  @Deprecated('Use DeviceFingerprintService().getFingerprint() instead')
  static Future<String> getFingerprintKey(String userId) async {
    return await DeviceFingerprintService().getFingerprint();
  }

  @Deprecated('Use DeviceFingerprintService().clearFingerprint(userId:) instead')
  static Future<void> clearFingerprint(String userId) async {
    await DeviceFingerprintService().clearFingerprint(userId: userId);
  }

  @Deprecated('No longer needed — fingerprints are user-scoped and removed individually')
  static Future<void> clearAllFingerprints() async {
    debugPrint('[DeviceFingerprint] clearAllFingerprints() — no-op in user-based model.');
  }
}
