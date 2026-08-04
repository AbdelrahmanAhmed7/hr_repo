import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/cubit/auth_state.dart' show UserRole;
import '../../shared/widgets/error_state_widget.dart';
import 'models/public_holiday_model.dart';
import 'cubit/holidays_cubit.dart';
import 'repository/public_holiday_repository.dart';
import 'widgets/holiday_list_tile.dart';
import 'widgets/holiday_form_dialog.dart';
import 'widgets/holiday_exceptions_dialog.dart';

class HolidaysScreen extends StatelessWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<HolidaysCubit>()..loadHolidays(DateTime.now().year),
        ),
        BlocProvider.value(value: getIt<AuthCubit>()),
      ],
      child: const _HolidaysScreenContent(),
    );
  }
}

class _HolidaysScreenContent extends StatefulWidget {
  const _HolidaysScreenContent();

  @override
  State<_HolidaysScreenContent> createState() => _HolidaysScreenContentState();
}

class _HolidaysScreenContentState extends State<_HolidaysScreenContent> {
  int _selectedYear = DateTime.now().year;
  bool _showOnlyUpcoming = false;

  bool get _canManageHolidays {
    final authState = context.read<AuthCubit>().state;
    if (authState.isAuthenticated) {
      final role = authState.role;
      return role == UserRole.hr || role == UserRole.admin || role == UserRole.superAdmin;
    }
    return false;
  }

  Future<void> _selectYear() async {
    final year = await showDialog<int>(
      context: context,
      builder: (context) => _YearPickerDialog(initialYear: _selectedYear),
    );
    if (year != null && year != _selectedYear) {
      setState(() => _selectedYear = year);
      if (mounted) {
        context.read<HolidaysCubit>().loadHolidays(year);
      }
    }
  }

  void _showAddHolidayDialog() {
    final cubit = context.read<HolidaysCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => HolidayFormDialog(
        onSave: (holiday) async {
          await cubit.createHoliday(holiday);
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        },
      ),
    );
  }

  void _showEditHolidayDialog(PublicHolidayModel holiday) {
    final cubit = context.read<HolidaysCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => HolidayFormDialog(
        holiday: holiday,
        onSave: (updatedHoliday) async {
          await cubit.updateHoliday(holiday.id, updatedHoliday);
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(PublicHolidayModel holiday) {
    final cubit = context.read<HolidaysCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الإجازة'),
        content: Text('هل أنت متأكد من حذف "${holiday.nameAr}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              await cubit.deleteHoliday(holiday.id);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showExceptionsDialog(PublicHolidayModel holiday) {
    showDialog(
      context: context,
      builder: (context) => HolidayExceptionsDialog(
        holiday: holiday,
        repository: getIt<PublicHolidayRepository>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: BlocConsumer<HolidaysCubit, HolidaysState>(
        listener: (context, state) {
          if (state is HolidaysError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HolidaysCubit>().loadHolidays(_selectedYear),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: AppColors.backgroundSecondary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                title: const Text('الإجازات العامة'),
                actions: [
                  if (_canManageHolidays)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _showAddHolidayDialog,
                      tooltip: 'إضافة إجازة',
                    ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      setState(() => _showOnlyUpcoming = !_showOnlyUpcoming);
                    },
                    tooltip: _showOnlyUpcoming ? 'عرض الكل' : 'الإجازات القادمة فقط',
                    color: _showOnlyUpcoming ? AppColors.primary : null,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.backgroundSecondary,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Year Selector & Stats
              SliverToBoxAdapter(
                child: _buildYearSelector(state),
              ),

              // Holidays List
              if (state is HolidaysLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is HolidaysLoaded)
                _buildHolidaysList(state.holidays)
              else if (state is HolidayExceptionsLoading)
                _buildHolidaysList(state.previousState.holidays)
              else if (state is HolidayExceptionsLoaded)
                _buildHolidaysList(state.holidays)
              else
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    title: 'تعذر تحميل الإجازات الرسمية',
                    error: 'حدث خطأ مؤقت. يرجى المحاولة مرة أخرى.',
                    buttonLabel: 'إعادة المحاولة',
                    onRetry: () => context.read<HolidaysCubit>().loadHolidays(_selectedYear),
                    icon: Icons.event_busy_rounded,
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
  }

  Widget _buildYearSelector(HolidaysState state) {
    final holidays = state is HolidaysLoaded
        ? state.holidays
        : state is HolidayExceptionsLoaded
            ? state.holidays
            : <PublicHolidayModel>[];

    final upcomingCount = holidays.where((h) => h.date.isAfter(DateTime.now())).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          // Year Selector Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سنة $_selectedYear',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${holidays.length} إجازة رسمية',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _selectYear,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'تغيير',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.event_available_rounded,
                  value: '${holidays.length}',
                  label: 'إجمالي الإجازات',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_outlined,
                  value: '$upcomingCount',
                  label: 'الإجازات القادمة',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHolidaysList(List<PublicHolidayModel> holidays) {
    var filteredHolidays = holidays;

    if (_showOnlyUpcoming) {
      final now = DateTime.now();
      filteredHolidays = holidays.where((h) => h.date.isAfter(now)).toList();
    }

    // Sort by date
    filteredHolidays.sort((a, b) => a.date.compareTo(b.date));

    if (filteredHolidays.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(showOnlyUpcoming: _showOnlyUpcoming),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final holiday = filteredHolidays[index];
            return HolidayListTile(
              holiday: holiday,
              onTap: () {
                // Show holiday details or options
              },
              onEdit: _canManageHolidays ? () => _showEditHolidayDialog(holiday) : null,
              onDelete: _canManageHolidays ? () => _showDeleteConfirmation(holiday) : null,
              onManageExceptions: _canManageHolidays ? () => _showExceptionsDialog(holiday) : null,
            );
          },
          childCount: filteredHolidays.length,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showOnlyUpcoming;

  const _EmptyState({required this.showOnlyUpcoming});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          showOnlyUpcoming ? Icons.event_busy : Icons.calendar_today,
          size: 64,
          color: AppColors.textTertiary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          showOnlyUpcoming
              ? 'لا توجد إجازات قادمة في هذه السنة'
              : 'لا توجد إجازات مسجلة في هذه السنة',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _YearPickerDialog extends StatefulWidget {
  final int initialYear;

  const _YearPickerDialog({required this.initialYear});

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (i) => currentYear - 5 + i);

    return AlertDialog(
      title: const Text('اختيار السنة'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: years.length,
          itemBuilder: (context, index) {
            final year = years[index];
            final isSelected = year == _selectedYear;
            return ListTile(
              title: Text(
                '$year',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : null,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(context, year),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
