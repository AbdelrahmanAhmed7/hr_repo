import '../../shared/components/custom_toast.dart';
import 'package:flutter/widgets.dart';

enum IdentityType {
  nationalId,
  passport,
}

class AuthValidators {
  static bool validateLoginCredentials({
    required BuildContext context,
    required String nationalId,
    required String password,
  }) {
    final idError = validateNationalId(nationalId);
    if (idError != null) {
      CustomToast.showError(idError);
      return false;
    }

    final passError = validatePassword(password);
    if (passError != null) {
      CustomToast.showError(passError);
      return false;
    }

    return true;
  }

  static String? validateNationalId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'أدخل رقم البطاقة';
    }

    if (trimmed.length != 14 || int.tryParse(trimmed) == null) {
      return 'رقم البطاقة يجب أن يكون ١٤ رقم صحيح';
    }

    return null;
  }

  static String? validatePassport(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'أدخل رقم الجواز';
    }

    // Passport numbers typically range from 6-9 alphanumeric characters
    // Some countries use only numbers, others use letters and numbers
    if (trimmed.length < 6 || trimmed.length > 15) {
      return 'رقم الجواز يجب أن يكون بين ٦ و ١٥ حرف';
    }

    // Allow alphanumeric characters (letters and numbers)
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed)) {
      return 'رقم الجواز يجب أن يحتوي على أحرف وأرقام فقط';
    }

    return null;
  }

  static String? validateIdentity(String value, IdentityType type) {
    switch (type) {
      case IdentityType.nationalId:
        return validateNationalId(value);
      case IdentityType.passport:
        return validatePassport(value);
    }
  }

  static String? validatePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'أدخل رقم الموبايل';
    }

    // Egyptian phone numbers: 11 digits starting with 010, 011, 012, or 015
    final pattern = r'^(01[0125][0-9]{8})$';
    final regExp = RegExp(pattern);

    if (!regExp.hasMatch(trimmed)) {
      return 'صيغة الرقم غير صحيحة. يجب أن يكون 11 رقمًا ويبدأ بـ 010, 011, 012, أو 015';
    }

    return null;
  }

  static String? validatePassword(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'أدخل كلمة المرور';
    }
    return null;
  }

  static String? validateOtp(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'أدخل كود التحقق';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'أدخل كود التحقق الصحيح (6 أرقام)';
    }
    return null;
  }
}

