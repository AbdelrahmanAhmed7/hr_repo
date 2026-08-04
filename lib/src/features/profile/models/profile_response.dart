import '../../home/models/employee_info.dart';

class ProfileResponse {
  final String id;
  final String? nationalId;
  final String? passportNumber;
  final String? email;
  final String? firstNameAr;
  final String? middleNameAr;
  final String? lastNameAr;
  final String? firstNameEn;
  final String? middleNameEn;
  final String? lastNameEn;
  final String? machineCode;
  final String? fingerprintKey;
  final int? nationalityId;
  final String? nationalityName;
  final String? employeeCode;
  final int? branchId;
  final String? branchName;
  final int? jobId;
  final String? jobTitleName;
  final String? managerId;
  final String? managerName;
  final int? maritalStatusId;
  final String? maritalStatusName;
  final String? addressAr;
  final String? addressEn;
  final int? employmentModeId;
  final String? employmentModeName;
  final int? governorateId;
  final String? governorateName;
  final int? cityId;
  final String? cityName;
  final bool isActive;
  final bool isDisabled;
  final int workType;
  final int? workFromHomeDays;
  final String phoneNumber;
  final int? departmentId;
  final String? departmentName;
  final String? jobTitle;
  final String? startDate;
  final String? companyPhoneNumber;
  final String? companyEmail;
  final String? imageUrl;
  final String role;
  final bool isMale;
  final bool isPending;
  final String? birthday;

  ProfileResponse({
    required this.id,
    this.nationalId,
    this.passportNumber,
    this.email,
    this.firstNameAr,
    this.middleNameAr,
    this.lastNameAr,
    this.firstNameEn,
    this.middleNameEn,
    this.lastNameEn,
    this.machineCode,
    this.fingerprintKey,
    this.nationalityId,
    this.nationalityName,
    this.employeeCode,
    this.branchId,
    this.branchName,
    this.jobId,
    this.jobTitleName,
    this.managerId,
    this.managerName,
    this.maritalStatusId,
    this.maritalStatusName,
    this.addressAr,
    this.addressEn,
    this.employmentModeId,
    this.employmentModeName,
    this.governorateId,
    this.governorateName,
    this.cityId,
    this.cityName,
    required this.isActive,
    required this.isDisabled,
    required this.workType,
    this.workFromHomeDays,
    required this.phoneNumber,
    this.departmentId,
    this.departmentName,
    this.jobTitle,
    this.startDate,
    this.companyPhoneNumber,
    this.companyEmail,
    this.imageUrl,
    required this.role,
    required this.isMale,
    required this.isPending,
    this.birthday,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    String? cleanImageUrl(String? url) {
      if (url == null) return null;
      // Remove all backticks first, then trim whitespace
      final cleaned = url.replaceAll('`', '').trim();
      return cleaned.isEmpty ? null : cleaned;
    }

    return ProfileResponse(
      id: json['id'] as String,
      nationalId: json['nationalId'] as String?,
      passportNumber: json['passportNumber'] as String?,
      email: json['email'] as String?,
      firstNameAr: json['firstNameAr'] as String?,
      middleNameAr: json['middleNameAr'] as String?,
      lastNameAr: json['lastNameAr'] as String?,
      firstNameEn: json['firstNameEn'] as String?,
      middleNameEn: json['middleNameEn'] as String?,
      lastNameEn: json['lastNameEn'] as String?,
      machineCode: json['machineCode'] as String?,
      fingerprintKey: json['fingerprintKey'] as String?,
      nationalityId: json['nationalityId'] as int?,
      nationalityName: json['nationalityName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      branchId: json['branchId'] as int?,
      branchName: json['branchName'] as String?,
      jobId: json['jobId'] as int?,
      jobTitleName: json['jobTitleName'] as String?,
      managerId: json['managerId'] as String?,
      managerName: json['managerName'] as String?,
      maritalStatusId: json['maritalStatusId'] as int?,
      maritalStatusName: json['maritalStatusName'] as String?,
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      employmentModeId: json['employmentModeId'] as int?,
      employmentModeName: json['employmentModeName'] as String?,
      governorateId: json['governorateId'] as int?,
      governorateName: json['governorateName'] as String?,
      cityId: json['cityId'] as int?,
      cityName: json['cityName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isDisabled: json['isDisabled'] as bool? ?? false,
      workType: json['workType'] as int? ?? 0,
      workFromHomeDays: json['workFromHomeDays'] as int?,
      phoneNumber: json['phoneNumber'] as String,
      departmentId: json['departmentId'] as int?,
      departmentName: json['departmentName'] as String?,
      jobTitle: json['jobTitle'] as String?,
      startDate: json['startDate'] as String?,
      companyPhoneNumber: json['companyPhoneNumber'] as String?,
      companyEmail: json['companyEmail'] as String?,
      imageUrl: cleanImageUrl(json['imageUrl'] as String?),
      role: json['role'] as String? ?? 'User',
      isMale: json['isMale'] as bool? ?? true,
      isPending: json['isPending'] as bool? ?? false,
      birthday: json['birthday'] as String?,
    );
  }

  String get fullNameAr {
    final parts = [firstNameAr, middleNameAr, lastNameAr]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'موظف' : parts.join(' ');
  }

  String get fullNameEn {
    final parts = [firstNameEn, middleNameEn, lastNameEn]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Employee' : parts.join(' ');
  }

  EmployeeInfo toEmployeeInfo() {
    return EmployeeInfo(
      id: id,
      name: fullNameAr,
      position: jobTitleName ?? jobTitle ?? 'موظف',
      department: departmentName ?? 'غير محدد',
      email: email,
      phone: phoneNumber,
      nationalId: nationalId,
      gender: isMale ? 'ذكر' : 'أنثى',
      machineCode: machineCode,
      birthDate: birthday != null ? DateTime.tryParse(birthday!) : null,
      address: addressAr,
      addressEn: addressEn,
      city: cityName,
      governorate: governorateName,
      startDate: startDate != null ? DateTime.tryParse(startDate!) : null,
      profileImageUrl: imageUrl,
      companyEmail: companyEmail,
      companyPhone: companyPhoneNumber,
      branchName: branchName,
      managerName: managerName,
      employeeCode: employeeCode,
      maritalStatus: maritalStatusName,
      nationality: nationalityName,
      jobTitleName: jobTitleName,
    );
  }
}
