import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/daily_attendance_record.dart';
import 'models/payroll_period.dart';
import 'utils/attendance_formatters.dart';
import 'widgets/attendance_payroll_period_picker.dart';
import 'widgets/attendance_period_tab.dart';
import 'widgets/attendance_records_summary_card.dart';
import 'widgets/attendance_records_table.dart';

class AllAttendanceRecordsScreen extends StatefulWidget {
  final List<DailyAttendanceRecord> records;
  final DateTime initialDate;

  const AllAttendanceRecordsScreen({
    super.key,
    required this.records,
    required this.initialDate,
  });

  @override
  State<AllAttendanceRecordsScreen> createState() =>
      _AllAttendanceRecordsScreenState();
}

enum _AttendanceFilter { all, present, issues, absent, leave }

class _AllAttendanceRecordsScreenState
    extends State<AllAttendanceRecordsScreen> {
  late final List<PayrollPeriod> _payrollPeriods;
  late PayrollPeriod _selectedPayrollPeriod;
  _AttendanceFilter _selectedFilter = _AttendanceFilter.all;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _payrollPeriods = _buildPayrollPeriods(widget.initialDate, count: 12);
    _selectedPayrollPeriod = _resolveInitialPayrollPeriod(widget.initialDate);
  }

  PayrollPeriod _resolveInitialPayrollPeriod(DateTime focusDate) {
    final normalized = DateTime(focusDate.year, focusDate.month, focusDate.day);
    for (final period in _payrollPeriods) {
      if (!normalized.isBefore(period.start) &&
          !normalized.isAfter(period.end)) {
        return period;
      }
    }
    return _payrollPeriods.first;
  }

  DateTime _startOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  DateTime _endOfWeek(DateTime date) {
    final start = _startOfWeek(date);
    return start.add(const Duration(days: 6));
  }

  List<PayrollPeriod> _buildPayrollPeriods(DateTime anchor, {int count = 12}) {
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    final end = (a.day >= 26)
        ? DateTime(a.year, a.month + 1, 25)
        : DateTime(a.year, a.month, 25);

    final periods = <PayrollPeriod>[];
    for (int i = 0; i < count; i++) {
      final periodEnd = DateTime(end.year, end.month - i, 25);
      final periodStart = DateTime(periodEnd.year, periodEnd.month - 1, 26);
      periods.add(PayrollPeriod(start: periodStart, end: periodEnd));
    }
    return periods;
  }

  List<DailyAttendanceRecord> _filterRecords(DateTime start, DateTime end) {
    return widget.records.where((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  List<DailyAttendanceRecord> _applyStatusFilter(
    List<DailyAttendanceRecord> records,
  ) {
    switch (_selectedFilter) {
      case _AttendanceFilter.all:
        return records;
      case _AttendanceFilter.present:
        return records
            .where(
              (r) =>
                  r.status == AttendanceStatus.present ||
                  r.status == AttendanceStatus.late ||
                  r.status == AttendanceStatus.halfDay,
            )
            .toList();
      case _AttendanceFilter.issues:
        return records
            .where(
              (r) =>
                  r.status == AttendanceStatus.late ||
                  r.status == AttendanceStatus.halfDay ||
                  r.status == AttendanceStatus.absent,
            )
            .toList();
      case _AttendanceFilter.absent:
        return records
            .where((r) => r.status == AttendanceStatus.absent)
            .toList();
      case _AttendanceFilter.leave:
        return records
            .where(
              (r) =>
                  r.status == AttendanceStatus.leave ||
                  r.status == AttendanceStatus.weeklyOff,
            )
            .toList();
    }
  }

  int _countByFilter(
    List<DailyAttendanceRecord> records,
    _AttendanceFilter filter,
  ) {
    final previous = _selectedFilter;
    _selectedFilter = filter;
    final count = _applyStatusFilter(records).length;
    _selectedFilter = previous;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _startOfWeek(widget.initialDate);
    final weekEnd = _endOfWeek(widget.initialDate);

    final rawWeekRecords = _filterRecords(weekStart, weekEnd);
    final payroll = _selectedPayrollPeriod;
    final rawPayrollRecords = _filterRecords(payroll.start, payroll.end);

    final weekRecords = _applyStatusFilter(rawWeekRecords);
    final payrollRecords = _applyStatusFilter(rawPayrollRecords);
    final activeRawRecords = _selectedTabIndex == 0
        ? rawWeekRecords
        : rawPayrollRecords;

    final weekRangeText = '${formatDate(weekStart)} - ${formatDate(weekEnd)}';
    final payrollRangeText =
        '${formatDate(payroll.start)} - ${formatDate(payroll.end)}';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                expandedHeight: 230,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _AttendanceRecordsHero(
                    totalRecords: widget.records.length,
                    currentFilterLabel: _filterLabel(_selectedFilter),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Container(
                    color: AppColors.backgroundSecondary,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TabBar(
                      onTap: (index) {
                        setState(() => _selectedTabIndex = index);
                      },
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textTertiary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'الأسبوع'),
                        Tab(text: 'فترة المرتبات'),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _AttendanceFilterBar(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                    counters: {
                      _AttendanceFilter.all: activeRawRecords.length,
                      _AttendanceFilter.present: _countByFilter(
                        activeRawRecords,
                        _AttendanceFilter.present,
                      ),
                      _AttendanceFilter.issues: _countByFilter(
                        activeRawRecords,
                        _AttendanceFilter.issues,
                      ),
                      _AttendanceFilter.absent: _countByFilter(
                        activeRawRecords,
                        _AttendanceFilter.absent,
                      ),
                      _AttendanceFilter.leave: _countByFilter(
                        activeRawRecords,
                        _AttendanceFilter.leave,
                      ),
                    },
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              AttendancePeriodTab(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                header: _PeriodHeaderCard(
                  title: 'ملخص الأسبوع الحالي',
                  subtitle:
                      'راجع حركة الحضور خلال الأسبوع الحالي مع فلترة سريعة حسب الحالة.',
                  rangeText: weekRangeText,
                  recordCount: weekRecords.length,
                  accentColor: AppColors.primary,
                ),
                summary: AttendanceRecordsSummaryCard(
                  rangeText: weekRangeText,
                  records: weekRecords,
                ),
                table: AttendanceRecordsTable(records: weekRecords),
              ),
              AttendancePeriodTab(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                header: Column(
                  children: [
                    AttendancePayrollPeriodPicker(
                      periods: _payrollPeriods,
                      selected: _selectedPayrollPeriod,
                      onChanged: (value) =>
                          setState(() => _selectedPayrollPeriod = value),
                    ),
                    const SizedBox(height: 12),
                    _PeriodHeaderCard(
                      title: 'ملخص فترة المرتبات',
                      subtitle:
                          'اختر الفترة المناسبة ثم راجع الملخص والجدول بالحالة التي تهمك.',
                      rangeText: payrollRangeText,
                      recordCount: payrollRecords.length,
                      accentColor: AppColors.primaryDark,
                    ),
                  ],
                ),
                summary: AttendanceRecordsSummaryCard(
                  rangeText: payrollRangeText,
                  records: payrollRecords,
                ),
                table: AttendanceRecordsTable(records: payrollRecords),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _filterLabel(_AttendanceFilter filter) {
    switch (filter) {
      case _AttendanceFilter.all:
        return 'كل السجلات';
      case _AttendanceFilter.present:
        return 'الحضور';
      case _AttendanceFilter.issues:
        return 'الحالات الحرجة';
      case _AttendanceFilter.absent:
        return 'الغياب';
      case _AttendanceFilter.leave:
        return 'الإجازات';
    }
  }
}

class _AttendanceRecordsHero extends StatelessWidget {
  final int totalRecords;
  final String currentFilterLabel;

  const _AttendanceRecordsHero({
    required this.totalRecords,
    required this.currentFilterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1734), Color(0xFF12306A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.table_chart_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'سجل الحضور الكامل',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'فلترة أسرع ومراجعة أوضح لكل السجلات على مستوى الفترة المختارة.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(label: '$totalRecords سجل'),
              _HeroPill(label: currentFilterLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AttendanceFilterBar extends StatelessWidget {
  final _AttendanceFilter selectedFilter;
  final ValueChanged<_AttendanceFilter> onFilterChanged;
  final Map<_AttendanceFilter, int> counters;

  const _AttendanceFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.counters,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (filter: _AttendanceFilter.all, label: 'الكل'),
      (filter: _AttendanceFilter.present, label: 'حضور'),
      (filter: _AttendanceFilter.issues, label: 'حرجة'),
      (filter: _AttendanceFilter.absent, label: 'غياب'),
      (filter: _AttendanceFilter.leave, label: 'إجازات'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final isSelected = item.filter == selectedFilter;
          final count = counters[item.filter] ?? 0;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(
                '${item.label} $count',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              onSelected: (_) => onFilterChanged(item.filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String rangeText;
  final int recordCount;
  final Color accentColor;

  const _PeriodHeaderCard({
    required this.title,
    required this.subtitle,
    required this.rangeText,
    required this.recordCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$recordCount سجل',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              rangeText,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
