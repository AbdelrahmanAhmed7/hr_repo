import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/searchable_dropdown_field.dart';
import '../../shared/widgets/server_unavailable_dialog.dart';
import '../attendance/cubit/sa_attendance_cubit.dart';
import '../attendance/cubit/sa_attendance_state.dart';
import '../attendance/widgets/sa_attendance_date_navigator.dart';
import '../attendance/widgets/sa_attendance_stats_strip.dart';
import '../attendance/widgets/sa_attendance_filter_bar.dart';
import '../attendance/widgets/sa_attendance_search_bar.dart';
import '../attendance/widgets/sa_attendance_employee_row.dart';
import '../attendance/presentation/cubit/punch_cubit.dart';
import '../attendance/presentation/cubit/punch_state.dart';
import '../attendance/presentation/widgets/punch_filter_bar.dart';
import '../attendance/presentation/widgets/punch_summary_employee_card.dart';

class SuperAdminAttendanceScreen extends StatelessWidget {
  const SuperAdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SAAttendanceCubit>()..loadAttendance(),
      child: const _SAAttendanceContent(),
    );
  }
}

class _SAAttendanceContent extends StatefulWidget {
  const _SAAttendanceContent();

  @override
  State<_SAAttendanceContent> createState() => _SAAttendanceContentState();
}

