import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_exception.dart';
import '../api/profile_api.dart';
import '../models/profile_response.dart';

class ProfileRepository {
  final ProfileApi _profileApi;
  final Dio _dio;

  ProfileRepository(DioClient dioClient)
    : _profileApi = ProfileApi(dioClient.dio),
      _dio = dioClient.dio;

  Future<ProfileResponse> getProfile() async {
    try {
      final response = await _profileApi.getProfile();
      return response;
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(AppException.from(e).message);
    }
  }

  String _extractErrorMessage(dynamic e) {
    String errorMessage = 'An unexpected error occurred';
    if (e is DioException) {
      try {
        if (e.response?.data != null) {
          final data = e.response!.data;
          Map<String, dynamic> responseData;
          if (data is Map) {
            responseData = Map<String, dynamic>.from(data);
          } else if (data is String) {
            responseData = jsonDecode(data);
          } else {
            responseData = {};
          }
          if (responseData.containsKey('errors') &&
              responseData['errors'] is Map) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.first.first;
          } else if (responseData.containsKey('title') &&
              responseData['title'] != null) {
            errorMessage = responseData['title'].toString();
          } else if (responseData.containsKey('message') &&
              responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      } catch (parseError) {
        if (kDebugMode) {
          print('Error parsing API response: $parseError');
        }
      }
    }
    return errorMessage;
  }

  Future<void> updateProfile({
    String? email,
    String? fullName,
    String? phoneNumber,
    int? departmentId,
    String? jobTitle,
    String? startDate,
    String? companyPhoneNumber,
    String? companyEmail,
    File? image, // Now typed explicitly as File?
  }) async {
    try {
      // Build FormData manually so File → MultipartFile conversion is explicit
      final formData = FormData();

      void addField(String key, String? value) {
        if (value != null && value.isNotEmpty) {
          formData.fields.add(MapEntry(key, value));
        }
      }

      addField('Email', email);
      addField('FullName', fullName);
      addField('PhoneNumber', phoneNumber);
      addField('JobTitle', jobTitle);
      addField('StartDate', startDate);
      addField('CompanyPhoneNumber', companyPhoneNumber);
      addField('CompanyEmail', companyEmail);
      if (departmentId != null) {
        formData.fields.add(MapEntry('DepartmentId', departmentId.toString()));
      }

      if (image != null) {
        final fileName = image.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(image.path, filename: fileName),
          ),
        );
      }

      if (kDebugMode) {
        print('=== updateProfile FormData fields ===');
        for (final f in formData.fields) {
          print('  ${f.key}: ${f.value}');
        }
        print('  image files count: \${formData.files.length}');
      }

      final response = await _dio.put(
        '/api/Auth/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (kDebugMode) {
        print('=== updateProfile response: \${response.statusCode} ===');
        print(response.data);
      }

      // 200 or 204 are both success
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return;
      }

      throw Exception('فشل تحديث الملف الشخصي');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== updateProfile DioException ===');
        print('statusCode: \${e.response?.statusCode}');
        print('data: \${e.response?.data}');
      }
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) print('=== updateProfile error: \$e ===');
      throw Exception(AppException.from(e).message);
    }
  }
}
