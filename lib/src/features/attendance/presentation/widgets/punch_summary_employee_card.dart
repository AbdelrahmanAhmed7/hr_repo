import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/punch_pair_model.dart';
import '../../data/models/punch_summary_model.dart';
import '../cubit/punch_cubit.dart';
import '../cubit/punch_state.dart';
import 'punch_pair_item.dart';

class PunchSummaryEmployeeCard extends StatelessWidget {
  final PunchSummaryModel item;

  const PunchSummaryEmployeeCard({super.key, required this.item});

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    if (name.isEmpty) return '?';
    return name.substring(0, min(2, name.length));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (context, state) {
        final isExpanded = state.expandedUserId == item.userId;
        final isLoadingPairs = state.pairsLoadingUserId == item.userId;
        final pairs = state.pairsCache[item.userId];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Collapsed header row ──────────────────────────────
              InkWell(
                onTap: () =>
                    context.read<PunchCubit>().toggleExpand(item.userId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          _getInitials(item.employeeName),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.workedFormatted,
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (item.breakHours > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.free_breakfast_rounded,
                                  size: 11,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item.breakFormatted,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expanded panel ────────────────────────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: _ExpandedPanel(
                  userId: item.userId,
                  isLoading: isLoadingPairs,
                  pairs: pairs,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Expanded Panel ───────────────────────────────────────────────────────────

class _ExpandedPanel extends StatelessWidget {
  final String userId;
  final bool isLoading;
  final List<PunchPairModel>? pairs;

  const _ExpandedPanel({
    required this.userId,
    required this.isLoading,
    required this.pairs,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (pairs == null || pairs!.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'لا يوجد بيانات',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    } else {
      // Collect all permissions & assignments across every pair
      final allPermissions = <PunchPairPermission>[];
      final allAssignments = <PunchPairAssignment>[];
      for (final p in pairs!) {
        allPermissions.addAll(p.permissions);
        allAssignments.addAll(p.assignments);
      }

      content = Column(
        children: [
          ...pairs!.map((p) => PunchPairItem(item: p)),
          if (allPermissions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BigRequestBanner(
                icon: Icons.logout_rounded,
                color: AppColors.warning,
                label: 'أذن',
                reason: allPermissions.first.reason,
                time: allPermissions.first.displayTime,
                count: allPermissions.length,
              ),
            ),
          ],
          if (allAssignments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BigRequestBanner(
                icon: Icons.flight_takeoff_rounded,
                color: AppColors.info,
                label: 'مأمورية',
                reason: allAssignments.first.reason,
                time: allAssignments.first.displayTime,
                count: allAssignments.length,
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      color: AppColors.backgroundSecondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: content,
      ),
    );
  }
}