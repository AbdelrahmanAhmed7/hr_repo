import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/services/auth_storage_service.dart';
import 'cache_interceptor.dart';

class DioClient {
  static const bool _enableNetworkLogs =
      bool.fromEnvironment('ENABLE_NETWORK_LOGS');
  static const bool _allowBadCertificates =
      bool.fromEnvironment('ALLOW_BAD_CERT') || bool.fromEnvironment('ALLOW_BAD_CERTIFICATES');

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://hr-api.mediconsulteg.com',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const <String, String>{
          // Default headers; some endpoints (like login) override via Retrofit @Headers
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (kDebugMode || _allowBadCertificates) {
      final adapter = _dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (certificate, host, port) {
            return true; // Accept all bad certificates when flag is enabled
          };
          return client;
        };
      }
    }

    // Basic request/response logger. Enable in release with:
    // --dart-define=ENABLE_NETWORK_LOGS=true
    if (kDebugMode || _enableNetworkLogs) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (Object obj) {
            // ignore: avoid_print
            print(obj);
          },
        ),
      );
    }

    // Normalize text/plain responses (some backend endpoints return JSON as plain text).
    _dio.interceptors.add(_PlainTextJsonInterceptor());

    // Fallback offline cache interceptor
    _dio.interceptors.add(CacheInterceptor());

    // Token interceptor - adds Bearer token to requests
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - token expired or invalid
          if (error.response?.statusCode == 401) {
            if (kDebugMode) {
              print('DioClient: 401 Unauthorized - clearing auth and triggering logout');
            }
            
            // Clear auth state
            await AuthStorageService.clearAuthState();
            
            // Notify listeners about auth failure
            _authErrorController.add(AuthError.unauthorized);
            
            // Don't retry, just pass the error
            handler.next(error);
            return;
          }
          
          // Handle 403 Forbidden - user doesn't have permission
          if (error.response?.statusCode == 403) {
            if (kDebugMode) {
              print('DioClient: 403 Forbidden - user lacks permission for this resource');
            }
            
            // Notify listeners about permission error
            _authErrorController.add(AuthError.forbidden);
            
            handler.next(error);
            return;
          }
          
          // Pass other errors through
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;

  Dio get dio => _dio;
  
  // Stream to notify about auth errors
  static final _authErrorController = StreamController<AuthError>.broadcast();
  static Stream<AuthError> get authErrorStream => _authErrorController.stream;
}

enum AuthError {
  unauthorized,
  forbidden,
}

class _PlainTextJsonInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is String) {
      final trimmed = data.trim();

      // 1) If it's JSON, decode it so Retrofit can parse into models.
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          response.data = dioDecodeJson(trimmed);
          handler.next(response);
          return;
        } catch (_) {
          // fall through to message wrapping below
        }
      }

      // 2) Some endpoints may return a plain message string. Wrap it to match MessageResponse.
      final path = response.requestOptions.path.toLowerCase();
      if (path.contains('/api/auth/forgot-password') ||
          path.contains('/api/auth/verify-reset-otp') ||
          path.contains('/api/auth/reset-password') ||
          path.contains('/api/auth/change-password')) {
        response.data = <String, dynamic>{'message': trimmed};
      }
    }

    handler.next(response);
  }

  dynamic dioDecodeJson(String input) {
    // Delayed import avoidance not needed; keep small helper here.
    // ignore: avoid_dynamic_calls
    return jsonDecode(input);
  }
}
