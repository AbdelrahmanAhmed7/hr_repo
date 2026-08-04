class EmployeeUpsertRequest {
  final String? nationalId;
  final String? passportNumber;
  final String? employeeCode;
  final String? password;
  final String? firstNameAr;
  final String? middleNameAr;
  final String? lastNameAr;
  final String? firstNameEn;
  final String? middleNameEn;
  final String? lastNameEn;
  final bool? isMale;
  final DateTime? birthday;
  final String? phoneNumber;
  final String? email;
  final String? addressAr;
  final String? addressEn;
  final int? departmentId;
  final int? branchId;
  final int? jobId;
  final DateTime? startDate;
  final DateTime? contractEndDate;
  final bool? isActive;
  final String? companyEmail;
  final String? companyPhoneNumber;

  const EmployeeUpsertRequest({
    this.nationalId,
    this.passportNumber,
    this.employeeCode,
    this.password,
    this.firstNameAr,
    this.middleNameAr,
    this.lastNameAr,
    this.firstNameEn,
    this.middleNameEn,
    this.lastNameEn,
    this.isMale,
    this.birthday,
    this.phoneNumber,
    this.email,
    this.addressAr,
    this.addressEn,
    this.departmentId,
    this.branchId,
    this.jobId,
    this.startDate,
    this.contractEndDate,
    this.isActive,
    this.companyEmail,
    this.companyPhoneNumber,
  });

  Map<String, dynamic> toFormMap() {
    final map = <String, dynamic>{};

    void add(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      map[key] = value;
    }

    add('NationalId', nationalId);
    add('PassportNumber', passportNumber);
    add('EmployeeCode', employeeCode);
    add('Password', password);
    add('FirstNameAr', firstNameAr);
    add('MiddleNameAr', middleNameAr);
    add('LastNameAr', lastNameAr);
    add('FirstNameEn', firstNameEn);
    add('MiddleNameEn', middleNameEn);
    add('LastNameEn', lastNameEn);
    add('IsMale', isMale);
    add('Birthday', _formatDate(birthday));
    add('PhoneNumber', phoneNumber);
    add('Email', email);
    add('AddressAr', addressAr);
    add('AddressEn', addressEn);
    add('DepartmentId', departmentId);
    add('BranchId', branchId);
    add('JobId', jobId);
    add('StartDate', _formatDate(startDate));
    add('ContractEndDate', _formatDate(contractEndDate));
    add('IsActive', isActive);
    add('CompanyEmail', companyEmail);
    add('CompanyPhoneNumber', companyPhoneNumber);

    return map;
  }

  static String? _formatDate(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
