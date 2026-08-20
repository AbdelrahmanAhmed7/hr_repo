import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final textMuted = theme.hintColor;
        final dividerColor = theme.dividerColor;
        final surfaceVariant = theme.colorScheme.surfaceContainerHighest;

        final isExpanded = state.expandedUserId == item.userId;
        final isLoadingPairs = state.pairsLoadingUserId == item.userId;
        final pairs = state.pairsCache[item.userId];

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: dividerColor)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Collapsed header row ──────────────────────────────
              InkWell(
                onTap: () =>
                    context.read<PunchCubit>().toggleExpand(item.userId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Expand indicator
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        child: Text(
                          _getInitials(item.employeeName),
                          style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Name
                      Expanded(
                        child: Text(
                          item.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Hours summary
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 12, color: primary),
                              const SizedBox(width: 3),
                              Text(
                                item.workedFormatted,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                          if (item.breakHours > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.free_breakfast_rounded,
                                    size: 11, color: textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  item.breakFormatted,
                                  style: TextStyle(
                                      fontSize: 11, color: textMuted),
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
                  surfaceVariant: surfaceVariant,
                  textMuted: textMuted,
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
  final Color surfaceVariant;
  final Color textMuted;

  const _ExpandedPanel({
    required this.userId,
    required this.isLoading,
    required this.pairs,
    required this.surfaceVariant,
    required this.textMuted,
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
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ),
      );
    } else {
      content = Column(
        children: pairs!
            .map((p) => PunchPairItem(item: p))
            .toList(),
      );
    }

    return Container(
      color: surfaceVariant.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: content,
      ),
    );
  }
}
