class Payslip {
  final String? employeeStatusNote;
  final String fullNameAr;
  final String fullNameEn;
  final String? departmentName;
  final String? jobTitle;
  final String? employmentMode;
  final int month;
  final int year;
  final int actualWorkingDays;
  final SalaryDetails salaryDetails;
  final DateTime? issuedAt;

  const Payslip({
    this.employeeStatusNote,
    required this.fullNameAr,
    required this.fullNameEn,
    required this.departmentName,
    required this.jobTitle,
    required this.employmentMode,
    required this.month,
    required this.year,
    required this.actualWorkingDays,
    required this.salaryDetails,
    required this.issuedAt,
  });

  bool get isEmployeeNotActive =>
      employeeStatusNote != null && employeeStatusNote!.isNotEmpty;

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      employeeStatusNote: json['employeeStatusNote']?.toString(),
      fullNameAr: json['fullNameAr']?.toString() ?? '',
      fullNameEn: json['fullNameEn']?.toString() ?? '',
      departmentName: json['departmentName']?.toString(),
      jobTitle: json['jobTitle']?.toString(),
      employmentMode: json['employmentMode']?.toString(),
      month: _asInt(json['month']),
      year: _asInt(json['year']),
      actualWorkingDays: _asInt(json['actualWorkingDays']),
      salaryDetails: SalaryDetails.fromJson(
        (json['salaryDetails'] as Map<String, dynamic>? ?? const {}),
      ),
      issuedAt: _asDateTime(json['issuedAt']),
    );
  }
}

class SalaryDetails {
  final double grossSalary;
  final double totalEarnings;
  final double netSalary;
  final Allowances allowances;
  final Deductions deductions;
  final Insurance insurance;
  final double? insuranceSalary;
  final double bonusAmount;
  final double settlementAmount;
  final double settlementAdditions;
  final double settlementDeductions;
  final List<String> settlementDetails;
  final double taxAmount;
  final double? shiftRate;
  final int paidShiftDays;
  final int totalWorkingDays;
  final double hoursWorked;
  final double overtimeHours;
  final double overtimePay;
  final List<String> absenceDates;
  final List<String> lateDates;
  final List<String> incompleteDates;
  final List<String> overtimeDates;
  final List<PayslipOvertimeDetail> overtimeDetails;
  final int shiftMonthlyRequiredWorkingDays;
  final double shiftMonthlyRequiredHours;
  final double shiftMonthlyActualHours;
  final double shiftMonthlyMissingHours;
  final int shiftMonthlyDeductionDays;
  final int shiftMonthlyAbsentDays;
  final int shiftMonthlyHourDeficitDays;

  const SalaryDetails({
    required this.grossSalary,
    required this.totalEarnings,
    required this.netSalary,
    required this.allowances,
    required this.deductions,
    required this.insurance,
    required this.insuranceSalary,
    required this.bonusAmount,
    required this.settlementAmount,
    required this.settlementAdditions,
    required this.settlementDeductions,
    required this.settlementDetails,
    required this.taxAmount,
    required this.shiftRate,
    required this.paidShiftDays,
    required this.totalWorkingDays,
    required this.hoursWorked,
    required this.overtimeHours,
    required this.overtimePay,
    required this.absenceDates,
    required this.lateDates,
    required this.incompleteDates,
    required this.overtimeDates,
    required this.overtimeDetails,
    required this.shiftMonthlyRequiredWorkingDays,
    required this.shiftMonthlyRequiredHours,
    required this.shiftMonthlyActualHours,
    required this.shiftMonthlyMissingHours,
    required this.shiftMonthlyDeductionDays,
    required this.shiftMonthlyAbsentDays,
    required this.shiftMonthlyHourDeficitDays,
  });

