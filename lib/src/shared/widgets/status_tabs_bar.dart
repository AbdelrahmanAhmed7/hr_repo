import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Visual variant of the status tabs bar.
/// - [underline]: classic text tabs with a bottom indicator (default).
/// - [segmented]: pill buttons on a tinted track, matching flat card UIs.
enum StatusTabsStyle { underline, segmented }

/// Reusable status tabs bar component
/// Used for filtering by status: All, Pending, Approved, Rejected
class StatusTabsBar extends StatelessWidget {
  final TabController controller;
  final String pendingLabel;
  final StatusTabsStyle style;
  /// Optional counts shown next to each tab label: [all, pending, approved, rejected].
  final List<int>? tabCounts;

  const StatusTabsBar({
    super.key,
    required this.controller,
    this.pendingLabel = 'معلقة',
    this.style = StatusTabsStyle.underline,
    this.tabCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (style == StatusTabsStyle.segmented) {
      return _buildSegmented();
    }
    return _buildUnderline();
  }

  Widget _buildSegmented() {
    final counts = tabCounts;
    String label(String text, int index) {
      if (counts != null && index >= 0 && index < counts.length) {
        return '$text (${counts[index]})';
      }
      return text;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        height: 40,
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            height: 1.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            height: 1.2,
          ),
          labelPadding: EdgeInsets.zero,
          tabs: [
            Tab(text: label('الكل', 0)),
            Tab(text: label(pendingLabel, 1)),
            Tab(text: label('موافق عليها', 2)),
            Tab(text: label('مرفوضة', 3)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          height: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 1.2,
        ),
        labelPadding: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: [
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'الكل',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                pendingLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'موافق عليها',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'مرفوضة',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SliverPersistentHeader delegate for status tabs
class StatusTabsSliverDelegate extends SliverPersistentHeaderDelegate {
  final StatusTabsBar statusTabsBar;

  StatusTabsSliverDelegate(this.statusTabsBar);

  @override
  double get minExtent {
    if (statusTabsBar.style == StatusTabsStyle.segmented) {
      // 40 (tabs) + 8 (track padding) + 10 (top margin) + 16 (wrapper padding)
      return 74;
    }
    // Create a temporary TabBar to get its preferred size
    final tempTabBar = TabBar(
      controller: statusTabsBar.controller,
      labelStyle: const TextStyle(fontSize: 12, height: 1.2),
      tabs: const [
        Tab(text: 'الكل'),
        Tab(text: 'معلقة'),
        Tab(text: 'موافق عليها'),
        Tab(text: 'مرفوضة'),
      ],
    );
    return tempTabBar.preferredSize.height + 16;
  }

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isSegmented = statusTabsBar.style == StatusTabsStyle.segmented;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isSegmented ? 16 : 0,
        right: isSegmented ? 16 : 0,
      ),
      child: statusTabsBar,
    );
  }

  @override
  bool shouldRebuild(StatusTabsSliverDelegate oldDelegate) {
    return statusTabsBar.controller != oldDelegate.statusTabsBar.controller ||
        statusTabsBar.pendingLabel != oldDelegate.statusTabsBar.pendingLabel ||
        statusTabsBar.style != oldDelegate.statusTabsBar.style ||
        statusTabsBar.tabCounts != oldDelegate.statusTabsBar.tabCounts;
  }
}





