// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_password_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ResetPasswordRequest(
  nationalId: json['nationalId'] as String,
  phoneNumber: json['phoneNumber'] as String,
  newPassword: json['newPassword'] as String,
  confirmNewPassword: json['confirmNewPassword'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'nationalId': instance.nationalId,
  'phoneNumber': instance.phoneNumber,
  'newPassword': instance.newPassword,
  'confirmNewPassword': instance.confirmNewPassword,
};
