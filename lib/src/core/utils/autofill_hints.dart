import 'package:flutter/services.dart';

/// Autofill hints constants for TextField autofill support
class AppAutofillHints {
  // Auth
  static const List<String> username = [AutofillHints.username];
  static const List<String> password = [AutofillHints.password];
  static const List<String> newPassword = [AutofillHints.newPassword];
  static const List<String> oneTimeCode = [AutofillHints.oneTimeCode];

  // Personal Info
  static const List<String> name = [AutofillHints.name];
  static const List<String> givenName = [AutofillHints.givenName];
  static const List<String> familyName = [AutofillHints.familyName];
  static const List<String> fullName = [AutofillHints.name];
  static const List<String> birthday = [AutofillHints.birthday];
  static const List<String> gender = [AutofillHints.gender];

  // Contact
  static const List<String> email = [AutofillHints.email];
  static const List<String> telephone = [AutofillHints.telephoneNumber];
  static const List<String> phone = [AutofillHints.telephoneNumber];

  // Address - Using only available hints from Flutter
  static const List<String> address = [AutofillHints.fullStreetAddress];
  static const List<String> city = [AutofillHints.addressCity];
  static const List<String> state = [AutofillHints.addressState];
  static const List<String> postalCode = [AutofillHints.postalCode];
  static const List<String> country = [AutofillHints.countryName];

  // Organization
  static const List<String> organizationName = [AutofillHints.organizationName];
  static const List<String> jobTitle = [AutofillHints.jobTitle];

  // Other
  static const List<String> countryCode = [AutofillHints.countryCode];
  static const List<String> creditCardNumber = [AutofillHints.creditCardNumber];
  static const List<String> creditCardExpirationDate = [AutofillHints.creditCardExpirationDate];
  static const List<String> creditCardSecurityCode = [AutofillHints.creditCardSecurityCode];
}

