import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_exception.dart';
import '../attendance/models/daily_attendance_record.dart';
import '../attendance/widgets/attendance_records_table.dart';
import 'cubit/employees_cubit.dart';
import 'models/employee.dart';
import 'widgets/employee_attendance_filters.dart';

class EmployeeAttendanceReportScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeAttendanceReportScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeAttendanceReportScreen> createState() =>
      _EmployeeAttendanceReportScreenState();
}

class _EmployeeAttendanceReportScreenState
    extends State<EmployeeAttendanceReportScreen> {
  List<DailyAttendanceRecord> _records = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final employeesCubit = context.read<EmployeesCubit>();
      final records = await employeesCubit.getEmployeeAttendanceRecords(
        widget.employee.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppException.from(e).message;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: RefreshIndicator(
        onRefresh: _loadAttendanceRecords,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تقرير الحضور',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 24,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.employee.fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  EmployeeAttendanceFilters(
                    startDate: _startDate,
                    endDate: _endDate,
                    onFilterChanged: (startDate, endDate) {
                      setState(() {
                        _startDate = startDate;
                        _endDate = endDate;
                      });
                      _loadAttendanceRecords();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Attendance Summary
                  _buildAttendanceSummary(),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _error != null
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _records.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 48,
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'لا توجد سجلات حضور',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'لا توجد سجلات حضور للفترة المحددة',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : AttendanceRecordsTable(records: _records),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    final totalDays = _records.length;
    final presentDays =
        _records.where((r) => r.status == AttendanceStatus.present).length;
    final absentDays =
        _records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateDays =
        _records.where((r) => r.status == AttendanceStatus.late).length;
    final leaveDays =
        _records.where((r) => r.status == AttendanceStatus.leave).length;
    final weeklyOffDays =
        _records.where((r) => r.status == AttendanceStatus.weeklyOff).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.bar_chart_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'ملخص الحضور',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('إجمالي الأيام', totalDays.toString()),
          const SizedBox(height: 12),
          _buildSummaryRow('أيام الحضور', presentDays.toString(),
              color: _getStatusColor(AttendanceStatus.present)),
          const SizedBox(height: 12),
          _buildSummaryRow('أيام الغياب', absentDays.toString(),
              color: _getStatusColor(AttendanceStatus.absent)),
          const SizedBox(height: 12),
          _buildSummaryRow('أيام التأخير', lateDays.toString(),
              color: _getStatusColor(AttendanceStatus.late)),
          const SizedBox(height: 12),
          _buildSummaryRow('أيام الإجازة', leaveDays.toString(),
              color: _getStatusColor(AttendanceStatus.leave)),
          if (weeklyOffDays > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow('إجازات أسبوعية', weeklyOffDays.toString(),
                color: _getStatusColor(AttendanceStatus.weeklyOff)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color ?? AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF0F7D3E); // success green
      case AttendanceStatus.absent:
        return const Color(0xFFC41E3A); // error red
      case AttendanceStatus.leave:
        return const Color(0xFF4A90E2); // primary blue
      case AttendanceStatus.late:
        return const Color(0xFFD97706); // warning orange
      case AttendanceStatus.halfDay:
        return const Color(0xFF8C8C8C); // tertiary gray
      case AttendanceStatus.weeklyOff:
        return const Color(0xFF8C8C8C); // tertiary gray
    }
  }
}
