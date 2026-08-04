import 'package:equatable/equatable.dart';
import '../models/account_status.dart';

enum UserRole {
  user,
  admin,
  superAdmin,
  hr,
}

/// Auth State
class AuthState extends Equatable {
  final bool isAuthenticated;
  final String? userId;
  final String? token;
  final UserRole? role;
  final AccountStatus? accountStatus;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.token,
    this.role,
    this.accountStatus,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? token,
    UserRole? role,
    AccountStatus? accountStatus,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isHR => role == UserRole.hr;
  bool get isAccountApproved => accountStatus == AccountStatus.approved;

  @override
  List<Object?> get props => [isAuthenticated, userId, token, role, accountStatus];
}

