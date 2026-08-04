import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/models/employee_info.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/network/dio_client.dart';
import '../api/profile_api.dart';
import '../models/profile_response.dart';

/// Service for managing user profile data
class ProfileService {
  final ProfileApi _profileApi;

  ProfileService(DioClient dioClient)
      : _profileApi = ProfileApi(dioClient.dio);

  /// Load user profile from API
  /// Falls back to cached data on error
  Future<EmployeeInfo> loadProfile() async {
    try {
      final response = await _profileApi.getProfile();
      final employeeInfo = _convertToEmployeeInfo(response);
      
      // Cache the profile data
      await employeeInfo.saveToStorage();
      
      return employeeInfo;
    } catch (e) {
      if (kDebugMode) {
        print('ProfileService: Error loading profile from API - $e');
      }
      
      // Try to load from cache
      final cachedProfile = await EmployeeInfo.loadFromStorage();
      if (cachedProfile != null) {
        if (kDebugMode) {
          print('ProfileService: Using cached profile');
        }
        return cachedProfile;
      }

      rethrow;
    }
  }

  /// Convert ProfileResponse to EmployeeInfo
  EmployeeInfo _convertToEmployeeInfo(ProfileResponse response) {
    return EmployeeInfo(
      id: response.id,
      name: response.fullNameAr,
      position: response.jobTitleName ?? response.jobTitle ?? 'موظف',
      department: response.departmentName ?? 'غير محدد',
      email: response.email,
      phone: response.phoneNumber,
      nationalId: response.nationalId,
      gender: response.isMale ? 'ذكر' : 'أنثى',
      machineCode: response.machineCode,
      birthDate: response.birthday != null 
          ? DateTime.tryParse(response.birthday!) 
          : null,
      address: response.addressAr,
      addressEn: response.addressEn,
      city: response.cityName,
      governorate: response.governorateName,
      startDate: response.startDate != null 
          ? DateTime.tryParse(response.startDate!) 
          : null,
      profileImageUrl: response.imageUrl,
      companyEmail: response.companyEmail,
      companyPhone: response.companyPhoneNumber,
      branchName: response.branchName,
      managerName: response.managerName,
      employeeCode: response.employeeCode,
      maritalStatus: response.maritalStatusName,
      nationality: response.nationalityName,
      jobTitleName: response.jobTitleName,
    );
  }

  /// Save user profile to storage
  Future<void> saveProfile(EmployeeInfo profile) async {
    await profile.saveToStorage();
  }

  /// Update profile image path
  Future<void> updateProfileImage(String? imagePath) async {
    final currentProfile = await loadProfile();
    final updatedProfile = currentProfile.copyWith(profileImagePath: imagePath);
    await saveProfile(updatedProfile);
  }

  /// Clear saved profile data
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.userProfile);
  }
}

