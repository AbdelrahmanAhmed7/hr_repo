import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../cubit/employee_of_month_cubit.dart';
import '../cubit/employee_of_month_state.dart';
import '../widgets/winner_card.dart';

const _kMonthNames = [
  'يناير',
  'فبراير',
  'مارس',
  'إبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String _monthName(int month) => _kMonthNames[(month - 1).clamp(0, 11)];

class SuperAdminEmployeeOfMonthScreen extends StatefulWidget {
  const SuperAdminEmployeeOfMonthScreen({super.key});

  @override
  State<SuperAdminEmployeeOfMonthScreen> createState() =>
      _SuperAdminEmployeeOfMonthScreenState();
}

class _SuperAdminEmployeeOfMonthScreenState
    extends State<SuperAdminEmployeeOfMonthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminEmployeeOfMonthCubit>().loadWinners();
    });
  }

  void _prevMonth(
    SuperAdminEmployeeOfMonthCubit cubit,
    SuperAdminEmployeeOfMonthState state,
  ) {
    int month = state.selectedMonth;
    int year = state.selectedYear;
    if (month == 1) {
      month = 12;
      year -= 1;
    } else {
      month--;
    }
    cubit.changeMonth(month, year);
  }

  void _nextMonth(
    SuperAdminEmployeeOfMonthCubit cubit,
    SuperAdminEmployeeOfMonthState state,
  ) {
    int month = state.selectedMonth;
    int year = state.selectedYear;
    final now = DateTime.now();
    // Do not allow navigating into the future beyond current month.
    if (year == now.year && month >= now.month) return;
    if (month == 12) {
      month = 1;
      year += 1;
    } else {
      month++;
    }
    cubit.changeMonth(month, year);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      SuperAdminEmployeeOfMonthCubit,
      SuperAdminEmployeeOfMonthState
    >(
      listenWhen: (prev, curr) => prev.calculateStatus != curr.calculateStatus,
      listener: (ctx, state) {
        if (state.calculateStatus == CalculateStatus.success) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('تم حساب الفائز بنجاح 🎉'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.calculateStatus == CalculateStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (ctx, state) {
        final cubit = ctx.read<SuperAdminEmployeeOfMonthCubit>();
        final now = DateTime.now();
        final isCurrentMonth =
            state.selectedMonth == now.month && state.selectedYear == now.year;

        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ─────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(ctx, state, cubit)),

              // ── Month Selector ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _MonthSelector(
                  month: state.selectedMonth,
                  year: state.selectedYear,
                  isAtCurrentMonth: isCurrentMonth,
                  onPrev: () => _prevMonth(cubit, state),
                  onNext: () => _nextMonth(cubit, state),
                ),
              ),

              // ── Loading ─────────────────────────────────────────────────
              if (state.status == EmployeeOfMonthStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),

              // ── Error ───────────────────────────────────────────────────
              if (state.status == EmployeeOfMonthStatus.error)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: 'تعذر تحميل البيانات',
                    message: state.errorMessage,
                    buttonLabel: 'إعادة المحاولة',
                    iconColor: AppColors.error,
                    onButtonPressed: () => cubit.loadWinners(),
                  ),
                ),

              // ── Success ─────────────────────────────────────────────────
              if (state.status == EmployeeOfMonthStatus.success) ...[
                if (state.winners.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoWinnersSection(
                      onCalculate: () => cubit.calculateWinners(),
                      isLoading:
                          state.calculateStatus == CalculateStatus.loading,
                    ),
                  )
                else ...[
                  // Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'الفائزون',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: state.winners.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          WinnerCard(winner: state.winners[i]),
                    ),
                  ),
                  // Recalculate button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: _CalculateButton(
                        onCalculate: () => cubit.calculateWinners(),
                        isLoading:
                            state.calculateStatus == CalculateStatus.loading,
                        label: 'إعادة الحساب',
                        outlined: true,
                      ),
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SuperAdminEmployeeOfMonthState state,
    SuperAdminEmployeeOfMonthCubit cubit,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFCD34D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'موظف الشهر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'إدارة وحساب الفائزين',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Refresh
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: cubit.loadWinners,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Month Selector ───────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final int month;
  final int year;
  final bool isAtCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.month,
    required this.year,
    required this.isAtCurrentMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.primary,
          ),
          Column(
            children: [
              Text(
                _monthName(month),
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$year',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: isAtCurrentMonth ? null : onNext,
            icon: const Icon(Icons.chevron_left_rounded),
            color: isAtCurrentMonth
                ? AppColors.textTertiary
                : AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── No Winners Section ───────────────────────────────────────────────────────

class _NoWinnersSection extends StatelessWidget {
  final VoidCallback onCalculate;
  final bool isLoading;

  const _NoWinnersSection({required this.onCalculate, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لم يتم حساب الفائز بعد',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على الزر أدناه لحساب الفائز لهذا الشهر',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _CalculateButton(
              onCalculate: onCalculate,
              isLoading: isLoading,
              label: 'احسب الفائز الآن',
              outlined: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calculate Button ─────────────────────────────────────────────────────────

class _CalculateButton extends StatelessWidget {
  final VoidCallback onCalculate;
  final bool isLoading;
  final String label;
  final bool outlined;

  const _CalculateButton({
    required this.onCalculate,
    required this.isLoading,
    required this.label,
    required this.outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onCalculate,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.calculate_rounded),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onCalculate,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.calculate_rounded),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
