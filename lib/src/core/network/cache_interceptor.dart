import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Cache successful GET requests
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = '${response.requestOptions.method}:${response.requestOptions.uri}';
        await prefs.setString(cacheKey, jsonEncode(response.data));
      } catch (_) {
        // Ignore caching errors
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Attempt fallback to cache for offline/timeout errors
    if (err.requestOptions.method == 'GET') {
      if (err.type == DioExceptionType.connectionTimeout || 
          err.type == DioExceptionType.receiveTimeout || 
          err.type == DioExceptionType.connectionError ||
          err.type == DioExceptionType.unknown) {
        
        try {
          final prefs = await SharedPreferences.getInstance();
          final cacheKey = '${err.requestOptions.method}:${err.requestOptions.uri}';
          final cachedData = prefs.getString(cacheKey);
          
          if (cachedData != null) {
            final data = jsonDecode(cachedData);
            return handler.resolve(
              Response(
                requestOptions: err.requestOptions,
                data: data,
                statusCode: 200,
                statusMessage: 'Cached Data',
              )
            );
          }
        } catch (_) {
          // Ignore cache decoding errors
        }
      }
    }
    
    // If no cache or not a network error, pass the error forward
    handler.next(err);
  }
}
