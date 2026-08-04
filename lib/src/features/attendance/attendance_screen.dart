import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/features/attendance/cubit/attendance_state.dart';

import '../../core/theme/app_colors.dart';
import 'attendance_screen_controller.dart';
import 'cubit/attendance_cubit.dart';
import 'widgets/attendance_date_selector.dart';
import 'widgets/attendance_header.dart';
import 'widgets/attendance_monthly_pdf_card.dart';
import 'widgets/check_in_out_section.dart';
import 'widgets/sections/attendance_analytics_section.dart';
import 'widgets/sections/attendance_daily_overview_section.dart';
import 'widgets/sections/attendance_period_snapshot_section.dart';
import 'widgets/sections/attendance_scope_switcher.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AttendanceScreenController();
    _controller.initialize(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, attendanceState) {
            final todayAttendance = attendanceState.todayAttendance;
            final displayedAttendance = attendanceState.displayedAttendance;
            final todayPermissions = attendanceState.todayPermissions;
            final visibleAttendance = _controller.isToday()
                ? todayAttendance
                : displayedAttendance;
            final monthlyData = attendanceState.monthlyData;

            return Scaffold(
              backgroundColor: AppColors.backgroundSecondary,
              body: RefreshIndicator(
                onRefresh: () => _controller.refresh(context, mounted: mounted),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AttendanceHeader(
                        attendance: visibleAttendance,
                        selectedDate: _controller.selectedDate,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AttendanceDateSelector(
                        selectedDate: _controller.selectedDate,
                        onDateChanged: (date) =>
                            _controller.onDateChanged(context, date),
                        onOpenHistory: monthlyData != null
                            ? () => _controller.openAttendanceHistory(context)
                            : null,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: AttendanceMonthlyPdfCard(),
                          ),
                          if (_controller.isToday())
                            CheckInOutSection(
                              todayAttendance: visibleAttendance,
                              onCheckIn: () => _controller.handleCheckIn(
                                context,
                                mounted: mounted,
                              ),
                              onCheckOut: () => _controller.handleCheckOut(
                                context,
                                mounted: mounted,
                              ),
                              isLoading: _controller.isProcessingAttendance,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AttendanceDailyOverviewSection(
                              attendance: visibleAttendance,
                              isToday: _controller.isToday(),
                              selectedDate: _controller.selectedDate,
                              todayPermissions: todayPermissions,
                            ),
                          ),
                          if (monthlyData != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: AttendanceScopeSwitcher(
                                selectedScope: _controller.selectedScope,
                                onScopeChanged: _controller.setScope,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: AttendancePeriodSnapshotSection(
                                data: monthlyData,
                                selectedDate: _controller.selectedDate,
                                scope: _controller.selectedScope,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: AttendanceRangeSection(
                                data: monthlyData,
                                onOpenHistory: () =>
                                    _controller.openAttendanceHistory(context),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: AttendanceMonthlyRecordsDeskSection(
                                data: monthlyData,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}