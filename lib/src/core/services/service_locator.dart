import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../../features/notifications/repository/notifications_repository.dart';
import '../../features/notifications/cubit/notifications_cubit.dart';
import '../../features/auth/api/auth_api.dart';
import '../../features/auth/services/auth_api_service.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/missions/api/assignment_api.dart';
import '../../features/missions/services/assignment_api_service.dart';
import '../../features/missions/repository/assignment_repository.dart';
import '../../features/missions/cubit/assignment_cubit.dart';
import '../../features/permissions/api/permission_api.dart';
import '../../features/permissions/services/permission_api_service.dart';
import '../../features/permissions/repository/permission_repository.dart';
import '../../features/admin/cubit/admin_requests_cubit.dart';
import '../../features/admin/cubit/super_admin_dashboard_cubit.dart';
import '../../features/admin/cubit/admin_dashboard_cubit.dart';
import '../../features/admin/api/super_admin_dashboard_api.dart';
import '../../features/admin/api/admin_dashboard_api.dart';
import '../../features/admin/services/super_admin_dashboard_service.dart';
import '../../features/admin/services/admin_dashboard_service.dart';
import '../../features/admin/repository/super_admin_dashboard_repository.dart';
import '../../features/admin/repository/admin_dashboard_repository.dart';
import '../../features/admin/services/admin_permissions_service.dart';
import '../../features/admin/repository/admin_permissions_repository.dart';
import '../../features/admin/cubit/admin_permissions_cubit.dart';
import '../../features/admin/services/admin_leaves_service.dart';
import '../../features/admin/repository/admin_leaves_repository.dart';
import '../../features/admin/cubit/admin_leaves_cubit.dart';
import '../../features/admin/services/admin_assignments_service.dart';
import '../../features/admin/repository/admin_assignments_repository.dart';
import '../../features/admin/cubit/admin_assignments_cubit.dart';
import '../../features/organization/cubit/organization_chart_cubit.dart';
import '../../features/home/api/home_api.dart';
import '../../features/home/services/home_api_service.dart';
import '../../features/home/repository/home_repository.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/requests/repository/requests_repository.dart';
import '../../features/requests/services/requests_refresh_service.dart';
import '../../features/hr/cubit/employees_cubit.dart';
import '../../features/hr/cubit/hr_home_cubit.dart';
import '../../features/hr/services/employees_api_service.dart';
import '../../features/hr/repository/employees_repository.dart';
import '../../features/leaves/api/leaves_api.dart';
import '../../features/leaves/services/leaves_api_service.dart';
import '../../features/leaves/repository/leaves_repository.dart';
import '../../features/leaves/cubit/leaves_cubit.dart';
import '../../features/attendance/api/attendance_api.dart';
import '../../features/attendance/services/attendance_api_service.dart';
import '../../features/attendance/repository/attendance_repository.dart';
import '../../features/attendance/cubit/attendance_cubit.dart';
import '../../features/overtime/api/overtime_api.dart';
import '../../features/overtime/services/overtime_api_service.dart';
import '../../features/overtime/repository/overtime_repository.dart';
import '../../features/overtime/cubit/overtime_cubit.dart';
import '../../features/holidays/api/public_holiday_api.dart';
import '../../features/holidays/services/public_holiday_service.dart';
import '../../features/holidays/repository/public_holiday_repository.dart';
import '../../features/holidays/cubit/holidays_cubit.dart';
import '../../features/hr/api/hr_home_api.dart';
import '../../features/hr/services/hr_home_service.dart';
import '../../features/hr/repository/hr_home_repository.dart';
import '../../features/profile/api/profile_api.dart';
import '../../features/profile/services/profile_service.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../../features/payslip/services/payslip_service.dart';
import '../../features/payslip/repository/payslip_repository.dart';
import '../../features/payslip/cubit/payslip_cubit.dart';
import '../../features/employee_history/services/employee_history_service.dart';
import '../../features/employee_history/repository/employee_history_repository.dart';
import '../../features/employee_history/cubit/employee_history_cubit.dart';
import '../../features/employee_of_month/data/datasources/employee_of_month_service.dart';
import '../../features/employee_of_month/data/repositories/employee_of_month_repository_impl.dart';
import '../../features/employee_of_month/domain/repositories/employee_of_month_repository.dart';
import '../../features/employee_of_month/presentation/cubit/employee_of_month_cubit.dart';
import '../../features/attendance/services/sa_attendance_service.dart';
import '../../features/attendance/repository/sa_attendance_repository.dart';
import '../../features/attendance/repository/sa_attendance_repository_impl.dart';
import '../../features/attendance/cubit/sa_attendance_cubit.dart';
import '../../features/attendance/cubit/punch_pairs_cubit.dart';

