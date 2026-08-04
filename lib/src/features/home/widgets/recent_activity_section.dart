import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/skeleton/skeleton_activity_item.dart';
import '../models/recent_activity.dart';
import 'recent_activity_card.dart';

class RecentActivitySection extends StatefulWidget {
  final List<RecentActivity>? activities;
  final List<RecentActivity>? pendingActivities;
  final List<RecentActivity>? acceptedActivities;
  final List<RecentActivity>? rejectedActivities;
  final VoidCallback? onViewAll;
  final VoidCallback? onOpenPending;
  final bool isLoading;

  const RecentActivitySection({
    super.key,
    this.activities,
    this.pendingActivities,
    this.acceptedActivities,
    this.rejectedActivities,
    this.onViewAll,
    this.onOpenPending,
    this.isLoading = false,
  });

  @override
  State<RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  int _selectedIndex = 0;

  static const _tabs = [
    _ActivityTab(
      label: '\u0627\u0644\u0643\u0644',
      emptyLabel: '\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0644\u0628\u0627\u062a \u0628\u0639\u062f',
    ),
    _ActivityTab(
      label: '\u0645\u0639\u0644\u0642\u0629',
      emptyLabel:
          '\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0644\u0628\u0627\u062a \u0645\u0639\u0644\u0642\u0629',
    ),
    _ActivityTab(
      label: '\u0645\u0642\u0628\u0648\u0644\u0629',
      emptyLabel:
          '\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0644\u0628\u0627\u062a \u0645\u0642\u0628\u0648\u0644\u0629',
    ),
    _ActivityTab(
      label: '\u0645\u0631\u0641\u0648\u0636\u0629',
      emptyLabel:
          '\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0644\u0628\u0627\u062a \u0645\u0631\u0641\u0648\u0636\u0629',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.activities == null) {
      return _LoadingState(onViewAll: widget.onViewAll);
    }

    if (widget.activities!.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentList = _currentList();
    final currentTab = _tabs[_selectedIndex];
    final totalCount = widget.activities?.length ?? 0;
    final pendingCount = widget.pendingActivities?.length ?? 0;
    final acceptedCount = widget.acceptedActivities?.length ?? 0;
    final rejectedCount = widget.rejectedActivities?.length ?? 0;
    final contextualActionLabel = _selectedIndex == 1 && pendingCount > 0
        ? 'فتح المعلقة'
        : 'عرض الكل';
    final contextualAction = _selectedIndex == 1 && pendingCount > 0
        ? widget.onOpenPending
        : widget.onViewAll;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: '\u0622\u062e\u0631 \u0627\u0644\u062d\u0631\u0643\u0627\u062a',
            title: '\u0637\u0644\u0628\u0627\u062a\u0643 \u0627\u0644\u0623\u062e\u064a\u0631\u0629',
            icon: Icons.history_rounded,
            actionLabel: contextualAction != null
                ? contextualActionLabel
                : null,
            onAction: contextualAction,
          ),
          const SizedBox(height: 12),
          _ActivityOverview(
            totalCount: totalCount,
            pendingCount: pendingCount,
            acceptedCount: acceptedCount,
            rejectedCount: rejectedCount,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index == _tabs.length - 1 ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      _tabs[index].label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
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
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIndex = index);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (currentList.isEmpty)
            _EmptyState(
              label: currentTab.emptyLabel,
              actionLabel: contextualActionLabel,
              onAction: contextualAction,
            )
          else
            ...currentList.take(3).map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RecentActivityCard(activity: activity),
                  ),
                ),
        ],
      ),
    );
  }

  List<RecentActivity> _currentList() {
    switch (_selectedIndex) {
      case 0:
        return widget.activities ?? [];
      case 1:
        return widget.pendingActivities ?? [];
      case 2:
        return widget.acceptedActivities ?? [];
      case 3:
        return widget.rejectedActivities ?? [];
      default:
        return widget.activities ?? [];
    }
  }
}

class _ActivityTab {
  final String label;
  final String emptyLabel;

  const _ActivityTab({
    required this.label,
    required this.emptyLabel,
  });
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityOverview extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final int acceptedCount;
  final int rejectedCount;

  const _ActivityOverview({
    required this.totalCount,
    required this.pendingCount,
    required this.acceptedCount,
    required this.rejectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActivityCountPill(
          label: 'الكل',
          value: '$totalCount',
          color: AppColors.primary,
        ),
        _ActivityCountPill(
          label: 'معلقة',
          value: '$pendingCount',
          color: const Color(0xFFD97706),
        ),
        _ActivityCountPill(
          label: 'مقبولة',
          value: '$acceptedCount',
          color: const Color(0xFF0F7D3E),
        ),
        _ActivityCountPill(
          label: 'مرفوضة',
          value: '$rejectedCount',
          color: const Color(0xFFC41E3A),
        ),
      ],
    );
  }
}

class _ActivityCountPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ActivityCountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final VoidCallback? onViewAll;

  const _LoadingState({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: '\u0622\u062e\u0631 \u0627\u0644\u062d\u0631\u0643\u0627\u062a',
            title: '\u0637\u0644\u0628\u0627\u062a\u0643 \u0627\u0644\u0623\u062e\u064a\u0631\u0629',
            icon: Icons.history_rounded,
            actionLabel:
                onViewAll != null ? '\u0639\u0631\u0636 \u0627\u0644\u0643\u0644' : null,
            onAction: onViewAll,
          ),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const SkeletonActivityItem(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
