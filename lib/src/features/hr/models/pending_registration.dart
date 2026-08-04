import '../../auth/auth_validators.dart' show IdentityType;

class PendingRegistration {
  final String id;
  final String phone;
  final String fullName;
  final String email;
  final String nationalId;
  final IdentityType identityType;
  final DateTime? birthDate;
  final String? gender;
  final String? department;
  final String? companyPhone;
  final String? companyEmail;
  final DateTime registrationDate;

  // Fields added by HR:
  final String? position;
  final bool? hasSecurityClearance;

  PendingRegistration({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.email,
    required this.nationalId,
    required this.identityType,
    this.birthDate,
    this.gender,
    this.department,
    this.companyPhone,
    this.companyEmail,
    required this.registrationDate,
    this.position,
    this.hasSecurityClearance,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'fullName': fullName,
      'email': email,
      'nationalId': nationalId,
      'identityType': identityType.name,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'department': department,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'registrationDate': registrationDate.toIso8601String(),
      'position': position,
      'hasSecurityClearance': hasSecurityClearance,
    };
  }

  factory PendingRegistration.fromJson(Map<String, dynamic> json) {
    return PendingRegistration(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      nationalId: json['nationalId'] as String,
      identityType: IdentityType.values.firstWhere(
        (e) => e.name == json['identityType'],
        orElse: () => IdentityType.nationalId,
      ),
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      gender: json['gender'] as String?,
      department: json['department'] as String?,
      companyPhone: json['companyPhone'] as String?,
      companyEmail: json['companyEmail'] as String?,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      position: json['position'] as String?,
      hasSecurityClearance: json['hasSecurityClearance'] as bool?,
    );
  }

  PendingRegistration copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? email,
    String? nationalId,
    IdentityType? identityType,
    DateTime? birthDate,
    String? gender,
    String? department,
    String? companyPhone,
    String? companyEmail,
    DateTime? registrationDate,
    String? position,
    bool? hasSecurityClearance,
  }) {
    return PendingRegistration(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      identityType: identityType ?? this.identityType,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      department: department ?? this.department,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      registrationDate: registrationDate ?? this.registrationDate,
      position: position ?? this.position,
      hasSecurityClearance: hasSecurityClearance ?? this.hasSecurityClearance,
    );
  }
}