class _SAAttendanceContentState extends State<_SAAttendanceContent> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<SAAttendanceCubit>();
    cubit.loadDepartments();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('سجل الحضور والانصراف'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'سجل الحضور'),
              Tab(text: 'الدخول والخروج'),
            ],
          ),
          actions: [
            BlocBuilder<SAAttendanceCubit, SAAttendanceState>(
              builder: (context, state) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isExportingPdf)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () =>
                            context.read<SAAttendanceCubit>().exportPdf(),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        tooltip: 'تصدير PDF',
                      ),
                    _buildFilterButton(context, state),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocListener<SAAttendanceCubit, SAAttendanceState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              AppException.isServerUnavailableMessage(current.errorMessage),
          listener: (context, state) {
            showServerUnavailableDialog(
              context,
              onRetry: () => context.read<SAAttendanceCubit>().loadAttendance(),
            );
          },
          child: TabBarView(
            children: [
              // Tab 1: Attendance
              BlocBuilder<SAAttendanceCubit, SAAttendanceState>(
                builder: (context, state) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SAAttendanceDateNavigator(
                          selectedDate: state.selectedDate,
                          onPrevious: () => context
                              .read<SAAttendanceCubit>()
                              .goToPreviousDay(),
                          onNext: () =>
                              context.read<SAAttendanceCubit>().goToNextDay(),
                          onToday: () =>
                              context.read<SAAttendanceCubit>().goToToday(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _DepartmentFilterBar(
                          departments: state.departments,
                          selectedDepartmentId: state.selectedDepartmentId,
                          onDepartmentChanged: (id) => context
                              .read<SAAttendanceCubit>()
                              .applyDepartmentFilter(id),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SAAttendanceStatsStrip(
                          totalCount: state.totalEmployees,
                          presentCount: state.employeesWithAttendance,
                          absentCount: state.absentCount,
                          percentage: state.attendancePercentage,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SAAttendanceFilterBar(
                          activeFilter: state.activeFilter,
                          onFilterChanged: (filter) => context
                              .read<SAAttendanceCubit>()
                              .applyFilter(filter),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SAAttendanceSearchBar(
                          query: state.searchQuery,
                          onChanged: (query) => context
                              .read<SAAttendanceCubit>()
                              .applySearch(query),
                        ),
                      ),
                      _buildBodySliver(context, state),
                    ],
                  );
                },
              ),
              // Tab 2: Punch Summary
              BlocProvider(
                create: (ctx) => getIt<PunchCubit>(),
                child: const _PunchTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, SAAttendanceState state) {
    return GestureDetector(
      onTap: () => _showFiltersSheet(context, state),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.tune_rounded, size: 24),
          ),
          if (state.hasActiveFilters)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context, SAAttendanceState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SAAttendanceCubit>(),
        child: _FiltersSheet(state: state),
      ),
    );
  }

  Widget _buildBodySliver(BuildContext context, SAAttendanceState state) {
    switch (state.status) {
      case SAAttendanceStatus.initial:
      case SAAttendanceStatus.loading:
        return _buildShimmer();
      case SAAttendanceStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateWidget(
            error: state.errorMessage ?? 'حدث خطأ غير متوقع',
            buttonLabel: 'إعادة المحاولة',
            onRetry: () => context.read<SAAttendanceCubit>().loadAttendance(),
          ),
        );
      case SAAttendanceStatus.success:
        if (state.filteredRecords.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.event_busy_rounded,
              title: 'لا يوجد سجلات',
              message: 'لا توجد سجلات حضور لهذا التاريخ',
              iconColor: AppColors.textTertiary,
            ),
          );
        }
        return _buildList(context, state);
    }
  }

  Widget _buildList(BuildContext context, SAAttendanceState state) {
    return SliverPadding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxxl,
      ),
      sliver: SliverList.builder(
        itemCount: state.filteredRecords.length,
        itemBuilder: (context, index) {
          final record = state.filteredRecords[index];
          return SAAttendanceEmployeeRow(
            record: record,
            isExpanded: state.expandedEmployeeId == record.employeeName,
            onTap: () => context.read<SAAttendanceCubit>().toggleExpand(
              record.employeeName,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
              ),
              child: Row(
                children: [
                  const ShimmerPlaceholder(
                    width: 48,
                    height: 48,
                    borderRadius: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(
                          width: 120 + (index * 10).toDouble(),
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 6),
                        const ShimmerPlaceholder(
                          width: 80,
                          height: 10,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const ShimmerPlaceholder(
                    width: 56,
                    height: 22,
                    borderRadius: 11,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Department Filter Bar ────────────────────────────────────────────────────

class _DepartmentFilterBar extends StatelessWidget {
  final List<DepartmentOption> departments;
  final int? selectedDepartmentId;
  final ValueChanged<int?> onDepartmentChanged;

  const _DepartmentFilterBar({
    required this.departments,
    required this.selectedDepartmentId,
    required this.onDepartmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SearchableDropdownField<int>(
              value: selectedDepartmentId,
              labelText: 'القسم',
              hintText: 'كل الأقسام',
              searchHintText: 'ابحث عن قسم',
              isDense: true,
              items: [
                const SearchableDropdownItem<int?>(
                  value: null,
                  label: 'كل الأقسام',
                ),
                ...departments.map(
                  (dept) => SearchableDropdownItem<int?>(
                    value: dept.id,
                    label: dept.name,
                  ),
                ),
              ],
              onChanged: onDepartmentChanged,
            ),
          ),
          if (selectedDepartmentId != null) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => onDepartmentChanged(null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────

class _FiltersSheet extends StatefulWidget {
  final SAAttendanceState state;
  const _FiltersSheet({required this.state});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late int? _deviceType;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.state.startDate;
    _dateTo = widget.state.endDate;
    _deviceType = widget.state.deviceTypeFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'تصفية النتائج',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  context.read<SAAttendanceCubit>().clearAllFilters();
                  Navigator.pop(context);
                },
                child: const Text('مسح الكل'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'الفترة الزمنية',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'من',
                  value: _dateFrom,
                  onPicked: (v) => setState(() => _dateFrom = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: 'إلى',
                  value: _dateTo,
                  onPicked: (v) => setState(() => _dateTo = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'نوع الجهاز',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _DeviceTypeChip(
                label: 'الكل',
                isSelected: _deviceType == null,
                onTap: () => setState(() => _deviceType = null),
              ),
              const SizedBox(width: 8),
              _DeviceTypeChip(
                label: 'موبايل',
                icon: Icons.phone_android_rounded,
                isSelected: _deviceType == 2,
                onTap: () => setState(() => _deviceType = 2),
              ),
              const SizedBox(width: 8),
              _DeviceTypeChip(
                label: 'بصمة',
                icon: Icons.fingerprint_rounded,
                isSelected: _deviceType == 3,
                onTap: () => setState(() => _deviceType = 3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final cubit = context.read<SAAttendanceCubit>();
                if (_dateFrom != null && _dateTo != null) {
                  cubit.loadAttendanceWithRange(
                    startDate: _dateFrom!,
                    endDate: _dateTo!,
                  );
                } else {
                  cubit.loadAttendance();
                }
                cubit.applyDeviceTypeFilter(_deviceType);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تطبيق',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = value != null
        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
        : null;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText ?? label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onPicked(null),
                child: const Icon(
                  Icons.clear_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTypeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeviceTypeChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusRound),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PunchTabContent extends StatelessWidget {
  const _PunchTabContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (context, state) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent * 0.8) {
              context.read<PunchCubit>().loadMoreSummary();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: PunchFilterBar()),
              _buildPunchBodySliver(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPunchBodySliver(BuildContext context, PunchState state) {
    if (state.summaryStatus == PunchStatus.loading &&
        state.summaryItems.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.summaryStatus == PunchStatus.error &&
        state.summaryItems.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateWidget(
          error: state.errorMessage ?? 'حدث خطأ',
          buttonLabel: 'إعادة المحاولة',
          onRetry: () => context.read<PunchCubit>().loadSummary(refresh: true),
        ),
      );
    }
    if (state.summaryItems.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          icon: Icons.event_busy_rounded,
          title: 'لا يوجد بيانات',
          message: 'لم يتم العثور على سجلات في هذه الفترة',
        ),
      );
    }

    final items = state.filteredSummaryItems;
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      sliver: SliverList.builder(
        itemCount: items.length + (state.isLoadingMoreSummary ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return PunchSummaryEmployeeCard(item: items[index]);
        },
      ),
    );
  }
}