  factory SalaryDetails.fromJson(Map<String, dynamic> json) {
    return SalaryDetails(
      grossSalary: _asDouble(json['grossSalary']),
      totalEarnings: _asDouble(json['totalEarnings']),
      netSalary: _asDouble(json['netSalary']),
      allowances: Allowances.fromJson(
        (json['allowances'] as Map<String, dynamic>? ?? const {}),
      ),
      deductions: Deductions.fromJson(
        (json['deductions'] as Map<String, dynamic>? ?? const {}),
      ),
      insurance: Insurance.fromJson(
        (json['insurance'] as Map<String, dynamic>? ?? const {}),
      ),
      insuranceSalary: _asNullableDouble(json['insuranceSalary']),
      bonusAmount: _asDouble(json['bonusAmount']),
      settlementAmount: _asDouble(json['settlementAmount']),
      settlementAdditions: _asDouble(json['settlementAdditions']),
      settlementDeductions: _asDouble(json['settlementDeductions']),
      settlementDetails: _asStringList(json['settlementDetails']),
      taxAmount: _asDouble(json['taxAmount']),
      shiftRate: _asNullableDouble(json['shiftRate']),
      paidShiftDays: _asInt(json['paidShiftDays']),
      totalWorkingDays: _asInt(json['totalWorkingDays']),
      hoursWorked: _asDouble(json['hoursWorked']),
      overtimeHours: _asDouble(json['overtimeHours']),
      overtimePay: _asDouble(json['overtimePay']),
      absenceDates: _asStringList(json['absenceDates']),
      lateDates: _asStringList(json['lateDates']),
      incompleteDates: _asStringList(json['incompleteDates']),
      overtimeDates: _asOvertimeDates(json['overtimeDates']),
      overtimeDetails: _asOvertimeDetails(json['overtimeDates']),
      shiftMonthlyRequiredWorkingDays: _asInt(
        json['shiftMonthlyRequiredWorkingDays'],
      ),
      shiftMonthlyRequiredHours: _asDouble(json['shiftMonthlyRequiredHours']),
      shiftMonthlyActualHours: _asDouble(json['shiftMonthlyActualHours']),
      shiftMonthlyMissingHours: _asDouble(json['shiftMonthlyMissingHours']),
      shiftMonthlyDeductionDays: _asInt(json['shiftMonthlyDeductionDays']),
      shiftMonthlyAbsentDays: _asInt(json['shiftMonthlyAbsentDays']),
      shiftMonthlyHourDeficitDays: _asInt(json['shiftMonthlyHourDeficitDays']),
    );
  }
}

class PayslipOvertimeDetail {
  final String date;
  final double hours;
  final double pay;

  const PayslipOvertimeDetail({
    required this.date,
    required this.hours,
    required this.pay,
  });

  factory PayslipOvertimeDetail.fromJson(Map<String, dynamic> json) {
    return PayslipOvertimeDetail(
      date: json['date']?.toString() ?? '',
      hours: _asDouble(json['hours']),
      pay: _asDouble(json['pay']),
    );
  }
}

class Allowances {
  final double housing;
  final double meal;
  final double transportation;
  final double insurance;
  final double additional;
  final double other;
  final double total;

  const Allowances({
    required this.housing,
    required this.meal,
    required this.transportation,
    required this.insurance,
    required this.additional,
    required this.other,
    required this.total,
  });

  factory Allowances.fromJson(Map<String, dynamic> json) {
    return Allowances(
      housing: _asDouble(json['housing']),
      meal: _asDouble(json['meal']),
      transportation: _asDouble(json['transportation']),
      insurance: _asDouble(json['insurance']),
      additional: _asDouble(json['additional']),
      other: _asDouble(json['other']),
      total: _asDouble(json['total']),
    );
  }
}

class Deductions {
  final double lateAmount;
  final double lateHours;
  final double absenceAmount;
  final double absenceDays;
  final double penaltiesAmount;
  final double advancesAmount;
  final double healthInsuranceAmount;
  final double settlementDeductions;
  final List<PayslipPenaltyDetail> penaltyDetails;
  final double total;

  const Deductions({
    required this.lateAmount,
    required this.lateHours,
    required this.absenceAmount,
    required this.absenceDays,
    required this.penaltiesAmount,
    required this.advancesAmount,
    required this.healthInsuranceAmount,
    required this.settlementDeductions,
    required this.penaltyDetails,
    required this.total,
  });

