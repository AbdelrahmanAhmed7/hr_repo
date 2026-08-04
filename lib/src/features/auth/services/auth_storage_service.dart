import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_status.dart';
import '../cubit/auth_state.dart';
import '../../../core/constants/storage_keys.dart';

/// Service for handling authentication-related storage operations
class AuthStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static UserRole? _parseRole(String? roleString) {
    if (roleString == null) return null;
    switch (roleString) {
      case 'superAdmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'hr':
        return UserRole.hr;
      case 'user':
        return UserRole.user;
      default:
        // tolerate backend variants like "HR"
        final normalized = roleString.trim().toLowerCase();
        if (normalized == 'hr') return UserRole.hr;
        if (normalized == 'admin') return UserRole.admin;
        if (normalized == 'superadmin') return UserRole.superAdmin;
        if (normalized == 'user') return UserRole.user;
        return null;
    }
  }

  static String _roleToString(UserRole role) {
    if (role == UserRole.superAdmin) return 'superAdmin';
    if (role == UserRole.admin) return 'admin';
    if (role == UserRole.hr) return 'hr';
    return 'user';
  }

  static String? extractUserIdFromToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      final rawUserId =
          claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          claims['sub'];

      final userId = rawUserId?.toString().trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikeGuid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed);
  }

  /// Load saved auth state from secure storage (secrets) + SharedPreferences (account status)
  static Future<AuthState> loadAuthState() async {
    try {
      final token = await _secureStorage.read(key: StorageKeys.authToken);
      var userId = await _secureStorage.read(key: StorageKeys.authUserId);
      final roleString = await _secureStorage.read(key: StorageKeys.authRole);
      final role = _parseRole(roleString);

      final tokenUserId = extractUserIdFromToken(token);
      if (!_looksLikeGuid(userId) && tokenUserId != null) {
        userId = tokenUserId;
        await _secureStorage.write(key: StorageKeys.authUserId, value: userId);
      }
      
      final isAuthenticated = token != null && token.isNotEmpty;
      
      // Load account status based on user's phone (if available)
      AccountStatus? accountStatus;
      final userPhone = await _secureStorage.read(key: StorageKeys.authUserPhone);
      if (userPhone != null) {
        final prefs = await SharedPreferences.getInstance();
        final accountStatusString = prefs.getString('${StorageKeys.authAccountStatus}_$userPhone');
        accountStatus = accountStatusString != null
            ? (accountStatusString == 'pending'
                ? AccountStatus.pending
                : accountStatusString == 'approved'
                    ? AccountStatus.approved
                    : AccountStatus.rejected)
            : null;
      }

      return AuthState(
        isAuthenticated: isAuthenticated,
        userId: userId,
        token: token,
        role: role,
        accountStatus: accountStatus,
      );
    } catch (e) {
      return const AuthState();
    }
  }

  /// Save auth state to secure storage (secrets) + SharedPreferences (account status)
  static Future<void> saveAuthState({
    required String userId,
    required String token,
    required UserRole role,
    required String phone,
    DateTime? expiresAt,
    AccountStatus? accountStatus,
  }) async {
    // We no longer explicitly save 'authIsAuthenticated'. 
    // Presence of 'token' implies authentication.
    await _secureStorage.write(key: StorageKeys.authUserId, value: userId);
    await _secureStorage.write(key: StorageKeys.authToken, value: token);
    await _secureStorage.write(key: StorageKeys.authUserPhone, value: phone);
    await _secureStorage.write(key: StorageKeys.authRole, value: _roleToString(role));
    if (expiresAt != null) {
      await _secureStorage.write(
        key: StorageKeys.authExpiresAt,
        value: expiresAt.toUtc().toIso8601String(),
      );
    }
    
    if (accountStatus != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${StorageKeys.authAccountStatus}_$phone',
        accountStatus.name,
      );
    }
  }

  /// Clear auth state from secure storage
  static Future<void> clearAuthState() async {
    // Delete the token to invalidate session
    await _secureStorage.delete(key: StorageKeys.authToken);
    // Delete other auth data
    await _secureStorage.delete(key: StorageKeys.authIsAuthenticated); // Clean up legacy key if exists
    await _secureStorage.delete(key: StorageKeys.authUserId);
    await _secureStorage.delete(key: StorageKeys.authToken);
    await _secureStorage.delete(key: StorageKeys.authRole);
    await _secureStorage.delete(key: StorageKeys.authUserPhone);
    await _secureStorage.delete(key: StorageKeys.authExpiresAt);
    // Note: We don't remove accountStatus to maintain the approval state
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: StorageKeys.authToken);
  }

  static Future<DateTime?> getExpiresAt() async {
    final s = await _secureStorage.read(key: StorageKeys.authExpiresAt);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  /// Get account status for a specific phone
  static Future<AccountStatus?> getAccountStatus(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountStatusString = prefs.getString('${StorageKeys.authAccountStatus}_$phone');
      if (accountStatusString == null) return null;
      
      switch (accountStatusString) {
        case 'pending':
          return AccountStatus.pending;
        case 'approved':
          return AccountStatus.approved;
        case 'rejected':
          return AccountStatus.rejected;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Set account status for a specific phone
  static Future<void> setAccountStatus(String phone, AccountStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${StorageKeys.authAccountStatus}_$phone', status.name);
  }

  /// Get current user phone
  static Future<String?> getCurrentUserPhone() async {
    return await _secureStorage.read(key: StorageKeys.authUserPhone);
  }
}
