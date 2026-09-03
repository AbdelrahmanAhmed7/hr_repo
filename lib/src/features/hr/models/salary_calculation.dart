class SalaryCalculation {
  final String? employeeStatusNote;
  final double grossSalary;
  final double totalEarnings;
  final double netSalary;

  final SalaryAllowances allowances;
  final SalaryDeductions deductions;
  final SalaryInsurance insurance;

  final double insuranceSalary;
  final double bonusAmount;
  final double settlementAmount;
  final double settlementAdditions;
  final double settlementDeductions;
  final List<SalarySettlementDetail> settlementDetails;
  final double taxAmount;

  final double shiftRate;
  final int paidShiftDays;
  final int totalWorkingDays;

  final List<String> absenceDates;
  final List<String> lateDates;
  final List<String> incompleteDates;

  final double hoursWorked;
  final double overtimeHours;
  final double overtimePay;
  final List<String> overtimeDates;
  final List<SalaryOvertimeDetail> overtimeDetails;

  final int shiftMonthlyRequiredWorkingDays;
  final double shiftMonthlyRequiredHours;
  final double shiftMonthlyActualHours;
  final double shiftMonthlyMissingHours;
  final int shiftMonthlyDeductionDays;
  final int shiftMonthlyAbsentDays;
  final int shiftMonthlyHourDeficitDays;

  const SalaryCalculation({
    this.employeeStatusNote,
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
    required this.absenceDates,
    required this.lateDates,
    required this.incompleteDates,
    required this.hoursWorked,
    required this.overtimeHours,
    required this.overtimePay,
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

  factory SalaryCalculation.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;

    List<String> strList(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    return SalaryCalculation(
      employeeStatusNote: json['employeeStatusNote'] as String?,
      grossSalary: d('grossSalary'),
      totalEarnings: d('totalEarnings'),
      netSalary: d('netSalary'),
      allowances: SalaryAllowances.fromJson(
        json['allowances'] as Map<String, dynamic>? ?? const {},
      ),
      deductions: SalaryDeductions.fromJson(
        json['deductions'] as Map<String, dynamic>? ?? const {},
      ),
      insurance: SalaryInsurance.fromJson(
        json['insurance'] as Map<String, dynamic>? ?? const {},
      ),
      insuranceSalary: d('insuranceSalary'),
      bonusAmount: d('bonusAmount'),
      settlementAmount: d('settlementAmount'),
      settlementAdditions: d('settlementAdditions'),
      settlementDeductions: d('settlementDeductions'),
      settlementDetails:
          (json['settlementDetails'] as List<dynamic>? ?? const [])
              .map(
                (e) =>
                    SalarySettlementDetail.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      taxAmount: d('taxAmount'),
      shiftRate: d('shiftRate'),
      paidShiftDays: i('paidShiftDays'),
      totalWorkingDays: i('totalWorkingDays'),
      absenceDates: strList('absenceDates'),
      lateDates: strList('lateDates'),
      incompleteDates: strList('incompleteDates'),
      hoursWorked: d('hoursWorked'),
      overtimeHours: d('overtimeHours'),
      overtimePay: d('overtimePay'),
      overtimeDates: _overtimeDates(json['overtimeDates']),
      overtimeDetails: _overtimeDetails(json['overtimeDates']),
      shiftMonthlyRequiredWorkingDays: i('shiftMonthlyRequiredWorkingDays'),
      shiftMonthlyRequiredHours: d('shiftMonthlyRequiredHours'),
      shiftMonthlyActualHours: d('shiftMonthlyActualHours'),
      shiftMonthlyMissingHours: d('shiftMonthlyMissingHours'),
      shiftMonthlyDeductionDays: i('shiftMonthlyDeductionDays'),
      shiftMonthlyAbsentDays: i('shiftMonthlyAbsentDays'),
      shiftMonthlyHourDeficitDays: i('shiftMonthlyHourDeficitDays'),
    );
  }
}

class SalaryOvertimeDetail {
  final String date;
  final double hours;
  final double pay;

  const SalaryOvertimeDetail({
    required this.date,
    required this.hours,
    required this.pay,
  });

  factory SalaryOvertimeDetail.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return SalaryOvertimeDetail(
      date: json['date']?.toString() ?? '',
      hours: d('hours'),
      pay: d('pay'),
    );
  }
}

class SalaryAllowances {
  final double housing;
  final double meal;
  final double transportation;
  final double insurance;
  final double additional;
  final double other;
  final double total;

  const SalaryAllowances({
    required this.housing,
    required this.meal,
    required this.transportation,
    required this.insurance,
    required this.additional,
    required this.other,
    required this.total,
  });

  factory SalaryAllowances.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return SalaryAllowances(
      housing: d('housing'),
      meal: d('meal'),
      transportation: d('transportation'),
      insurance: d('insurance'),
      additional: d('additional'),
      other: d('other'),
      total: d('total'),
    );
  }
}

class SalaryDeductions {
  final double lateAmount;
  final double lateHours;
  final double absenceAmount;
  final double absenceDays;
  final double penaltiesAmount;
  final double advancesAmount;
  final double healthInsuranceAmount;
  final double settlementDeductions;
  final List<SalaryPenaltyDetail> penaltyDetails;
  final double total;

  const SalaryDeductions({
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

  factory SalaryDeductions.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return SalaryDeductions(
      lateAmount: d('lateAmount'),
      lateHours: d('lateHours'),
      absenceAmount: d('absenceAmount'),
      absenceDays: d('absenceDays'),
      penaltiesAmount: d('penaltiesAmount'),
      advancesAmount: d('advancesAmount'),
      healthInsuranceAmount: d('healthInsuranceAmount'),
      settlementDeductions: d('settlementDeductions'),
      penaltyDetails: (json['penaltyDetails'] as List<dynamic>? ?? const [])
          .map((e) => SalaryPenaltyDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: d('total'),
    );
  }
}

class SalaryPenaltyDetail {
  final int? id;
  final String? description;
  final String? type;
  final String? penaltyType;
  final double days;
  final double amount;
  final String? penaltyDate;
  final String? reason;

  const SalaryPenaltyDetail({
    this.id,
    this.description,
    this.type,
    this.penaltyType,
    required this.days,
    required this.amount,
    this.penaltyDate,
    this.reason,
  });

  factory SalaryPenaltyDetail.fromJson(Map<String, dynamic> json) {
    return SalaryPenaltyDetail(
      id: (json['id'] as num?)?.toInt(),
      description: (json['description'] ?? json['name']) as String?,
      type: json['type'] as String?,
      penaltyType: json['penaltyType']?.toString() ?? json['type']?.toString(),
      days: (json['days'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      penaltyDate: json['penaltyDate']?.toString(),
      reason:
          json['reason']?.toString() ??
          json['description']?.toString() ??
          json['name']?.toString(),
    );
  }

  bool get isDayPenalty => (penaltyType ?? '').toLowerCase() == 'days';
  bool get isAmountPenalty => (penaltyType ?? '').toLowerCase() == 'amount';
}

class SalarySettlementDetail {
  final String? description;
  final double amount;

  const SalarySettlementDetail({this.description, required this.amount});

  factory SalarySettlementDetail.fromJson(Map<String, dynamic> json) {
    return SalarySettlementDetail(
      description: (json['description'] ?? json['name']) as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalaryInsurance {
  final double social;
  final double health;
  final double companyShare;
  final double insuranceSalary;
  final double totalDeducted;

  const SalaryInsurance({
    required this.social,
    required this.health,
    required this.companyShare,
    required this.insuranceSalary,
    required this.totalDeducted,
  });

  factory SalaryInsurance.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return SalaryInsurance(
      social: d('social'),
      health: d('health'),
      companyShare: d('companyShare'),
      insuranceSalary: d('insuranceSalary'),
      totalDeducted: d('totalDeducted'),
    );
  }
}

List<String> _overtimeDates(dynamic value) {
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

List<SalaryOvertimeDetail> _overtimeDetails(dynamic value) {
  return (value as List<dynamic>? ?? const [])
      .map((item) {
        if (item is Map<String, dynamic>) {
          return SalaryOvertimeDetail.fromJson(item);
        }
        if (item is Map) {
          return SalaryOvertimeDetail.fromJson(Map<String, dynamic>.from(item));
        }
        return SalaryOvertimeDetail(date: item.toString(), hours: 0, pay: 0);
      })
      .where((detail) => detail.date.trim().isNotEmpty)
      .toList();
}