  factory Deductions.fromJson(Map<String, dynamic> json) {
    return Deductions(
      lateAmount: _asDouble(json['lateAmount']),
      lateHours: _asDouble(json['lateHours']),
      absenceAmount: _asDouble(json['absenceAmount']),
      absenceDays: _asDouble(json['absenceDays']),
      penaltiesAmount: _asDouble(json['penaltiesAmount']),
      advancesAmount: _asDouble(json['advancesAmount']),
      healthInsuranceAmount: _asDouble(json['healthInsuranceAmount']),
      settlementDeductions: _asDouble(json['settlementDeductions']),
      penaltyDetails: _asPenaltyDetails(json['penaltyDetails']),
      total: _asDouble(json['total']),
    );
  }
}

class PayslipPenaltyDetail {
  final int? id;
  final String? penaltyType;
  final double days;
  final double amount;
  final String? penaltyDate;
  final String? reason;
  final String? description;

  const PayslipPenaltyDetail({
    this.id,
    this.penaltyType,
    required this.days,
    required this.amount,
    this.penaltyDate,
    this.reason,
    this.description,
  });

  factory PayslipPenaltyDetail.fromJson(Map<String, dynamic> json) {
    return PayslipPenaltyDetail(
      id: _asNullableInt(json['id']),
      penaltyType: json['penaltyType']?.toString() ?? json['type']?.toString(),
      days: _asDouble(json['days']),
      amount: _asDouble(json['amount']),
      penaltyDate: json['penaltyDate']?.toString(),
      reason:
          json['reason']?.toString() ??
          json['description']?.toString() ??
          json['name']?.toString(),
      description: json['description']?.toString() ?? json['name']?.toString(),
    );
  }

  factory PayslipPenaltyDetail.fromText(String value) {
    return PayslipPenaltyDetail(
      days: 0,
      amount: 0,
      description: value,
      reason: value,
    );
  }

  bool get isDayPenalty => (penaltyType ?? '').toLowerCase() == 'days';
  bool get isAmountPenalty => (penaltyType ?? '').toLowerCase() == 'amount';
}

class Insurance {
  final double social;
  final double health;
  final double companyShare;
  final double insuranceSalary;
  final double totalDeducted;

  const Insurance({
    required this.social,
    required this.health,
    required this.companyShare,
    required this.insuranceSalary,
    required this.totalDeducted,
  });

  factory Insurance.fromJson(Map<String, dynamic> json) {
    return Insurance(
      social: _asDouble(json['social']),
      health: _asDouble(json['health']),
      companyShare: _asDouble(json['companyShare']),
      insuranceSalary: _asDouble(json['insuranceSalary']),
      totalDeducted: _asDouble(json['totalDeducted']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  return _asDouble(value);
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<String> _asStringList(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList();
}

List<String> _asOvertimeDates(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) {
        if (item is Map<String, dynamic>) {
          return item['date']?.toString() ?? '';
        }
        if (item is Map) {
          return item['date']?.toString() ?? '';
        }
        return item.toString();
      })
      .where((date) => date.trim().isNotEmpty)
      .toList();
}

List<PayslipOvertimeDetail> _asOvertimeDetails(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) {
        if (item is Map<String, dynamic>) {
          return PayslipOvertimeDetail.fromJson(item);
        }
        if (item is Map) {
          return PayslipOvertimeDetail.fromJson(
            Map<String, dynamic>.from(item),
          );
        }
        return PayslipOvertimeDetail(date: item.toString(), hours: 0, pay: 0);
      })
      .where((detail) => detail.date.trim().isNotEmpty)
      .toList();
}

List<PayslipPenaltyDetail> _asPenaltyDetails(dynamic value) {
  return (value as List<dynamic>? ?? const []).map((item) {
    if (item is Map<String, dynamic>) {
      return PayslipPenaltyDetail.fromJson(item);
    }
    if (item is Map) {
      return PayslipPenaltyDetail.fromJson(Map<String, dynamic>.from(item));
    }
    return PayslipPenaltyDetail.fromText(item.toString());
  }).toList();
}