final getIt = GetIt.instance;

/// Initialize service locator and register all dependencies
Future<void> setupServiceLocator() async {
  // Core Services
  getIt.registerLazySingleton<DioClient>(() => DioClient());

  // API Services (Retrofit)
  getIt.registerFactory<AuthApi>(() => AuthApi(getIt<DioClient>().dio));
  getIt.registerFactory<AssignmentApi>(
    () => AssignmentApi(getIt<DioClient>().dio),
  );
  getIt.registerFactory<PermissionApi>(
    () => PermissionApi(getIt<DioClient>().dio),
  );
  getIt.registerFactory<LeavesApi>(() => LeavesApi(getIt<DioClient>().dio));
  getIt.registerFactory<AttendanceApi>(
    () => AttendanceApi(getIt<DioClient>().dio),
  );
  getIt.registerFactory<OvertimeApi>(() => OvertimeApi(getIt<DioClient>().dio));
  getIt.registerFactory<HomeApi>(() => HomeApi(getIt<DioClient>().dio));
  getIt.registerFactory<PublicHolidayApi>(
    () => PublicHolidayApi(getIt<DioClient>().dio),
  );
  getIt.registerFactory<HrHomeApi>(() => HrHomeApi(getIt<DioClient>().dio));
  getIt.registerFactory<SuperAdminDashboardApi>(
    () => SuperAdminDashboardApi(getIt<DioClient>().dio),
  );
  getIt.registerFactory<AdminDashboardApi>(
    () => AdminDashboardApi(getIt<DioClient>().dio),
  );
  getIt.registerFactory<ProfileApi>(() => ProfileApi(getIt<DioClient>().dio));

  // Feature Services (API Service Layer)
  getIt.registerFactory<AuthApiService>(() => AuthApiService(getIt<AuthApi>()));
  getIt.registerFactory<AssignmentApiService>(
    () => AssignmentApiService(getIt<AssignmentApi>()),
  );
  getIt.registerFactory<PermissionApiService>(
    () => PermissionApiService(getIt<PermissionApi>()),
  );
  getIt.registerFactory<LeavesApiService>(
    () => LeavesApiService(getIt<LeavesApi>()),
  );
  getIt.registerFactory<AttendanceApiService>(
    () => AttendanceApiService(getIt<AttendanceApi>(), getIt<DioClient>()),
  );
  getIt.registerFactory<OvertimeApiService>(
    () => OvertimeApiService(getIt<OvertimeApi>()),
  );
  getIt.registerFactory<HomeApiService>(() => HomeApiService(getIt<HomeApi>()));
  getIt.registerFactory<PublicHolidayService>(
    () => PublicHolidayService(getIt<PublicHolidayApi>()),
  );
  getIt.registerFactory<HrHomeService>(() => HrHomeService(getIt<HrHomeApi>()));
  getIt.registerFactory<EmployeesApiService>(
    () => EmployeesApiService(getIt<DioClient>()),
  );
  getIt.registerFactory<SuperAdminDashboardService>(
    () => SuperAdminDashboardService(getIt<SuperAdminDashboardApi>()),
  );
  getIt.registerFactory<AdminDashboardService>(
    () => AdminDashboardService(getIt<AdminDashboardApi>()),
  );
  getIt.registerFactory<AdminPermissionsService>(
    () => AdminPermissionsService(getIt<DioClient>()),
  );
  getIt.registerFactory<AdminLeavesService>(
    () => AdminLeavesService(getIt<DioClient>()),
  );
  getIt.registerFactory<AdminAssignmentsService>(
    () => AdminAssignmentsService(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(getIt<DioClient>()),
  );
  getIt.registerFactory<PayslipService>(
    () => PayslipService(getIt<DioClient>()),
  );
  getIt.registerFactory<EmployeeHistoryService>(
    () => EmployeeHistoryService(getIt<DioClient>()),
  );
  getIt.registerFactory<EmployeeOfMonthService>(
    () => EmployeeOfMonthService(getIt<DioClient>().dio),
  );

  // Repositories
  getIt.registerFactory<AuthRepository>(
    () => AuthRepository(authApiService: getIt<AuthApiService>()),
  );
  getIt.registerFactory<AssignmentRepository>(
    () => AssignmentRepository(
      assignmentApiService: getIt<AssignmentApiService>(),
    ),
  );
  getIt.registerFactory<PermissionRepository>(
    () => PermissionRepository(
      permissionApiService: getIt<PermissionApiService>(),
    ),
  );
  getIt.registerFactory<LeavesRepository>(
    () => LeavesRepository(leavesApiService: getIt<LeavesApiService>()),
  );
  getIt.registerFactory<AttendanceRepository>(
    () => AttendanceRepository(service: getIt<AttendanceApiService>()),
  );
  getIt.registerFactory<OvertimeRepository>(
    () => OvertimeRepository(overtimeApiService: getIt<OvertimeApiService>()),
  );
  getIt.registerFactory<HomeRepository>(
    () => HomeRepository(getIt<HomeApiService>(), getIt<DioClient>()),
  );
  getIt.registerFactory<RequestsRepository>(
    () => RequestsRepository(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<RequestsRefreshService>(
    () => RequestsRefreshService(),
  );
  getIt.registerLazySingleton<PublicHolidayRepository>(
    () => PublicHolidayRepository(getIt<PublicHolidayService>()),
  );
  getIt.registerFactory<HrHomeRepository>(
    () => HrHomeRepository(getIt<HrHomeService>()),
  );
  getIt.registerFactory<EmployeesRepository>(
    () => EmployeesRepository(getIt<EmployeesApiService>()),
  );
  getIt.registerFactory<SuperAdminDashboardRepository>(
    () => SuperAdminDashboardRepository(getIt<SuperAdminDashboardService>()),
  );
  getIt.registerFactory<AdminDashboardRepository>(
    () => AdminDashboardRepository(getIt<AdminDashboardService>()),
  );
  getIt.registerFactory<AdminPermissionsRepository>(
    () => AdminPermissionsRepository(getIt<AdminPermissionsService>()),
  );
  getIt.registerFactory<AdminLeavesRepository>(
    () => AdminLeavesRepository(getIt<AdminLeavesService>()),
  );
  getIt.registerFactory<AdminAssignmentsRepository>(
    () => AdminAssignmentsRepository(getIt<AdminAssignmentsService>()),
  );

  getIt.registerFactory<ProfileRepository>(
    () => ProfileRepository(getIt<DioClient>()),
  );
  getIt.registerFactory<PayslipRepository>(
    () => PayslipRepository(getIt<PayslipService>()),
  );
  getIt.registerFactory<EmployeeHistoryRepository>(
    () => EmployeeHistoryRepository(getIt<EmployeeHistoryService>()),
  );
  getIt.registerFactory<NotificationsRepository>(
    () => NotificationsRepository(getIt<DioClient>()),
  );

  // Cubits
  // AuthCubit as a singleton so authentication state is shared across the app
  // Register as singleton (not lazy) to ensure it loads state immediately
  final authCubit = AuthCubit(getIt<AuthRepository>());
  getIt.registerSingleton<AuthCubit>(authCubit);

  // Wait for auth state to load from storage
  // This ensures the state is ready before the app starts
  await Future.delayed(const Duration(milliseconds: 200));

  getIt.registerFactory<AssignmentCubit>(
    () => AssignmentCubit(getIt<AssignmentRepository>()),
  );
  getIt.registerFactory<AttendanceCubit>(
    () => AttendanceCubit(getIt<AttendanceRepository>()),
  );
  getIt.registerFactory<SAAttendanceService>(
    () => SAAttendanceService(getIt<DioClient>()),
  );
  getIt.registerFactory<SAAttendanceRepository>(
    () => SAAttendanceRepositoryImpl(getIt<SAAttendanceService>()),
  );
  getIt.registerFactory<SAAttendanceCubit>(
    () => SAAttendanceCubit(getIt<SAAttendanceRepository>(), dio: getIt<DioClient>().dio),
  );
  getIt.registerFactory<OvertimeCubit>(
    () => OvertimeCubit(getIt<OvertimeRepository>()),
  );
  getIt.registerFactory<AdminRequestsCubit>(() => AdminRequestsCubit());
  getIt.registerFactory<SuperAdminDashboardCubit>(
    () => SuperAdminDashboardCubit(getIt<SuperAdminDashboardRepository>()),
  );
  getIt.registerFactory<AdminDashboardCubit>(
    () => AdminDashboardCubit(getIt<AdminDashboardRepository>()),
  );
  getIt.registerFactory<AdminPermissionsCubit>(
    () => AdminPermissionsCubit(getIt<AdminPermissionsRepository>()),
  );
  getIt.registerFactory<AdminLeavesCubit>(
    () => AdminLeavesCubit(getIt<AdminLeavesRepository>()),
  );
  getIt.registerFactory<AdminAssignmentsCubit>(
    () => AdminAssignmentsCubit(getIt<AdminAssignmentsRepository>()),
  );
  getIt.registerFactory<OrganizationChartCubit>(() => OrganizationChartCubit());
  getIt.registerFactory<HomeCubit>(() => HomeCubit(getIt<HomeRepository>()));
  getIt.registerFactory<EmployeesCubit>(
    () => EmployeesCubit(getIt<EmployeesRepository>()),
  );
  getIt.registerFactory<HrHomeCubit>(
    () => HrHomeCubit(getIt<HrHomeRepository>(), getIt<EmployeesRepository>()),
  );
  // LeavesCubit as singleton to share leave types across screens (caching)
  getIt.registerLazySingleton<LeavesCubit>(
    () => LeavesCubit(getIt<LeavesRepository>()),
  );

  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(getIt<ProfileRepository>()),
  );
  getIt.registerFactory<PayslipCubit>(
    () => PayslipCubit(getIt<PayslipRepository>()),
  );
  getIt.registerFactory<EmployeeHistoryCubit>(
    () => EmployeeHistoryCubit(getIt<EmployeeHistoryRepository>()),
  );
  getIt.registerFactory<HolidaysCubit>(
    () => HolidaysCubit(getIt<PublicHolidayRepository>()),
  );

  // NotificationsCubit as singleton so badge count is shared across the app
  getIt.registerLazySingleton<NotificationsCubit>(
    () => NotificationsCubit(getIt<NotificationsRepository>()),
  );

  // Employee of the Month
  getIt.registerLazySingleton<EmployeeOfMonthRepository>(
    () => EmployeeOfMonthRepositoryImpl(getIt<EmployeeOfMonthService>()),
  );
  getIt.registerFactory<EmployeeOfMonthCubit>(
    () => EmployeeOfMonthCubit(getIt<EmployeeOfMonthRepository>()),
  );
  getIt.registerFactory<SuperAdminEmployeeOfMonthCubit>(
    () => SuperAdminEmployeeOfMonthCubit(getIt<EmployeeOfMonthRepository>()),
  );
  getIt.registerFactory<PunchPairsCubit>(
    () => PunchPairsCubit(
      getIt<SAAttendanceRepository>(),
      getIt<EmployeesRepository>(),
    ),
  );
}
