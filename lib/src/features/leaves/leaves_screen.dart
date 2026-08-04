import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import '../requests/services/requests_refresh_service.dart';
import 'create_leave_request_screen.dart';
import 'cubit/leaves_cubit.dart';
import 'cubit/leaves_state.dart';
import 'models/leave_balance_model.dart';
import 'models/leave_request_model.dart';
import 'models/leave_statistics.dart';
import 'widgets/leave_balance_details.dart';
import 'widgets/leave_request_card.dart';
import 'widgets/leaves_header.dart';

class LeavesScreen extends StatefulWidget {
  final int initialTab;

  const LeavesScreen({super.key, this.initialTab = 0});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late LeavesCubit _cubit;
  StreamSubscription<void>? _refreshSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3).toInt(),
    );
    // Keep the screen feeling instant: if we already have data, refresh silently.
    final cubit = getIt<LeavesCubit>();
    final hasData =
        cubit.state.leaveBalance != null || cubit.state.leaveRequests.isNotEmpty;
    _cubit = cubit
      ..loadLeavesOverview(silent: hasData);
    _refreshSubscription = getIt<RequestsRefreshService>().stream.listen((_) {
      if (mounted) {
        _cubit.loadLeavesOverview(silent: true, forceRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  LeaveStatistics _calculateStatistics(
    List<LeaveRequestModel> leaves,
    LeaveBalanceModel? balance,
  ) {
    final pending = leaves
        .where((l) => l.status.toLowerCase() == 'pending')
        .length;
    final approved = leaves
        .where((l) => l.status.toLowerCase() == 'approved')
        .length;
    final rejected = leaves
        .where((l) => l.status.toLowerCase() == 'rejected')
        .length;

    if (balance != null) {
      return LeaveStatistics(
        totalLeaves: balance.annualLeaveBalance,
        usedLeaves: balance.annualLeaveUsed,
        remainingLeaves: balance.annualLeaveRemaining,
        pendingRequests: pending,
        approvedRequests: approved,
        rejectedRequests: rejected,
      );
    }

    final used = leaves
        .where((l) => l.status.toLowerCase() == 'approved')
        .fold<int>(0, (sum, l) => sum + l.numberOfDays);
    const total = 21;
    final remaining = (total - used).clamp(0, total);

    return LeaveStatistics(
      totalLeaves: total,
      usedLeaves: used,
      remainingLeaves: remaining,
      pendingRequests: pending,
      approvedRequests: approved,
      rejectedRequests: rejected,
    );
  }

  List<LeaveRequestModel> _filterLeaves(
    List<LeaveRequestModel> all,
    String status,
  ) {
    return all
        .where((l) => l.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        floatingActionButton: BlocBuilder<LeavesCubit, LeavesState>(
          builder: (context, state) {
            return FloatingActionButton.extended(
              heroTag: 'leaves_fab',
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateLeaveRequestScreen(),
                  ),
                );

                if (result == true) {
                  _cubit.loadLeavesOverview(
                    silent: true,
                    forceRefresh: true,
                  );
                }
              },
              backgroundColor: AppColors.primary,
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: const Text(
                'إجازة جديدة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
        body: BlocBuilder<LeavesCubit, LeavesState>(
          builder: (context, state) {
            if (state.status == LeavesStatus.loading) {
              return const ListShimmerLoading();
            }

            if (state.status == LeavesStatus.failure) {
              return ErrorStateWidget(
                title: 'تعذر تحميل الإجازات',
                error: 'حدث خطأ مؤقت في الخادم. يرجى المحاولة مرة أخرى.',
                buttonLabel: 'إعادة المحاولة',
                onRetry: () => _cubit.loadLeavesOverview(forceRefresh: true),
                icon: Icons.calendar_today_outlined,
              );
            }

            final statistics = _calculateStatistics(
              state.leaveRequests,
              state.leaveBalance,
            );
            final allLeaves = state.leaveRequests;
            final pendingLeaves = _filterLeaves(allLeaves, 'pending');
            final approvedLeaves = _filterLeaves(allLeaves, 'approved');
            final rejectedLeaves = _filterLeaves(allLeaves, 'rejected');

            return RefreshIndicator(
              onRefresh: () async {
                await _cubit.loadLeavesOverview(
                  silent: true,
                  forceRefresh: true,
                );
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: LeavesHeader(statistics: statistics),
                    ),
                    if (state.leaveBalance != null)
                      SliverToBoxAdapter(
                        child: LeaveBalanceDetails(
                          balance: state.leaveBalance!,
                        ),
                      ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: StatusTabsSliverDelegate(
                        StatusTabsBar(
                          controller: _tabController,
                          pendingLabel: 'معلقة',
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeavesList(allLeaves),
                    _buildLeavesList(pendingLeaves),
                    _buildLeavesList(approvedLeaves),
                    _buildLeavesList(rejectedLeaves),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeavesList(List<LeaveRequestModel> leaves) {
    if (leaves.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.calendar_today_outlined,
        title: 'لا توجد إجازات',
        message: 'ستظهر طلبات الإجازات هنا بمجرد إضافتها أو تحديث حالتها.',
        iconColor: AppColors.textTertiary,
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom + 72,
      ),
      itemCount: leaves.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _LeavesListIntro(count: leaves.length);
        }
        return LeaveRequestCard(leaveRequest: leaves[index - 1]);
      },
    );
  }
}

class _LeavesListIntro extends StatelessWidget {
  final int count;

  const _LeavesListIntro({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عرض مرتب لطلبات الإجازة',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'يوجد $count طلب في هذا القسم. افتح أي بطاقة لرؤية التفاصيل الكاملة.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
