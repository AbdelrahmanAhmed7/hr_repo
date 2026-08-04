import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';

class EmployeeInfo {
  final String? id;
  final String name;
  final String department;
  final String position;
  final String? profileImageUrl;
  final String? profileImagePath; // Local file path
  final int notificationCount;
  
  // Personal information fields (editable)
  final String? phone;
  final String? email;
  final String? nationalId;
  final DateTime? birthDate;
  final String? gender;
  final String? machineCode;
  
  // Company information fields (non-editable)
  final DateTime? hireDate; // تاريخ البداية
  final DateTime? startDate; // تاريخ البداية (من API)
  final String? address;
  final String? addressEn;
  final String? city;
  final String? governorate;
  final String? companyEmail;
  final String? companyPhone;
  final String? branchName;
  final String? managerName;
  final String? employeeCode;
  final String? maritalStatus;
  final String? nationality;
  final String? jobTitleName;

  EmployeeInfo({
    this.id,
    required this.name,
    required this.department,
    required this.position,
    this.profileImageUrl,
    this.profileImagePath,
    this.notificationCount = 0,
    this.phone,
    this.email,
    this.nationalId,
    this.birthDate,
    this.gender,
    this.machineCode,
    this.hireDate,
    this.startDate,
    this.address,
    this.addressEn,
    this.city,
    this.governorate,
    this.companyEmail,
    this.companyPhone,
    this.branchName,
    this.managerName,
    this.employeeCode,
    this.maritalStatus,
    this.nationality,
    this.jobTitleName,
  });

  EmployeeInfo copyWith({
    String? id,
    String? name,
    String? department,
    String? position,
    String? profileImageUrl,
    String? profileImagePath,
    int? notificationCount,
    String? phone,
    String? email,
    String? nationalId,
    DateTime? birthDate,
    String? gender,
    String? machineCode,
    DateTime? hireDate,
    DateTime? startDate,
    String? address,
    String? addressEn,
    String? city,
    String? governorate,
    String? companyEmail,
    String? companyPhone,
    String? branchName,
    String? managerName,
    String? employeeCode,
    String? maritalStatus,
    String? nationality,
    String? jobTitleName,
  }) {
    return EmployeeInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      position: position ?? this.position,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      notificationCount: notificationCount ?? this.notificationCount,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      machineCode: machineCode ?? this.machineCode,
      hireDate: hireDate ?? this.hireDate,
      startDate: startDate ?? this.startDate,
      address: address ?? this.address,
      addressEn: addressEn ?? this.addressEn,
      city: city ?? this.city,
      governorate: governorate ?? this.governorate,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      branchName: branchName ?? this.branchName,
      managerName: managerName ?? this.managerName,
      employeeCode: employeeCode ?? this.employeeCode,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      nationality: nationality ?? this.nationality,
      jobTitleName: jobTitleName ?? this.jobTitleName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'position': position,
      'profileImageUrl': profileImageUrl,
      'profileImagePath': profileImagePath,
      'notificationCount': notificationCount,
      'phone': phone,
      'email': email,
      'nationalId': nationalId,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'machineCode': machineCode,
      'hireDate': hireDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'address': address,
      'addressEn': addressEn,
      'city': city,
      'governorate': governorate,
      'companyEmail': companyEmail,
      'companyPhone': companyPhone,
      'branchName': branchName,
      'managerName': managerName,
      'employeeCode': employeeCode,
      'maritalStatus': maritalStatus,
      'nationality': nationality,
      'jobTitleName': jobTitleName,
    };
  }

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    String? cleanImageUrl(String? url) {
      if (url == null) return null;
      // Remove all backticks first, then trim whitespace
      final cleaned = url.replaceAll('`', '').trim();
      return cleaned.isEmpty ? null : cleaned;
    }

    return EmployeeInfo(
      id: json['id'] as String?,
      name: json['name'] as String,
      department: json['department'] as String,
      position: json['position'] as String,
      profileImageUrl: cleanImageUrl(json['profileImageUrl'] as String?),
      profileImagePath: json['profileImagePath'] as String?,
      notificationCount: json['notificationCount'] as int? ?? 0,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      nationalId: json['nationalId'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      gender: json['gender'] as String?,
      machineCode: json['machineCode'] as String?,
      hireDate: json['hireDate'] != null
          ? DateTime.parse(json['hireDate'] as String)
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      address: json['address'] as String?,
      addressEn: json['addressEn'] as String?,
      city: json['city'] as String?,
      governorate: json['governorate'] as String?,
      companyEmail: json['companyEmail'] as String?,
      companyPhone: json['companyPhone'] as String?,
      branchName: json['branchName'] as String?,
      managerName: json['managerName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      nationality: json['nationality'] as String?,
      jobTitleName: json['jobTitleName'] as String?,
    );
  }



  // Save to SharedPreferences
  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(toJson());
    await prefs.setString(StorageKeys.userProfile, jsonString);
  }

  // Load from SharedPreferences
  static Future<EmployeeInfo?> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(StorageKeys.userProfile);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return EmployeeInfo.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}


