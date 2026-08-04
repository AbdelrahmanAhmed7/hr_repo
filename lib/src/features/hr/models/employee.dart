class EmployeeBankInfo {
  final String? bankName;
  final String? accountNumber;
  final String? ibanNumber;
  final String? swiftBicCode;
  final String? branchCode;

  const EmployeeBankInfo({
    this.bankName,
    this.accountNumber,
    this.ibanNumber,
    this.swiftBicCode,
    this.branchCode,
  });

  factory EmployeeBankInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeBankInfo(
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      ibanNumber: json['ibanNumber'] as String?,
      swiftBicCode: json['swiftBicCode'] as String?,
      branchCode: json['branchCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ibanNumber': ibanNumber,
      'swiftBicCode': swiftBicCode,
      'branchCode': branchCode,
    };
  }
}

class EmployeeEducation {
  final int? id;
  final String? universityName;
  final DateTime? graduationYear;
  final String? degree;
  final String? finalGrade;
  final DateTime? createdAt;

  const EmployeeEducation({
    this.id,
    this.universityName,
    this.graduationYear,
    this.degree,
    this.finalGrade,
    this.createdAt,
  });

  factory EmployeeEducation.fromJson(Map<String, dynamic> json) {
    return EmployeeEducation(
      id: json['id'] as int?,
      universityName: json['universityName'] as String?,
      graduationYear: json['graduationYear'] != null
          ? DateTime.tryParse(json['graduationYear'].toString())
          : null,
      degree: json['degree'] as String?,
      finalGrade: json['finalGrade'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class EmployeeAttachment {
  final String? id;
  final String? originalFileName;
  final String? contentType;
  final int? fileSize;
  final DateTime? uploadedAt;
  final String? fileUrl;
  final String? filePath;

  const EmployeeAttachment({
    this.id,
    this.originalFileName,
    this.contentType,
    this.fileSize,
    this.uploadedAt,
    this.fileUrl,
    this.filePath,
  });

  factory EmployeeAttachment.fromJson(Map<String, dynamic> json) {
    return EmployeeAttachment(
      id: json['id']?.toString(),
      originalFileName: json['originalFileName'] as String?,
      contentType: json['contentType'] as String?,
      fileSize: json['fileSize'] as int?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
      fileUrl: json['fileUrl'] as String?,
      filePath: json['filePath'] as String?,
    );
  }
}

class Employee {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final int? departmentId;
  final String? department;
  final int? jobId;
  final String? position;
  final DateTime? hireDate;
  final DateTime? contractEndDate;
  final DateTime? birthDate;
  final String? securityClearance;
  final String? profileImageUrl;
  final String? nationalId;
  final String? gender;
  final bool? isActive;
  final String? role;
  final String? passportNumber;
  final String? machineCode;
  final String? fingerprintKey;
  final String? nationalityName;
  final String? employeeCode;
  final String? branchName;
  final String? jobTitleName;
  final String? managerName;
  final String? maritalStatusName;
  final String? addressAr;
  final String? addressEn;
  final String? employmentModeName;
  final String? governorateName;
  final String? cityName;
  final String? companyPhoneNumber;
  final String? companyEmail;
  final double? grossSalary;
  final int? workType;
  final bool? isPending;
  final EmployeeBankInfo? bankInfo;
  final List<EmployeeEducation> educations;
  final List<EmployeeAttachment> attachments;

  Employee({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.departmentId,
    this.department,
    this.jobId,
    this.position,
    this.hireDate,
    this.contractEndDate,
    this.birthDate,
    this.securityClearance,
    this.profileImageUrl,
    this.nationalId,
    this.gender,
    this.isActive,
    this.role,
    this.passportNumber,
    this.machineCode,
    this.fingerprintKey,
    this.nationalityName,
    this.employeeCode,
    this.branchName,
    this.jobTitleName,
    this.managerName,
    this.maritalStatusName,
    this.addressAr,
    this.addressEn,
    this.employmentModeName,
    this.governorateName,
    this.cityName,
    this.companyPhoneNumber,
    this.companyEmail,
    this.grossSalary,
    this.workType,
    this.isPending,
    this.bankInfo,
    this.educations = const [],
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'departmentId': departmentId,
      'department': department,
      'jobId': jobId,
      'position': position,
      'hireDate': hireDate?.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
      'birthDate': birthDate?.toIso8601String(),
      'securityClearance': securityClearance,
      'profileImageUrl': profileImageUrl,
      'nationalId': nationalId,
      'gender': gender,
      'isActive': isActive,
      'role': role,
      'passportNumber': passportNumber,
      'machineCode': machineCode,
      'fingerprintKey': fingerprintKey,
      'nationalityName': nationalityName,
      'employeeCode': employeeCode,
      'branchName': branchName,
      'jobTitleName': jobTitleName,
      'managerName': managerName,
      'maritalStatusName': maritalStatusName,
      'addressAr': addressAr,
      'addressEn': addressEn,
      'employmentModeName': employmentModeName,
      'governorateName': governorateName,
      'cityName': cityName,
      'companyPhoneNumber': companyPhoneNumber,
      'companyEmail': companyEmail,
      'grossSalary': grossSalary,
      'workType': workType,
      'isPending': isPending,
      'bankInfo': bankInfo?.toJson(),
      'educations': educations
          .map(
            (e) => {
              'id': e.id,
              'universityName': e.universityName,
              'graduationYear': e.graduationYear?.toIso8601String(),
              'degree': e.degree,
              'finalGrade': e.finalGrade,
              'createdAt': e.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'attachments': attachments
          .map(
            (a) => {
              'id': a.id,
              'originalFileName': a.originalFileName,
              'contentType': a.contentType,
              'fileSize': a.fileSize,
              'uploadedAt': a.uploadedAt?.toIso8601String(),
              'fileUrl': a.fileUrl,
              'filePath': a.filePath,
            },
          )
          .toList(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      departmentId: json['departmentId'] as int?,
      department: json['department'] as String?,
      jobId: json['jobId'] as int?,
      position: json['position'] as String?,
      hireDate: json['hireDate'] != null
          ? DateTime.tryParse(json['hireDate'] as String)
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.tryParse(json['contractEndDate'] as String)
          : null,
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'] as String)
          : null,
      securityClearance: json['securityClearance'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      nationalId: json['nationalId'] as String?,
      gender: json['gender'] as String?,
      isActive: json['isActive'] as bool?,
      role: json['role'] as String?,
      passportNumber: json['passportNumber'] as String?,
      machineCode: json['machineCode'] as String?,
      fingerprintKey: json['fingerprintKey'] as String?,
      nationalityName: json['nationalityName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      branchName: json['branchName'] as String?,
      jobTitleName: json['jobTitleName'] as String?,
      managerName: json['managerName'] as String?,
      maritalStatusName: json['maritalStatusName'] as String?,
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      employmentModeName: json['employmentModeName'] as String?,
      governorateName: json['governorateName'] as String?,
      cityName: json['cityName'] as String?,
      companyPhoneNumber: json['companyPhoneNumber'] as String?,
      companyEmail: json['companyEmail'] as String?,
      grossSalary: _toDouble(json['grossSalary']),
      workType: json['workType'] as int?,
      isPending: json['isPending'] as bool?,
      bankInfo: json['bankInfo'] is Map<String, dynamic>
          ? EmployeeBankInfo.fromJson(json['bankInfo'] as Map<String, dynamic>)
          : null,
      educations: (json['educations'] as List<dynamic>? ?? const [])
          .map((item) => EmployeeEducation.fromJson(item as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .map((item) => EmployeeAttachment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory Employee.fromUsersApiJson(Map<String, dynamic> json) {
    final firstNameAr = (json['firstNameAr'] as String?)?.trim();
    final middleNameAr = (json['middleNameAr'] as String?)?.trim();
    final lastNameAr = (json['lastNameAr'] as String?)?.trim();
    final firstNameEn = (json['firstNameEn'] as String?)?.trim();
    final middleNameEn = (json['middleNameEn'] as String?)?.trim();
    final lastNameEn = (json['lastNameEn'] as String?)?.trim();

    final fullName = _buildFullName(
          [firstNameAr, middleNameAr, lastNameAr],
          [firstNameEn, middleNameEn, lastNameEn],
        ) ??
        (json['email'] as String?) ??
        (json['phoneNumber'] as String?) ??
        'موظف';

    final isMale = json['isMale'] as bool?;

    return Employee(
      id: json['id'] as String,
      fullName: fullName,
      phone: (json['phoneNumber'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      departmentId: json['departmentId'] as int?,
      department: json['departmentName'] as String?,
      jobId: json['jobId'] as int?,
      position:
          (json['jobTitleName'] as String?) ?? (json['jobTitle'] as String?),
      hireDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      profileImageUrl: json['imageUrl'] as String?,
      nationalId: json['nationalId'] as String?,
      gender: isMale == null ? null : (isMale ? 'ذكر' : 'أنثى'),
      isActive: json['isActive'] as bool?,
      role: json['role'] as String?,
      employeeCode: json['employeeCode'] as String?,
      jobTitleName: json['jobTitleName'] as String?,
      companyPhoneNumber: json['companyPhoneNumber'] as String?,
      companyEmail: json['companyEmail'] as String?,
      birthDate: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'] as String)
          : null,
      isPending: json['isPending'] as bool?,
      educations: const [],
      attachments: const [],
    );
  }

  factory Employee.fromEmployeeDetailsApiJson(Map<String, dynamic> json) {
    final firstNameAr = (json['firstNameAr'] as String?)?.trim();
    final middleNameAr = (json['middleNameAr'] as String?)?.trim();
    final lastNameAr = (json['lastNameAr'] as String?)?.trim();
    final firstNameEn = (json['firstNameEn'] as String?)?.trim();
    final middleNameEn = (json['middleNameEn'] as String?)?.trim();
    final lastNameEn = (json['lastNameEn'] as String?)?.trim();

    final fullName = _buildFullName(
          [firstNameAr, middleNameAr, lastNameAr],
          [firstNameEn, middleNameEn, lastNameEn],
        ) ??
        (json['email'] as String?) ??
        (json['phoneNumber'] as String?) ??
        'موظف';

    final isMale = json['isMale'] as bool?;

    return Employee(
      id: json['id'] as String,
      fullName: fullName,
      phone: (json['phoneNumber'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      departmentId: json['departmentId'] as int?,
      department: json['departmentName'] as String?,
      jobId: json['jobId'] as int?,
      position: (json['jobTitleName'] as String?) ?? (json['jobTitle'] as String?),
      hireDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.tryParse(json['contractEndDate'] as String)
          : null,
      birthDate: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'] as String)
          : null,
      profileImageUrl: json['imageUrl'] as String?,
      nationalId: json['nationalId'] as String?,
      gender: isMale == null ? null : (isMale ? 'ذكر' : 'أنثى'),
      isActive: json['isActive'] as bool?,
      role: json['role'] as String?,
      passportNumber: json['passportNumber'] as String?,
      machineCode: json['machineCode'] as String?,
      fingerprintKey: json['fingerprintKey'] as String?,
      nationalityName: json['nationalityName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      branchName: json['branchName'] as String?,
      jobTitleName: json['jobTitleName'] as String?,
      managerName: json['managerName'] as String?,
      maritalStatusName: json['maritalStatusName'] as String?,
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      employmentModeName: json['employmentModeName'] as String?,
      governorateName: json['governorateName'] as String?,
      cityName: json['cityName'] as String?,
      companyPhoneNumber: json['companyPhoneNumber'] as String?,
      companyEmail: json['companyEmail'] as String?,
      grossSalary: _toDouble(json['grossSalary']),
      workType: json['workType'] as int?,
      isPending: json['isPending'] as bool?,
      bankInfo: json['bankInfo'] is Map<String, dynamic>
          ? EmployeeBankInfo.fromJson(json['bankInfo'] as Map<String, dynamic>)
          : null,
      educations: (json['educations'] as List<dynamic>? ?? const [])
          .map((item) => EmployeeEducation.fromJson(item as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .map((item) => EmployeeAttachment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Employee copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    int? departmentId,
    String? department,
    int? jobId,
    String? position,
    DateTime? hireDate,
    DateTime? contractEndDate,
    DateTime? birthDate,
    String? securityClearance,
    String? profileImageUrl,
    String? nationalId,
    String? gender,
    bool? isActive,
    String? role,
    String? passportNumber,
    String? machineCode,
    String? fingerprintKey,
    String? nationalityName,
    String? employeeCode,
    String? branchName,
    String? jobTitleName,
    String? managerName,
    String? maritalStatusName,
    String? addressAr,
    String? addressEn,
    String? employmentModeName,
    String? governorateName,
    String? cityName,
    String? companyPhoneNumber,
    String? companyEmail,
    double? grossSalary,
    int? workType,
    bool? isPending,
    EmployeeBankInfo? bankInfo,
    List<EmployeeEducation>? educations,
    List<EmployeeAttachment>? attachments,
  }) {
    return Employee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      jobId: jobId ?? this.jobId,
      position: position ?? this.position,
      hireDate: hireDate ?? this.hireDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      birthDate: birthDate ?? this.birthDate,
      securityClearance: securityClearance ?? this.securityClearance,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      nationalId: nationalId ?? this.nationalId,
      gender: gender ?? this.gender,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      passportNumber: passportNumber ?? this.passportNumber,
      machineCode: machineCode ?? this.machineCode,
      fingerprintKey: fingerprintKey ?? this.fingerprintKey,
      nationalityName: nationalityName ?? this.nationalityName,
      employeeCode: employeeCode ?? this.employeeCode,
      branchName: branchName ?? this.branchName,
      jobTitleName: jobTitleName ?? this.jobTitleName,
      managerName: managerName ?? this.managerName,
      maritalStatusName: maritalStatusName ?? this.maritalStatusName,
      addressAr: addressAr ?? this.addressAr,
      addressEn: addressEn ?? this.addressEn,
      employmentModeName: employmentModeName ?? this.employmentModeName,
      governorateName: governorateName ?? this.governorateName,
      cityName: cityName ?? this.cityName,
      companyPhoneNumber: companyPhoneNumber ?? this.companyPhoneNumber,
      companyEmail: companyEmail ?? this.companyEmail,
      grossSalary: grossSalary ?? this.grossSalary,
      workType: workType ?? this.workType,
      isPending: isPending ?? this.isPending,
      bankInfo: bankInfo ?? this.bankInfo,
      educations: educations ?? this.educations,
      attachments: attachments ?? this.attachments,
    );
  }

  String get initials {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  bool get hasSecurityClearance =>
      securityClearance != null && securityClearance!.isNotEmpty;

  static String? _buildFullName(
    List<String?> arabicParts,
    List<String?> englishParts,
  ) {
    final arabic = arabicParts
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
    if (arabic.isNotEmpty) return arabic;

    final english = englishParts
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
    if (english.isNotEmpty) return english;

    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
