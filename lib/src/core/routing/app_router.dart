import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconsult_internal/src/features/holidays/holidays_screen.dart';
import 'package:mediconsult_internal/src/features/notifications/notifications_screen.dart';
import 'package:mediconsult_internal/src/features/device_fingerprint/device_fingerprint_diagnostic_screen.dart';
import '../../core/services/service_locator.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/hr/hr_home_screen.dart';
import '../../features/admin/admin_home_screen.dart';
import '../../features/admin/super_admin_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/missions/missions_screen.dart';
import '../../features/missions/create_mission_screen.dart';
import '../../features/hr/hr_assignments_screen.dart';
import '../../features/hr/hr_departments_screen.dart';
import '../../features/hr/hr_employees_screen.dart';
import '../../features/organization/organization_chart_screen.dart';
import '../../features/admin/admin_requests_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/full_profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/about_screen.dart';
import '../../features/profile/help_support_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../../features/payslip/cubit/payslip_cubit.dart';
import '../../features/payslip/payslip_screen.dart';
import '../../features/employee_history/cubit/employee_history_cubit.dart';
import '../../features/employee_history/employee_history_screen.dart';
import '../../features/employee_of_month/presentation/cubit/employee_of_month_cubit.dart';
import '../../features/employee_of_month/presentation/screens/employee_of_month_screen.dart';
import '../../features/leaves/leaves_screen.dart';
import '../../features/requests/all_requests_screen.dart';
import '../../features/requests/requests_screen.dart';
import '../../features/attendance/cubit/attendance_cubit.dart';
import '../../features/overtime/cubit/overtime_cubit.dart';
import '../../features/overtime/overtime_screen.dart';
import '../../features/missions/cubit/assignment_cubit.dart';
import '../../features/organization/cubit/organization_chart_cubit.dart';
import '../../features/admin/cubit/admin_requests_cubit.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/hr/cubit/employees_cubit.dart';
import '../../features/notifications/cubit/notifications_cubit.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: _handleRedirect,
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          // Use BlocProvider.value for singleton AuthCubit
          return BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: const LoginScreen(),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otp-verification',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final otp = state.uri.queryParameters['otp'] ?? '';
          return ResetPasswordScreen(phone: phone, otp: otp);
        },
      ),

      // Main Screen (with nested routes)
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<AuthCubit>()),
            BlocProvider(create: (_) => getIt<HomeCubit>()),
            BlocProvider(create: (_) => getIt<AttendanceCubit>()),
            BlocProvider(create: (_) => getIt<AdminRequestsCubit>()),
            BlocProvider.value(value: getIt<NotificationsCubit>()),
          ],
          child: const MainScreen(),
        ),
      ),

      // Home Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<HomeCubit>()),
            BlocProvider(create: (_) => getIt<AttendanceCubit>()),
            BlocProvider.value(value: getIt<AuthCubit>()),
          ],
          child: const HomeScreen(),
        ),
      ),

      // HR Routes
      GoRoute(
        path: '/hr-home',
        name: 'hr-home',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<AttendanceCubit>()),
            BlocProvider.value(value: getIt<AuthCubit>()),
          ],
          child: const HRHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/hr/assignments',
        name: 'hr-assignments',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AssignmentCubit>(),
          child: const HRAssignmentsScreen(),
        ),
      ),
      GoRoute(
        path: '/hr/employees',
        name: 'hr-employees',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<EmployeesCubit>(),
          child: const HREmployeesScreen(),
        ),
      ),
      GoRoute(
        path: '/hr/departments',
        name: 'hr-departments',
        builder: (context, state) => const HRDepartmentsScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin-home',
        name: 'admin-home',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<AttendanceCubit>()),
            BlocProvider(create: (_) => getIt<AdminRequestsCubit>()),
            BlocProvider.value(value: getIt<AuthCubit>()),
          ],
          child: const AdminHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/requests',
        name: 'admin-requests',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AdminRequestsCubit>(),
          child: const AdminRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/super-admin',
        name: 'super-admin',
        builder: (context, state) => BlocProvider.value(
          value: getIt<AuthCubit>(),
          child: const SuperAdminScreen(),
        ),
      ),

      // Attendance Route
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AttendanceCubit>(),
          child: const AttendanceScreen(),
        ),
      ),

      // Missions Routes
      GoRoute(
        path: '/missions',
        name: 'missions',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AssignmentCubit>(),
          child: const MissionsScreen(),
        ),
      ),
      GoRoute(
        path: '/missions/create',
        name: 'create-mission',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AssignmentCubit>(),
          child: const CreateMissionScreen(),
        ),
      ),

      // Organization Route
      GoRoute(
        path: '/organization',
        name: 'organization',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<OrganizationChartCubit>()),
            BlocProvider(create: (_) => getIt<EmployeesCubit>()),
            BlocProvider.value(value: getIt<AuthCubit>()),
          ],
          child: const OrganizationChartScreen(),
        ),
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => BlocProvider.value(
          value: getIt<AuthCubit>(),
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/full',
        name: 'full-profile',
        builder: (context, state) => const FullProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ProfileCubit>()..fetchProfile(),
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/payslip',
        name: 'payslip',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<PayslipCubit>(),
          child: const PayslipScreen(),
        ),
      ),
      GoRoute(
        path: '/employee-history',
        name: 'employee-history',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<EmployeeHistoryCubit>(),
          child: const EmployeeHistoryScreen(),
        ),
      ),

      // Leaves Route
      GoRoute(
        path: '/leaves',
        name: 'leaves',
        builder: (context, state) => const LeavesScreen(),
      ),

      // Requests Route
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: RequestsScreen(initialTab: tab),
          );
        },
      ),
      GoRoute(
        path: '/all-requests',
        name: 'all-requests',
        builder: (context, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: AllRequestsScreen(initialTab: tab),
          );
        },
      ),
      GoRoute(
        path: '/overtime',
        name: 'overtime',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<OvertimeCubit>(),
          child: const OvertimeScreen(),
        ),
      ),

      // Holidays Route
      GoRoute(
        path: '/holidays',
        name: 'holidays',
        builder: (context, state) => BlocProvider.value(
          value: getIt<AuthCubit>(),
          child: const HolidaysScreen(),
        ),
      ),

      // Notifications Route
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<NotificationsCubit>()),
            BlocProvider.value(value: getIt<AuthCubit>()),
          ],
          child: const NotificationsScreen(),
        ),
      ),

      // Device Fingerprint Diagnostic Route
      GoRoute(
        path: '/device-fingerprint-diagnostic',
        name: 'device-fingerprint-diagnostic',
        builder: (context, state) => const DeviceFingerprintDiagnosticScreen(),
      ),

      // Change Password Route
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Profile Settings Routes
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpSupportScreen(),
      ),

      // Employee of the Month
      GoRoute(
        path: '/employee-of-month',
        name: 'employee-of-month',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<EmployeeOfMonthCubit>()..loadData(),
          child: const EmployeeOfMonthScreen(),
        ),
      ),
    ],
  );

  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isOnLoginPage = state.uri.path == '/login';
    final isOnSplashPage = state.uri.path == '/';
    final isOnForgotPassword = state.uri.path == '/forgot-password';
    final isOnResetPassword = state.uri.path == '/reset-password';

    final isOnOtpVerification = state.uri.path == '/otp-verification';

    // Allow splash, forgot password, reset password, and OTP pages
    if (isOnSplashPage ||
        isOnForgotPassword ||
        isOnResetPassword ||
        isOnOtpVerification) {
      return null;
    }

    // Check authentication from AuthCubit (should be loaded by now)
    bool isAuthenticated = false;
    try {
      final authCubit = getIt<AuthCubit>();
      isAuthenticated = authCubit.state.isAuthenticated;
    } catch (e) {
      isAuthenticated = false;
    }

    // For login page, check if already authenticated
    if (isOnLoginPage) {
      if (isAuthenticated) {
        return '/main'; // Redirect to main if already logged in
      }
      return null;
    }

    // For other pages, check authentication
    if (!isAuthenticated) {
      return '/login';
    }

    return null;
  }
}
