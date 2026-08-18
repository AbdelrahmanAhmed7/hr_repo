
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../attendance/cubit/punch_pairs_cubit.dart';
import '../attendance/cubit/punch_pairs_state.dart';
import '../attendance/models/punch_pair.dart';
import '../attendance/repository/sa_attendance_repository.dart';
import '../hr/repository/employees_repository.dart';

class PunchPairsScreen extends StatelessWidget {
  const PunchPairsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PunchPairsCubit(
        getIt<SAAttendanceRepository>(),
        getIt<EmployeesRepository>(),
      )
        ..loadEmployeeOptions()
        ..load(),
      child: const _PunchPairsContent(),
    );
  }
}

class _PunchPairsContent extends StatefulWidget {
  const _PunchPairsContent();

  @override
  State<_PunchPairsContent> createState() => _PunchPairsContentState();
}

class _PunchPairsContentState extends State<_PunchPairsContent> {
  final _employeeSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _employeeSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final cubit = context.read<PunchPairsCubit>();
    final initial = isFrom
        ? cubit.state.fromDate ?? DateTime.now()
        : cubit.state.toDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    if (isFrom) {
      cubit.setFromDate(picked);
    } else {
      cubit.setToDate(picked);
    }
  }

  Future<void> _showEmployeePicker(BuildContext context) async {
    final cubit = context.read<PunchPairsCubit>();
    final options = cubit.state.employeeOptions;

    final result = await showModalBottomSheet<EmployeeOption?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeePickerSheet(
        options: options,
        selectedUserId: cubit.state.selectedUserId,
      ),
    );

    if (!context.mounted) return;
    if (result == null) {
      // deselect
      cubit.selectEmployee(null, null);
    } else {
      cubit.selectEmployee(result.userId, result.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: CustomScrollView(
          slivers: [
            _buildHeader(context),
            SliverToBoxAdapter(child: _buildFiltersSection(context)),
            _buildBody(context),
            SliverToBoxAdapter(child: _buildPagination(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سجل الدخول والخروج',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            BlocBuilder<PunchPairsCubit, PunchPairsState>(
                              builder: (context, state) => Text(
                                state.status == PunchPairsStatus.success
                                    ? 'إجمالي ${state.totalCount} سجل'
                                    : 'تقرير الحضور التفصيلي',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      BlocBuilder<PunchPairsCubit, PunchPairsState>(
                        builder: (context, state) => state.hasFilters
                            ? Tooltip(
                                message: 'مسح الفلاتر',
                                child: IconButton(
                                  onPressed: () =>
                                      context.read<PunchPairsCubit>().clearFilters(),
                                  icon: const Icon(
                                    Icons.filter_alt_off_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return BlocBuilder<PunchPairsCubit, PunchPairsState>(
      builder: (context, state) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'الفلاتر',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (state.hasFilters) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          context.read<PunchPairsCubit>().clearFilters(),
                      child: Text(
                        'مسح الكل',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Employee filter
              GestureDetector(
                onTap: () => _showEmployeePicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: state.selectedUserId != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: state.selectedUserId != null ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: state.selectedUserId != null
                        ? AppColors.primaryTint
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 20,
                        color: state.selectedUserId != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.selectedEmployeeName ?? 'اختر موظف (اختياري)',
                          style: TextStyle(
                            color: state.selectedUserId != null
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: state.selectedUserId != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (state.selectedUserId != null)
                        GestureDetector(
                          onTap: () =>
                              context.read<PunchPairsCubit>().selectEmployee(
                                    null,
                                    null,
                                  ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
                        )
                      else
                        Icon(Icons.arrow_drop_down_rounded,
                            color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: _DatePickerButton(
                      label: 'من',
                      value: state.fromDate != null
                          ? dateFormat.format(state.fromDate!)
                          : null,
                      icon: Icons.calendar_today_rounded,
                      onTap: () =>
                          _pickDate(context, isFrom: true),
                      onClear: state.fromDate != null
                          ? () => context
                              .read<PunchPairsCubit>()
                              .setFromDate(null)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DatePickerButton(
                      label: 'إلى',
                      value: state.toDate != null
                          ? dateFormat.format(state.toDate!)
                          : null,
                      icon: Icons.calendar_month_rounded,
                      onTap: () =>
                          _pickDate(context, isFrom: false),
                      onClear: state.toDate != null
                          ? () => context
                              .read<PunchPairsCubit>()
                              .setToDate(null)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<PunchPairsCubit, PunchPairsState>(
      builder: (context, state) {
        if (state.status == PunchPairsStatus.loading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: _LoadingWidget()),
          );
        }

        if (state.status == PunchPairsStatus.error) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorWidget(
              message: state.errorMessage ?? 'حدث خطأ',
              onRetry: () => context.read<PunchPairsCubit>().load(),
            ),
          );
        }

        if (state.items.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyWidget(),
          );
        }

        final grouped = <String, List<PunchPair>>{};
        for (final pair in state.items) {
          grouped.putIfAbsent(pair.userId, () => []).add(pair);
        }
        final groupList = grouped.values.toList();

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList.separated(
            itemCount: groupList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _EmployeeGroupCard(pairs: groupList[i]),
          ),
        );
      },
    );
  }

  Widget _buildPagination(BuildContext context) {
    return BlocBuilder<PunchPairsCubit, PunchPairsState>(
      builder: (context, state) {
        if (state.status != PunchPairsStatus.success ||
            state.totalPages <= 1) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<PunchPairsCubit>();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // prev
                _PaginationButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  label: 'السابق',
                  enabled: state.pageNumber > 1,
                  onTap: cubit.prevPage,
                ),
                // page info
                Column(
                  children: [
                    Text(
                      'صفحة ${state.pageNumber} من ${state.totalPages}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${state.totalCount} سجل',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // next
                _PaginationButton(
                  icon: Icons.arrow_back_ios_rounded,
                  label: 'التالي',
                  enabled: state.pageNumber < state.totalPages,
                  onTap: cubit.nextPage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────── Employee Picker ────────────────────────────

class _EmployeePickerSheet extends StatefulWidget {
  final List<EmployeeOption> options;
  final String? selectedUserId;

  const _EmployeePickerSheet({
    required this.options,
    this.selectedUserId,
  });

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<EmployeeOption> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.options
          : widget.options
              .where((e) => e.name.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'اختر موظف',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (widget.selectedUserId != null)
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('عرض الكل'),
                        ),
                    ],
                  ),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن موظف...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                // List
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final opt = _filtered[i];
                      final isSelected =
                          opt.userId == widget.selectedUserId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : AppColors.backgroundSecondary,
                          child: Text(
                            opt.name.isNotEmpty
                                ? opt.name.substring(0, 1)
                                : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          opt.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.pop(context, opt),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────── Punch Pair Card ────────────────────────────

class _EmployeeGroupCard extends StatelessWidget {
  final List<PunchPair> pairs;

  const _EmployeeGroupCard({required this.pairs});

  @override
  Widget build(BuildContext context) {
    final employeeName = pairs.first.employeeName;
    
    // Calculate total duration for this group
    Duration totalDuration = Duration.zero;
    for (final p in pairs) {
      if (p.workedDuration != null) {
        totalDuration += p.workedDuration!;
      }
    }
    
    String totalDurationLabel = '';
    if (totalDuration.inMinutes > 0) {
      final h = totalDuration.inHours;
      final m = totalDuration.inMinutes.remainder(60);
      totalDurationLabel = h > 0 ? '$h س $m د' : '$m د';
    } else {
      totalDurationLabel = '--';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: AppColors.primaryTint,
            highlightColor: AppColors.primaryTint.withValues(alpha: 0.5),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  employeeName.isNotEmpty ? employeeName.substring(0, 1) : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Text(
              employeeName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${pairs.length} سجل',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    totalDurationLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            children: pairs.map((p) => _MiniPunchPairCard(pair: p)).toList(),
          ),
        ),
      ),
    );
  }
}

class _MiniPunchPairCard extends StatelessWidget {
  final PunchPair pair;

  const _MiniPunchPairCard({required this.pair});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (pair.isComplete) {
      statusColor = AppColors.success;
      statusLabel = 'حضر وانصرف';
      statusIcon = Icons.check_circle_rounded;
    } else if (pair.hasCheckIn) {
      statusColor = AppColors.warning;
      statusLabel = 'حضر فقط';
      statusIcon = Icons.login_rounded;
    } else {
      statusColor = AppColors.error;
      statusLabel = 'غياب';
      statusIcon = Icons.cancel_rounded;
    }

    String dateDisplay = pair.date;
    try {
      final d = DateTime.parse(pair.date);
      dateDisplay = DateFormat('EEEE، d MMMM yyyy', 'ar').format(d);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _TimeInfo(
                  label: 'دخول',
                  value: pair.checkIn ?? '--',
                  color: AppColors.success,
                  icon: Icons.login_rounded,
                ),
              ),
              Expanded(
                child: _TimeInfo(
                  label: 'خروج',
                  value: pair.checkOut ?? '--',
                  color: pair.hasCheckOut ? AppColors.error : AppColors.textTertiary,
                  icon: Icons.logout_rounded,
                ),
              ),
              Expanded(
                child: _TimeInfo(
                  label: 'المدة',
                  value: pair.workedDurationLabel,
                  color: pair.isComplete ? AppColors.primary : AppColors.textTertiary,
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TimeInfo({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Date Picker Button ──────────────────────────────────

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerButton({
    required this.label,
    this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSet ? AppColors.primary : AppColors.border,
            width: isSet ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSet ? AppColors.primaryTint : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color:
                    isSet ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isSet ? value! : label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSet
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSet ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 14, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Pagination Button ──────────────────────────────────

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryTint : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'السابق') ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon,
                  size: 14,
                  color: enabled
                      ? AppColors.primary
                      : AppColors.textTertiary),
            ] else ...[
              Icon(icon,
                  size: 14,
                  color: enabled
                      ? AppColors.primary
                      : AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Loading / Error / Empty ────────────────────────────

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'جاري تحميل السجلات...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد سجلات دخول/خروج',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'حاول تعديل الفلاتر أو اختيار فترة زمنية مختلفة',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
