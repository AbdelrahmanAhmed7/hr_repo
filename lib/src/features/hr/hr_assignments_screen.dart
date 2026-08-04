import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import '../../shared/components/custom_toast.dart';
import '../missions/models/mission.dart';
import '../missions/models/mission_statistics.dart';
import '../missions/widgets/missions_header.dart';
import '../missions/widgets/mission_card.dart';
import '../missions/cubit/assignment_cubit.dart';
import '../missions/cubit/assignment_state.dart';
import 'widgets/hr_screen_header.dart';

class HRAssignmentsScreen extends StatefulWidget {
  const HRAssignmentsScreen({super.key});

  @override
  State<HRAssignmentsScreen> createState() => _HRAssignmentsScreenState();
}

class _HRAssignmentsScreenState extends State<HRAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<AssignmentCubit>().loadAllAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await context.read<AssignmentCubit>().loadAllAssignments();
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

  Future<void> _handleApprove(Mission mission) async {
    final cubit = context.read<AssignmentCubit>();
    final success = await cubit.updateAssignmentStatus(
      id: int.parse(mission.id),
      status: 2, // Approved
    );

    if (!mounted) return;

    if (success) {
      CustomToast.showSuccess('تمت الموافقة على المأمورية بنجاح');
    } else {
      final error = cubit.state.error ?? 'حدث خطأ أثناء الموافقة';
      CustomToast.showError(error);
    }
  }

  Future<void> _handleReject(Mission mission) async {
    // FIX: capture cubit before any await
    final cubit = context.read<AssignmentCubit>();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectionReasonDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    final success = await cubit.updateAssignmentStatus(
      id: int.parse(mission.id),
      status: 3,
      rejectionReason: reason,
    );

    if (!mounted) return;

    if (success) {
      CustomToast.showSuccess('تم رفض المأمورية');
    } else {
      final error = cubit.state.error ?? 'حدث خطأ أثناء الرفض';
      CustomToast.showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: BlocConsumer<AssignmentCubit, AssignmentState>(
        listener: (context, state) {
          if (state.error != null && !state.isLoading) {
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
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: HRScreenHeader(
                          title: 'المأموريات',
                          subtitle: 'مراجعة وموافقة على طلبات المأموريات',
                          icon: Icons.assignment_outlined,
                          showBackButton: true,
                        ),
                      ),
                      // Statistics Header
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
                      // Content
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMissionsList(allMissions),
                            _buildMissionsList(pendingMissions),
                            _buildMissionsList(approvedMissions),
                            _buildMissionsList(rejectedMissions),
                          ],
                        ),
                      ),
                    ],
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
        final mission = missions[index];
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              MissionCard(mission: mission),
              // Action buttons for pending missions
              if (mission.status == MissionStatus.pending)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleReject(mission),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('رفض'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleApprove(mission),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('موافقة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RejectionReasonDialog extends StatefulWidget {
  @override
  State<_RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<_RejectionReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('سبب الرفض'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'أدخل سبب رفض المأمورية',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('رفض'),
        ),
      ],
    );
  }
}
