import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/login_request.dart';
import 'models/login_response.dart';
import 'models/forgot_password_request.dart';
import 'models/message_response.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/api/auth/login')
  @Headers({
    'Content-Type': 'application/json',
    'Accept': 'text/plain',
  })
  Future<LoginResponse> login(@Body() LoginRequest body);

  @POST('/api/Auth/forgot-password')
  Future<MessageResponse> forgotPassword(@Body() ForgotPasswordRequest body);

  @POST('/api/Auth/verify-reset-otp')
  Future<MessageResponse> verifyResetOtp(@Body() Map<String, dynamic> body);

  @POST('/api/Auth/reset-password')
  Future<MessageResponse> resetPassword(@Body() Map<String, dynamic> body);

  @POST('/api/Auth/change-password')
  Future<MessageResponse> changePassword(@Body() Map<String, dynamic> body);
}
