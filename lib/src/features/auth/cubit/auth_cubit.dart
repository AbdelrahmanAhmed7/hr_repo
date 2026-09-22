import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../leaves/cubit/leaves_cubit.dart';
import '../../notifications/cubit/notifications_cubit.dart';
import '../repository/auth_repository.dart';
import 'auth_state.dart';

/// Auth Cubit - UI state management for authentication
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthState()) {
    _loadAuthState();
  }

  /// Load saved auth state from storage
  Future<void> _loadAuthState() async {
    try {
      final authState = await _authRepository.loadAuthState();
      if (!isClosed) {
        emit(authState);
      }
    } catch (e) {
      if (!isClosed) {
        emit(const AuthState());
      }
    }
  }

  /// Login with phone number and password
  Future<void> login({
    required String nationalId,
    required String password,
  }) async {
    try {
      final phone = nationalId.trim();
      if (kDebugMode) {
        print('AuthCubit.login: Starting login for phone: $phone');
      }
      if (kDebugMode) {
        print(
          'AuthCubit.login: This instance - isClosed=$isClosed, hashCode=$hashCode',
        );
      }

      final authState = await _authRepository.login(
        phoneNumber: phone,
        password: password,
      );

      if (kDebugMode) {
        print(
          'AuthCubit.login: Repository returned - isAuth=${authState.isAuthenticated}, role=${authState.role}',
        );
      }

      if (!isClosed) {
        emit(authState);
        _clearPreviousUserData();
        if (kDebugMode) {
          print(
            'AuthCubit.login: State emitted - isAuth=${state.isAuthenticated}, role=${state.role}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthCubit.login: Exception - $e');
      }
      rethrow;
    }
  }

  /// Logout - clear auth state
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _clearPreviousUserData();
      if (!isClosed) {
        emit(const AuthState());
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear user-scoped in-memory state (cubit states + repository caches)
  /// so the next user never sees the previous user's data.
  /// Guarded for contexts where the service locator isn't initialized (tests).
  void _clearPreviousUserData() {
    try {
      final getIt = GetIt.I;
      if (getIt.isRegistered<LeavesCubit>()) {
        getIt<LeavesCubit>().reset();
      }
      if (getIt.isRegistered<NotificationsCubit>()) {
        getIt<NotificationsCubit>().reset();
      }
    } catch (_) {
      // Best effort only — never break login/logout because of cache clearing.
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Check if user is admin
  bool get isAdmin => state.isAdmin;
}
