import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/features/auth/cubit/auth_state.dart';
import '../auth/cubit/auth_cubit.dart';
import '../home/home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../admin/super_admin_screen.dart';
import '../hr/hr_home_screen.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/hr_attendance_management_screen.dart';
import '../leaves/leaves_screen.dart';
import '../permissions/permissions_screen.dart';
import '../profile/profile_screen.dart';
import '../../shared/components/custom_bottom_navigation.dart';
import '../../shared/widgets/lazy_indexed_stack.dart';
import '../notifications/cubit/notifications_cubit.dart';
import '../notifications/cubit/notifications_state.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  List<Widget> _buildScreens(bool isAdmin, bool isHR) {
    Widget homeScreen;
    Widget attendanceScreen;
    if (isAdmin) {
      homeScreen = const AdminHomeScreen();
      attendanceScreen = const AttendanceScreen();
    } else if (isHR) {
      homeScreen = const HRHomeScreen();
      attendanceScreen = const HrAttendanceManagementScreen();
    } else {
      homeScreen = const HomeScreen();
      attendanceScreen = const AttendanceScreen();
    }

    return [
      homeScreen,
      attendanceScreen,
      const LeavesScreen(),
      const PermissionsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isSuperAdmin = authState.isSuperAdmin;
        final isAdmin = authState.isAdmin;
        final isHR = authState.isHR;

        // If super admin, show SuperAdminScreen
        if (isSuperAdmin) {
          return const SuperAdminScreen();
        }

        final screens = _buildScreens(isAdmin, isHR);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // Check if there's a route above us in the navigator (detail pages)
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }

            // If we're not on Home tab (index 0), go back to Home
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
              return;
            }

            // We're on Home tab, show double-tap exit
            final now = DateTime.now();
            if (_lastBackPress == null ||
                now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
              _lastBackPress = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('اضغط مرة أخرى للخروج'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: LazyIndexedStack(index: _currentIndex, children: screens),
            bottomNavigationBar: SafeArea(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, notifState) {
                  return CustomBottomNavigationBar(
                    currentIndex: _currentIndex,
                    notificationCount: notifState.unreadCount,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
