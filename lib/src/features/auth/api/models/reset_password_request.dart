import 'package:json_annotation/json_annotation.dart';

part 'reset_password_request.g.dart';

@JsonSerializable()
class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.nationalId,
    required this.phoneNumber,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  final String nationalId;
  final String phoneNumber;
  final String newPassword;
  final String confirmNewPassword;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}

