import 'dart:io';
import 'package:dio/dio.dart';

/// Unified error handling for the entire app.
/// Converts raw exceptions into user-friendly Arabic messages.
class AppException implements Exception {
  final String message;
  final String? debugMessage;
  final int? statusCode;

  const AppException({
    required this.message,
    this.debugMessage,
    this.statusCode,
  });

  @override
  String toString() => message;

  /// Creates an [AppException] from any exception type.
  /// Provides user-friendly Arabic messages for common error scenarios.
  factory AppException.from(Object error, {String? fallbackMessage}) {
    if (error is AppException) return error;

    if (error is DioException) {
      return _fromDio(error, fallbackMessage: fallbackMessage);
    }

    if (error is SocketException) {
      return const AppException(
        message: 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى.',
        debugMessage: 'SocketException',
      );
    }

    if (error is FormatException) {
      return AppException(
        message: fallbackMessage ?? 'خطأ في معالجة البيانات.',
        debugMessage: 'FormatException: ${error.message}',
      );
    }

    return AppException(
      message: fallbackMessage ?? 'حدث خطأ غير متوقع. حاول مرة أخرى.',
      debugMessage: error.toString(),
    );
  }

  static AppException _fromDio(DioException error, {String? fallbackMessage}) {
    // Try to extract server error message
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final serverMessage = data['title'] as String? ??
          data['message'] as String? ??
          data['error'] as String?;
      if (serverMessage != null && serverMessage.trim().isNotEmpty) {
        return AppException(
          message: serverMessage,
          statusCode: error.response?.statusCode,
          debugMessage: 'DioException: ${error.type}',
        );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          message: 'انتهت مهلة الاتصال. تأكد من سرعة الإنترنت.',
          debugMessage: 'Timeout',
        );

      case DioExceptionType.connectionError:
        return const AppException(
          message: 'تعذر الاتصال بالسيرفر. تأكد من اتصالك بالإنترنت.',
          debugMessage: 'ConnectionError',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return AppException(
              message: fallbackMessage ?? 'البيانات المدخلة غير صحيحة.',
              statusCode: 400,
            );
          case 401:
            return const AppException(
              message: 'انتهت صلاحية الجلسة. سجّل الدخول مرة أخرى.',
              statusCode: 401,
            );
          case 403:
            return const AppException(
              message: 'لا تملك صلاحية لتنفيذ هذا الإجراء.',
              statusCode: 403,
            );
          case 404:
            return AppException(
              message: fallbackMessage ?? 'لم يتم العثور على البيانات المطلوبة.',
              statusCode: 404,
            );
          case 500:
          case 502:
          case 503:
            return const AppException(
              message: 'خطأ في السيرفر. حاول مرة أخرى لاحقاً.',
              statusCode: 500,
            );
          default:
            return AppException(
              message: fallbackMessage ?? 'حدث خطأ غير متوقع (رمز: $statusCode).',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return const AppException(
          message: 'تم إلغاء العملية.',
          debugMessage: 'Cancelled',
        );

      default:
        return AppException(
          message: fallbackMessage ?? 'حدث خطأ غير متوقع. حاول مرة أخرى.',
          debugMessage: 'DioException: ${error.type}',
        );
    }
  }
}
