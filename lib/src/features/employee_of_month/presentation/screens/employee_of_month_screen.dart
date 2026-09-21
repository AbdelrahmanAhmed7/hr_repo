import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../cubit/employee_of_month_cubit.dart';
import '../cubit/employee_of_month_state.dart';
import '../employee_of_month_helpers.dart';
import '../widgets/nominee_card.dart';
import '../widgets/vote_confirmation_dialog.dart';
import '../widgets/winner_card.dart';
import '../../data/models/winner_model.dart';

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
              SliverToBoxAdapter(
                child: _HeroHeader(
                  month: state.currentMonth,
                  year: state.currentYear,
                ),
              ),

              if (state.status == EmployeeOfMonthStatus.loading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  sliver: SliverList.separated(
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, _) => const _NomineeSkeleton(),
                  ),
                ),

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

              if (state.status == EmployeeOfMonthStatus.success) ...[
                if (state.hasVoted)
                  SliverToBoxAdapter(
                    child: _VoteSuccessBanner(name: state.votedForName ?? ''),
                  ),

                SliverToBoxAdapter(
                  child: _SectionLabel(
                    icon: Icons.how_to_vote_rounded,
                    title: 'صوّت هذا الشهر',
                    count: state.nominees.length,
                    countLabel: 'مرشح',
                  ),
                ),

                if (state.nominees.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
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
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
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
                          isVoteLoading:
                              state.voteStatus == VoteStatus.loading,
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

                const SliverToBoxAdapter(child: SizedBox(height: 4)),

                SliverToBoxAdapter(
                  child: _SectionLabel(
                    icon: Icons.emoji_events_rounded,
                    title: state.winners.isEmpty
                        ? 'قاعة الفائزين'
                        : 'فائز شهر ${employeeOfMonthMonthName(state.winners.first.month)} ${state.winners.first.year}',
                    count: state.winners.length,
                    countLabel: 'فائز',
                  ),
                ),

                if (state.winners.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                      child: EmptyStateWidget(
                        icon: Icons.emoji_events_outlined,
                        title: 'لم يتم إعلان الفائز بعد',
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _WinnersHall(winners: state.winners),
                  ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Compact Hero Header ──────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final int month;
  final int year;

  const _HeroHeader({required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'موظف الشهر',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'صوّت لأفضل موظف هذا الشهر',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD34D).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFCD34D).withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFDE68A),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${employeeOfMonthMonthName(month)} $year',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFFDE68A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Vote Success Banner ──────────────────────────────────────────────────────

class _VoteSuccessBanner extends StatelessWidget {
  final String name;
  const _VoteSuccessBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.celebration_rounded,
            color: AppColors.success,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'أحسنت! صوتك لـ '),
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' تم تسجيله لهذا الشهر'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final String countLabel;

  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.count,
    required this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFB45309), size: 17),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count $countLabel',
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Winners Hall (compact podium + rows) ─────────────────────────────────────

class _WinnersHall extends StatelessWidget {
  final List<WinnerModel> winners;

  const _WinnersHall({required this.winners});

  @override
  Widget build(BuildContext context) {
    final sorted = [...winners]
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    // Fewer than 3 winners: dense medal rows — no wasted podium columns.
    if (sorted.length < 3) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            for (var i = 0; i < sorted.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WinnerCard(winner: sorted[i], rank: i + 1),
              ),
          ],
        ),
      );
    }

    final first = sorted[0];
    final second = sorted[1];
    final third = sorted[2];
    final extras = sorted.sublist(3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumColumn(winner: second, rank: 2),
              ),
              const SizedBox(width: 4),
              Expanded(child: _PodiumColumn(winner: first, rank: 1)),
              const SizedBox(width: 4),
              Expanded(child: _PodiumColumn(winner: third, rank: 3)),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < extras.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WinnerCard(winner: extras[i], rank: 4 + i),
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final WinnerModel winner;
  final int rank;

  const _PodiumColumn({required this.winner, required this.rank});

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};

  String get _initial {
    final trimmed = winner.fullNameAr.trim();
    return trimmed.isNotEmpty ? trimmed[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 68.0 : 50.0;
    final pedestalHeight = isFirst ? 48.0 : 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst) ...[
          const Text('🏆',
              style: TextStyle(fontSize: 18, height: 1)),
          const SizedBox(height: 3),
        ],
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isFirst
                  ? const [Color(0xFFFBBF24), Color(0xFFD97706)]
                  : const [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isFirst ? const Color(0xFFF59E0B) : Colors.black)
                    .withValues(alpha: isFirst ? 0.4 : 0.12),
                blurRadius: isFirst ? 18 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CachedAvatarWidget(
                imageUrl: winner.imageUrl,
                initials: _initial,
                size: avatarSize,
                backgroundColor: AppColors.primaryTint,
                textColor: AppColors.primary,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    _medals[rank] ?? '$rank',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            winner.fullNameAr,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: pedestalHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isFirst
                ? const Color(0xFFFBBF24)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            border: isFirst
                ? Border.all(color: const Color(0xFFD97706), width: 1)
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFirst ? Icons.emoji_events_rounded : Icons.how_to_vote_rounded,
                  color: isFirst ? Colors.white : AppColors.textTertiary,
                  size: isFirst ? 20 : 16,
                ),
                if (isFirst) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${winner.voteCount}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Nominee Skeleton ─────────────────────────────────────────────────────────

class _NomineeSkeleton extends StatelessWidget {
  const _NomineeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ShimmerPlaceholder(width: 56, height: 56, borderRadius: 28),
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
                  ShimmerPlaceholder(width: 130, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}