import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/features/admin/cubit/admin_requests_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/skeleton/skeleton_list_item.dart';
import '../home/models/recent_activity.dart';
import 'cubit/admin_requests_cubit.dart';
import 'widgets/admin_request_card.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load requests when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminRequestsCubit>().loadRequests();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleApprove(String requestId, AdminRequestsCubit cubit) async {
    final success = await cubit.approveRequest(requestId);
    if (mounted && success) {
      CustomToast.showSuccess('تم الموافقة على الطلب بنجاح');
    } else if (mounted && cubit.state.error != null) {
      CustomToast.showError(cubit.state.error!);
    }
  }

  void _handleReject(String requestId, AdminRequestsCubit cubit) async {
    String? rejectReason;

    // Show dialog to enter reject reason (optional)
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (result == null) return; // User cancelled

    final confirmed = result['confirmed'] as bool;
    rejectReason = result['reason'] as String?;

    if (confirmed && mounted) {
      final success = await cubit.rejectRequest(
        requestId,
        rejectReason: rejectReason,
      );
      if (mounted && success) {
        CustomToast.showError('تم رفض الطلب');
      } else if (mounted && cubit.state.error != null) {
        CustomToast.showError(cubit.state.error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AdminRequestsCubit, AdminRequestsState>(
          builder: (context, state) {
            final cubit = context.read<AdminRequestsCubit>();

              return NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'إدارة الطلبات',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tabs
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: StatusTabsSliverDelegate(
                        StatusTabsBar(
                          controller: _tabController,
                          pendingLabel: 'قيد الانتظار',
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(state.allRequests, cubit),
                    _buildRequestsList(state.pendingRequests, cubit),
                    _buildRequestsList(state.approvedRequests, cubit),
                    _buildRequestsList(state.rejectedRequests, cubit),
                  ],
                ),
              );
            },
          ),
        ),
      );
  }

  Widget _buildRequestsList(
    List<RecentActivity> requests,
    AdminRequestsCubit cubit,
  ) {
    if (cubit.state.isLoading) {
      return RefreshIndicator(
        onRefresh: () => cubit.loadRequests(),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return const SkeletonListItem(showAvatar: true);
          },
        ),
      );
    }

    if (requests.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: 'لا توجد طلبات',
        message: 'لم يتم العثور على أي طلبات في هذه الفئة',
        iconColor: AppColors.textTertiary,
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.loadRequests(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: requests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = requests[index];
          return AdminRequestCard(
            request: request,
            isLoading: false,
            onApprove: request.status == RequestStatus.pending
                ? () => _handleApprove(request.id, cubit)
                : null,
            onReject: request.status == RequestStatus.pending
                ? () => _handleReject(request.id, cubit)
                : null,
          );
        },
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رفض الطلب',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'هل أنت متأكد من رفض هذا الطلب؟',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Reason input field
            Text(
              'سبب الرفض (اختياري)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _reasonController,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'أدخل سبب الرفض إن أردت...',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'confirmed': true,
                        'reason': _reasonController.text.trim().isEmpty
                            ? null
                            : _reasonController.text.trim(),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'رفض',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
