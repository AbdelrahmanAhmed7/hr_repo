import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import '../../core/services/service_locator.dart';
import '../requests/services/requests_refresh_service.dart';
import 'models/mission.dart';
import 'models/mission_statistics.dart';
import 'widgets/missions_header.dart';
import 'widgets/mission_card.dart';
import 'cubit/assignment_cubit.dart';
import 'cubit/assignment_state.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<AssignmentCubit>().loadMyAssignments();
    _refreshSubscription = getIt<RequestsRefreshService>().stream.listen((_) {
      if (mounted) {
        context.read<AssignmentCubit>().loadMyAssignments();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await context.read<AssignmentCubit>().loadMyAssignments();
  }

  List<Mission> _getMissionsByStatus(List<Mission> allMissions, MissionStatus status) {
    return allMissions.where((mission) => mission.status == status).toList();
  }

  MissionStatistics _calculateStatistics(List<Mission> missions) {
    final pending = missions.where((m) => m.status == MissionStatus.pending).length;
    final approved = missions.where((m) => m.status == MissionStatus.approved).length;
    final rejected = missions.where((m) => m.status == MissionStatus.rejected).length;
    
    return MissionStatistics(
      totalMissions: missions.length,
      pendingCount: pending,
      approvedCount: approved,
      rejectedCount: rejected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      floatingActionButton: FloatingActionButton(
        heroTag: 'missions_fab',
        onPressed: () {
          context.push('/missions/create').then((_) {
            // Refresh after creating new assignment
            _refreshData();
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<AssignmentCubit, AssignmentState>(
        listener: (context, state) {
          if (state.error != null) {
            CustomToast.showError(state.error!);
          }
        },
        builder: (context, state) {
          final allMissions = state.assignments;
          final statistics = _calculateStatistics(allMissions);
          final pendingMissions = _getMissionsByStatus(allMissions, MissionStatus.pending);
          final approvedMissions = _getMissionsByStatus(allMissions, MissionStatus.approved);
          final rejectedMissions = _getMissionsByStatus(allMissions, MissionStatus.rejected);

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: state.isLoading && allMissions.isEmpty
                ? const ListShimmerLoading()
                : NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              // Header
              SliverToBoxAdapter(
                          child: MissionsHeader(statistics: statistics),
              ),
              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: StatusTabsSliverDelegate(
                  StatusTabsBar(controller: _tabController),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
                        _buildMissionsList(allMissions),
                        _buildMissionsList(pendingMissions),
                        _buildMissionsList(approvedMissions),
                        _buildMissionsList(rejectedMissions),
            ],
          ),
        ),
          );
        },
      ),
    );
  }

  Widget _buildMissionsList(List<Mission> missions) {
    if (missions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'لا توجد مأموريات',
        message: 'لم يتم العثور على أي مأموريات في هذه الفئة',
        iconColor: AppColors.textTertiary,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: missions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return MissionCard(mission: missions[index]);
      },
    );
  }
}
