import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/profile_response.dart';

part 'profile_api.g.dart';

@RestApi()
abstract class ProfileApi {
  factory ProfileApi(Dio dio, {String baseUrl}) = _ProfileApi;

  @GET('/api/Auth/profile')
  Future<ProfileResponse> getProfile();

  @PUT('/api/Auth/profile')
  @MultiPart()
  Future<void> updateProfile({
    @Part(name: 'Email') String? email,
    @Part(name: 'FullName') String? fullName,
    @Part(name: 'PhoneNumber') String? phoneNumber,
    @Part(name: 'DepartmentId') int? departmentId,
    @Part(name: 'JobTitle') String? jobTitle,
    @Part(name: 'StartDate') String? startDate,
    @Part(name: 'CompanyPhoneNumber') String? companyPhoneNumber,
    @Part(name: 'CompanyEmail') String? companyEmail,
    @Part(name: 'image') dynamic image,
  });
}
