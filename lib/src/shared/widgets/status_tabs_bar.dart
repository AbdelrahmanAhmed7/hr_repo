import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable status tabs bar component
/// Used for filtering by status: All, Pending, Approved, Rejected
class StatusTabsBar extends StatelessWidget {
  final TabController controller;
  final String pendingLabel;

  const StatusTabsBar({
    super.key,
    required this.controller,
    this.pendingLabel = 'معلقة',
  });

  @override
  Widget build(BuildContext context) {
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: statusTabsBar,
    );
  }

  @override
  bool shouldRebuild(StatusTabsSliverDelegate oldDelegate) {
    return statusTabsBar.controller != oldDelegate.statusTabsBar.controller ||
        statusTabsBar.pendingLabel != oldDelegate.statusTabsBar.pendingLabel;
  }
}





