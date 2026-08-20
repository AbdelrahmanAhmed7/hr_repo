import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/features/admin/cubit/admin_requests_state.dart';
import '../../core/theme/app_colors.dart';
import '../requests/widgets/requests_header.dart';
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

enum _RequestTypeFilter { all, leaves, permissions, missions }

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _RequestTypeFilter _selectedTypeFilter = _RequestTypeFilter.all;
  int? _selectedMonth;

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

  void _handleMonthChanged(int? month) {
    if (_selectedMonth == month) return;
    setState(() => _selectedMonth = month);
    context.read<AdminRequestsCubit>().loadRequests(month: month);
  }

  int _countByType(List<RecentActivity> requests, RequestType type) {
    return requests.where((item) => item.type == type).length;
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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AdminRequestsCubit, AdminRequestsState>(
          builder: (context, state) {
            final cubit = context.read<AdminRequestsCubit>();

              return NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: RequestsHeader(
                        title: 'إدارة الطلبات',
                        subtitle: 'متابعة طلبات الموظفين والإجراءات عليها من مكان واحد',
                        countLabel: _selectedMonth == null
                            ? 'إجمالي الطلبات'
                            : 'طلبات الشهر',
                        requestCount: state.allRequests.length,
                        selectedMonth: _selectedMonth,
                        onMonthChanged: _handleMonthChanged,
                        icon: Icons.request_quote_rounded,
                        accentColor: const Color(0xFFFFB74D),
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                        child: _RequestsTypeFilterBar(
                          selectedFilter: _selectedTypeFilter,
                          onChanged: (filter) {
                            setState(() => _selectedTypeFilter = filter);
                          },
                          allCount: state.allRequests.length,
                          leavesCount: _countByType(
                            state.allRequests,
                            RequestType.leave,
                          ),
                          permissionsCount: _countByType(
                            state.allRequests,
                            RequestType.permission,
                          ),
                          missionsCount: _countByType(
                            state.allRequests,
                            RequestType.assignment,
                          ),
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

  List<RecentActivity> _applyTypeFilter(List<RecentActivity> requests) {
    switch (_selectedTypeFilter) {
      case _RequestTypeFilter.all:
        return requests;
      case _RequestTypeFilter.leaves:
        return requests
            .where((item) => item.type == RequestType.leave)
            .toList();
      case _RequestTypeFilter.permissions:
        return requests
            .where((item) => item.type == RequestType.permission)
            .toList();
      case _RequestTypeFilter.missions:
        return requests
            .where((item) => item.type == RequestType.assignment)
            .toList();
    }
  }

  Widget _buildRequestsList(List<RecentActivity> requests, AdminRequestsCubit cubit) {
    final filteredRequests = _applyTypeFilter(requests);

    if (cubit.state.isLoading) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return const SkeletonListItem(showAvatar: true);
        },
      );
    }

    if (filteredRequests.isEmpty) {
      final isFilteredOut = requests.isNotEmpty;
      return RefreshIndicator(
        onRefresh: () => cubit.loadRequests(month: _selectedMonth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: EmptyStateWidget(
                  icon: isFilteredOut
                      ? Icons.filter_alt_off_rounded
                      : Icons.inbox_outlined,
                  title: isFilteredOut ? 'لا توجد نتائج لهذه الفلترة' : 'لا توجد طلبات',
                  message: isFilteredOut
                      ? 'جرّب تغيير نوع الطلب أو اختيار تبويب حالة مختلف.'
                      : 'لم يتم العثور على أي طلبات في هذه الفئة بعد.',
                  iconColor: isFilteredOut
                      ? AppColors.warning
                      : AppColors.textTertiary,
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.loadRequests(month: _selectedMonth),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: filteredRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = filteredRequests[index];
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

class _RequestsTypeFilterBar extends StatelessWidget {
  final _RequestTypeFilter selectedFilter;
  final ValueChanged<_RequestTypeFilter> onChanged;
  final int allCount;
  final int leavesCount;
  final int permissionsCount;
  final int missionsCount;

  const _RequestsTypeFilterBar({
    required this.selectedFilter,
    required this.onChanged,
    required this.allCount,
    required this.leavesCount,
    required this.permissionsCount,
    required this.missionsCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TypeChip(
            label: 'الكل',
            icon: Icons.apps_rounded,
            color: AppColors.primary,
            count: allCount,
            isSelected: selectedFilter == _RequestTypeFilter.all,
            onTap: () => onChanged(_RequestTypeFilter.all),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'إجازات',
            icon: Icons.airline_seat_individual_suite_rounded,
            color: AppColors.primaryLight,
            count: leavesCount,
            isSelected: selectedFilter == _RequestTypeFilter.leaves,
            onTap: () => onChanged(_RequestTypeFilter.leaves),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'أذونات',
            icon: Icons.logout_rounded,
            color: AppColors.warning,
            count: permissionsCount,
            isSelected: selectedFilter == _RequestTypeFilter.permissions,
            onTap: () => onChanged(_RequestTypeFilter.permissions),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'مأموريات',
            icon: Icons.flight_takeoff_rounded,
            color: AppColors.info,
            count: missionsCount,
            isSelected: selectedFilter == _RequestTypeFilter.missions,
            onTap: () => onChanged(_RequestTypeFilter.missions),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
