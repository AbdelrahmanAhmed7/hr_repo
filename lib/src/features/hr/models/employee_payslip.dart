import 'salary_calculation.dart';

class EmployeePayslip {
  final String? employeeStatusNote;
  final String fullNameAr;
  final String fullNameEn;
  final String departmentName;
  final String? jobTitle;
  final String employmentMode;
  final int month;
  final int year;
  final int actualWorkingDays;
  final SalaryCalculation salaryDetails;

  // Bank info
  final String bankName;
  final String bankAccountNumber;
  final DateTime? issuedAt;

  const EmployeePayslip({
    this.employeeStatusNote,
    required this.fullNameAr,
    required this.fullNameEn,
    required this.departmentName,
    this.jobTitle,
    required this.employmentMode,
    required this.month,
    required this.year,
    required this.actualWorkingDays,
    required this.salaryDetails,
    required this.bankName,
    required this.bankAccountNumber,
    this.issuedAt,
  });

  factory EmployeePayslip.fromJson(Map<String, dynamic> json) {
    String s(String key) => (json[key] ?? '').toString();
    return EmployeePayslip(
      employeeStatusNote: json['employeeStatusNote'] as String?,
      fullNameAr: s('fullNameAr'),
      fullNameEn: s('fullNameEn'),
      departmentName: s('departmentName'),
      jobTitle: json['jobTitle'] as String?,
      employmentMode: s('employmentMode'),
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      actualWorkingDays: (json['actualWorkingDays'] as num?)?.toInt() ?? 0,
      salaryDetails: SalaryCalculation.fromJson(
          json['salaryDetails'] as Map<String, dynamic>? ?? const {}),
      bankName: s('bankName'),
      bankAccountNumber: s('bankAccountNumber'),
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'].toString())
          : null,
    );
  }

  String get displayName =>
      fullNameAr.isNotEmpty ? fullNameAr : fullNameEn;

  String get titleOrFallback {
    if (jobTitle != null && jobTitle!.isNotEmpty) return jobTitle!;
    return 'موظف';
  }
}
