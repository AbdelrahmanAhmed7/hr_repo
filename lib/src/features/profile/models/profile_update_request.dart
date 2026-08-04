import 'dart:io';
import 'package:dio/dio.dart';

class ProfileUpdateRequest {
  final String email;
  final String fullName;
  final String phoneNumber;
  final int departmentId;
  final String jobTitle;
  final String startDate; // Format: YYYY-MM-DD
  final String companyPhoneNumber;
  final String companyEmail;
  final File? image;

  ProfileUpdateRequest({
    this.email = '',
    this.fullName = '',
    this.phoneNumber = '',
    this.departmentId = 0,
    this.jobTitle = '',
    this.startDate = '',
    this.companyPhoneNumber = '',
    this.companyEmail = '',
    this.image,
  });

  Future<FormData> toFormData() async {
    final formData = FormData.fromMap({
      'Email': email,
      'FullName': fullName,
      'PhoneNumber': phoneNumber,
      'DepartmentId': departmentId,
      'JobTitle': jobTitle,
      'StartDate': startDate,
      'CompanyPhoneNumber': companyPhoneNumber,
      'CompanyEmail': companyEmail,
    });

    if (image != null) {
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(image!.path),
      ));
    }

    return formData;
  }
}
