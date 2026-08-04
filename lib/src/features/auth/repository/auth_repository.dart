import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mediconsult_internal/src/core/services/push_notification_service.dart';
import '../services/auth_api_service.dart';
import '../services/auth_storage_service.dart';
import '../cubit/auth_state.dart';
import '../auth_validators.dart';

/// Repository layer for Auth feature
/// Handles business logic and coordinates between API service and storage service
class AuthRepository {
  final AuthApiService _authApiService;

  AuthRepository({
    required AuthApiService authApiService,
  }) : _authApiService = authApiService;

  /// Load saved auth state from storage
  Future<AuthState> loadAuthState() async {
    return await AuthStorageService.loadAuthState();
  }

  /// Login with phone number and password
  /// Returns AuthState on success, throws exception on failure
  Future<AuthState> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final passError = AuthValidators.validatePassword(password);
      if (passError != null) throw Exception(passError);

      if (kDebugMode) {
        print('AuthRepository.login: Calling API service...');
      }
      final response = await _authApiService.login(
        phoneNumber: phoneNumber.trim(),
        password: password,
      );

      if (kDebugMode) {
        print('AuthRepository.login: API response received - role="${response.role}"');
      }

      // Map role from API response to UserRole enum
      final roleFromApi = response.role.trim().toLowerCase();
      final userRole = _mapRoleFromApi(roleFromApi);
      if (kDebugMode) {
        print('AuthRepository.login: Mapped role: $userRole');
      }

      final resolvedUserId =
          AuthStorageService.extractUserIdFromToken(response.accessToken) ??
          phoneNumber.trim();

      // Save to secure storage
      if (kDebugMode) {
        print('AuthRepository.login: Saving to storage...');
      }
      await AuthStorageService.saveAuthState(
        userId: resolvedUserId,
        token: response.accessToken,
        role: userRole,
        phone: phoneNumber.trim(),
        expiresAt: response.expiresAt,
      );
      if (kDebugMode) {
        print('AuthRepository.login: Saved to storage');
      }

      PushNotificationService.instance.syncTokenWithBackend();

      // Return the new auth state
      final authState = AuthState(
        isAuthenticated: true,
        userId: resolvedUserId,
        token: response.accessToken,
        role: userRole,
      );
      if (kDebugMode) {
        print('AuthRepository.login: Returning AuthState - isAuth=${authState.isAuthenticated}, role=${authState.role}');
      }
      return authState;
    } on DioException {
      rethrow;
    } catch (e) {
      // For any other exceptions, rethrow them
      rethrow;
    }
  }

  /// Logout - clear auth state
  Future<void> logout() async {
    await AuthStorageService.clearAuthState();
  }

  /// Request password reset (forgot password)
  Future<String> forgotPassword({
    required String phoneNumber,
  }) async {
    try {
      final phoneError = AuthValidators.validatePhone(phoneNumber);
      if (phoneError != null) throw Exception(phoneError);

      final response = await _authApiService.forgotPassword(
        phoneNumber: phoneNumber,
      );
      return response.message;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        throw Exception('invalid_credentials');
      }
      rethrow;
    }
  }

  /// Reset password with new password
  Future<String> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final phoneError = AuthValidators.validatePhone(phoneNumber);
      final otpError = AuthValidators.validateOtp(otp);
      if (phoneError != null) throw Exception(phoneError);
      if (otpError != null) throw Exception(otpError);
      if (newPassword.trim().isEmpty) throw Exception('أدخل كلمة المرور الجديدة');
      if (confirmNewPassword.trim().isEmpty) throw Exception('أكد كلمة المرور الجديدة');
      if (newPassword.trim() != confirmNewPassword.trim()) {
        throw Exception('كلمة المرور غير متطابقة');
      }

      final response = await _authApiService.resetPassword(
        phoneNumber: phoneNumber,
        otp: otp,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      return response.message;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('invalid_data');
      }
      rethrow;
    }
  }

  Future<String> verifyResetOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final phoneError = AuthValidators.validatePhone(phoneNumber);
      final otpError = AuthValidators.validateOtp(otp);
      if (phoneError != null) throw Exception(phoneError);
      if (otpError != null) throw Exception(otpError);

      final response = await _authApiService.verifyResetOtp(
        phoneNumber: phoneNumber,
        otp: otp,
      );
      return response.message;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('invalid_otp');
      }
      rethrow;
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _authApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      return response.message;
    } on DioException catch (e) {
      final data = e.response?.data;
      final title = data is Map<String, dynamic> ? data['title']?.toString() : null;

      if (e.response?.statusCode == 400) {
        if (title == 'Current password is incorrect.') {
          throw Exception('incorrect_current_password');
        }
        if (title == 'New password and confirm new password do not match.') {
          throw Exception('password_mismatch');
        }
        throw Exception(title ?? 'invalid_change_password_data');
      }

      rethrow;
    }
  }

  /// Map role string from API to UserRole enum
  UserRole _mapRoleFromApi(String role) {
    switch (role) {
      case 'hr':
        return UserRole.hr;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }
}
