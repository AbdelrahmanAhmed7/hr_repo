import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../cubit/employee_of_month_cubit.dart';
import '../cubit/employee_of_month_state.dart';
import '../widgets/nominee_card.dart';
import '../widgets/vote_confirmation_dialog.dart';
import '../widgets/winner_card.dart';

// Arabic month names
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

class EmployeeOfMonthScreen extends StatefulWidget {
  const EmployeeOfMonthScreen({super.key});

  @override
  State<EmployeeOfMonthScreen> createState() => _EmployeeOfMonthScreenState();
}

class _EmployeeOfMonthScreenState extends State<EmployeeOfMonthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeOfMonthCubit>().loadData();
    });
  }

  void _showVoteDialog(BuildContext ctx, String userId, String name) {
    showDialog<bool>(
      context: ctx,
      builder: (_) => VoteConfirmationDialog(
        nomineeName: name,
        onConfirm: () => ctx.read<EmployeeOfMonthCubit>().vote(userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: BlocConsumer<EmployeeOfMonthCubit, EmployeeOfMonthState>(
        listenWhen: (prev, curr) =>
            prev.voteStatus != curr.voteStatus || prev.status != curr.status,
        listener: (ctx, state) {
          if (state.voteStatus == VoteStatus.success) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('تم تصويتك بنجاح 🎉'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.voteStatus == VoteStatus.error &&
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
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ─────────────────────────────────────────────────
              SliverToBoxAdapter(child: _Header(state: state)),

              // ── Loading ─────────────────────────────────────────────────
              if (state.status == EmployeeOfMonthStatus.loading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList.separated(
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => _NomineeSkeleton(),
                  ),
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
                    onButtonPressed: () =>
                        ctx.read<EmployeeOfMonthCubit>().loadData(),
                  ),
                ),

              // ── Success ─────────────────────────────────────────────────
              if (state.status == EmployeeOfMonthStatus.success) ...[
                // Voted banner
                if (state.hasVoted)
                  SliverToBoxAdapter(
                    child: _VotedBanner(name: state.votedForName ?? ''),
                  ),

                // Section 1 header — nominees
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.how_to_vote_rounded,
                    title: 'موظف الشهر — ${_monthName(state.currentMonth)}',
                  ),
                ),

                // Nominees list
                if (state.nominees.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: EmptyStateWidget(
                        icon: Icons.people_outline_rounded,
                        title: 'لا يوجد مرشحون حتى الآن',
                        iconColor: AppColors.textTertiary,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverList.separated(
                      itemCount: state.nominees.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final nominee = state.nominees[i];
                        final isVotedFor =
                            nominee.userId == state.votedForUserId;
                        return NomineeCard(
                          nominee: nominee,
                          hasVoted: state.hasVoted,
                          isVotedFor: isVotedFor,
                          isVoteLoading: state.voteStatus == VoteStatus.loading,
                          onTap:
                              state.hasVoted ||
                                  state.voteStatus == VoteStatus.loading
                              ? null
                              : () => _showVoteDialog(
                                  ctx,
                                  nominee.userId,
                                  nominee.fullNameAr,
                                ),
                        );
                      },
                    ),
                  ),

                // Section 2 header — previous winner
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.emoji_events_rounded,
                    title: () {
                      final now = DateTime.now();
                      final prevMonth = now.month == 1 ? 12 : now.month - 1;
                      return 'الفائز بشهر ${_monthName(prevMonth)}';
                    }(),
                  ),
                ),

                if (state.winners.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: EmptyStateWidget(
                        icon: Icons.emoji_events_outlined,
                        title: 'لم يتم إعلان الفائز بعد',
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: state.winners.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          WinnerCard(winner: state.winners[i]),
                    ),
                  ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final EmployeeOfMonthState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'موظف الشهر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'صوّت لموظف الشهر',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFCD34D),
                    size: 32,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Voted Banner ─────────────────────────────────────────────────────────────

class _VotedBanner extends StatelessWidget {
  final String name;
  const _VotedBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'لقد صوّت بالفعل لـ '),
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' هذا الشهر'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nominee Skeleton ─────────────────────────────────────────────────────────

class _NomineeSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ShimmerPlaceholder(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  ShimmerPlaceholder(width: 120, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
