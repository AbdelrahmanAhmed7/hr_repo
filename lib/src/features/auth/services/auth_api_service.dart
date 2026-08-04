import 'package:dio/dio.dart';
import '../api/auth_api.dart';
import '../api/models/login_request.dart';
import '../api/models/login_response.dart';
import '../api/models/forgot_password_request.dart';
import '../api/models/message_response.dart';

/// Service layer for Auth API calls
/// This service handles all API communication for authentication
class AuthApiService {
  final AuthApi _authApi;

  AuthApiService(this._authApi);

  /// Login with phone number and password
  Future<LoginResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final request = LoginRequest(
        phoneNumber: phoneNumber,
        password: password,
      );
      return await _authApi.login(request);
    } on DioException {
      // Re-throw with more context if needed
      rethrow;
    }
  }

  /// Request password reset (forgot password)
  Future<MessageResponse> forgotPassword({
    required String phoneNumber,
  }) async {
    try {
      final request = ForgotPasswordRequest(
        phoneNumber: phoneNumber,
      );
      return await _authApi.forgotPassword(request);
    } on DioException {
      rethrow;
    }
  }

  /// Reset password with new password
  Future<MessageResponse> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      return await _authApi.resetPassword({
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });
    } on DioException {
      rethrow;
    }
  }

  Future<MessageResponse> verifyResetOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      return await _authApi.verifyResetOtp({
        'phoneNumber': phoneNumber,
        'otp': otp,
      });
    } on DioException {
      rethrow;
    }
  }

  Future<MessageResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      return await _authApi.changePassword({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });
    } on DioException {
      rethrow;
    }
  }
}
