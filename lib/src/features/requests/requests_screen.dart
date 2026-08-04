import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../auth/cubit/auth_cubit.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/components/custom_toast.dart';
import '../home/models/home_api_response.dart';
import '../home/models/recent_activity.dart';
import '../home/widgets/recent_activity_card.dart';
import 'repository/requests_repository.dart';
import 'services/requests_refresh_service.dart';
import 'widgets/create_permission_bottom_sheet.dart';
import 'widgets/requests_header.dart';

class RequestsScreen extends StatefulWidget {
  final int initialTab;

  const RequestsScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with AutomaticKeepAliveClientMixin {
  List<RecentActivity> _allRequests = [];
  bool _isLoading = false;
  int? _selectedMonth;
  int _selectedFilterIndex = 0;
  StreamSubscription<void>? _refreshSubscription;

  static const _tabs = [
    _Tab(label: 'الكل', emptyLabel: 'لا توجد طلبات بعد'),
    _Tab(label: 'معلقة', emptyLabel: 'لا توجد طلبات معلقة'),
    _Tab(label: 'مقبولة', emptyLabel: 'لا توجد طلبات مقبولة'),
    _Tab(label: 'مرفوضة', emptyLabel: 'لا توجد طلبات مرفوضة'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialTab.clamp(0, 3);
    _refreshSubscription = getIt<RequestsRefreshService>().stream.listen((_) {
      if (mounted) _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final repository = getIt<RequestsRepository>();

      // Get data from all endpoints
      final results = await Future.wait([
        repository.getMyLeaves(),
        repository.getMyPermissions(),
        repository.getMyAssignments(),
        repository.getMyOvertime(),
      ], eagerError: false);

      // Convert to RecentActivity with proper types
      final List<RecentActivity> all = [];

      // Leaves - type: leave
      for (final item in results[0]) {
        all.add(_convertToActivity(item, 'leave'));
      }

      // Permissions - type: permission
      for (final item in results[1]) {
        all.add(_convertToActivity(item, 'permission'));
      }

      // Assignments - type: assignment
      for (final item in results[2]) {
        all.add(_convertToActivity(item, 'assignment'));
      }

      // Overtime - type: overtime
      for (final item in results[3]) {
        all.add(_convertToActivity(item, 'overtime'));
      }

      // Sort by date descending
      all.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _allRequests = all;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading requests: $e');
      CustomToast.showError('تعذر تحميل طلباتك. حاول مرة أخرى.');
    }
  }

  RecentActivity _convertToActivity(HomeRequestItem item, String type) {
    // Determine title based on type
    String title;
    switch (type) {
      case 'leave':
        title = 'إجازة';
        break;
      case 'permission':
        title = 'إذن خروج';
        break;
      case 'assignment':
        title = 'مهمة';
        break;
      case 'overtime':
        title = 'عمل إضافي';
        break;
      default:
        title = 'طلب';
    }

    // Parse status
    RequestStatus status;
    final statusStr = item.status.toLowerCase();
    switch (statusStr) {
      case 'approved':
      case 'accepted':
        status = RequestStatus.approved;
        break;
      case 'rejected':
        status = RequestStatus.rejected;
        break;
      default:
        status = RequestStatus.pending;
    }

    // Parse date
    DateTime date = DateTime.now();
    final dateStr = item.createdAt.isNotEmpty ? item.createdAt : (item.startDate ?? '');
    if (dateStr.isNotEmpty) {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) date = parsed;
    }

    // Build description
    String? description;
    final startDate = item.startDate ?? '';
    final endDate = item.endDate ?? '';
    if (type == 'leave' && startDate.isNotEmpty && endDate.isNotEmpty) {
      description = 'من $startDate إلى $endDate';
    } else if (type == 'permission' && item.startTime != null && item.endTime != null) {
      description = 'من ${item.startTime} إلى ${item.endTime}';
    } else if (type == 'assignment' && item.where != null) {
      description = item.where;
    }

    return RecentActivity(
      id: item.id.toString(),
      type: _parseRequestType(type),
      status: status,
      title: title,
      date: date,
      description: description ?? item.reason,
      reason: item.reason,
      startDate: _parseDate(item.startDate ?? ''),
      endDate: _parseDate(item.endDate ?? ''),
      startTime: item.startTime,
      endTime: item.endTime,
      location: item.where,
      leaveType: item.leaveType,
      rejectionReason: item.rejectionReason,
    );
  }

  RequestType _parseRequestType(String type) {
    switch (type) {
      case 'leave':
        return RequestType.leave;
      case 'permission':
        return RequestType.permission;
      case 'overtime':
        return RequestType.overtime;
      default:
        return RequestType.other;
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<RecentActivity> get _currentList {
    switch (_selectedFilterIndex) {
      case 1:
        return _allRequests.where((r) => r.status == RequestStatus.pending).toList();
      case 2:
        return _allRequests.where((r) => r.status == RequestStatus.approved).toList();
      case 3:
        return _allRequests.where((r) => r.status == RequestStatus.rejected).toList();
      default:
        return _allRequests;
    }
  }

  int get _pendingCount => _allRequests.where((r) => r.status == RequestStatus.pending).length;
  int get _approvedCount => _allRequests.where((r) => r.status == RequestStatus.approved).length;
  int get _rejectedCount => _allRequests.where((r) => r.status == RequestStatus.rejected).length;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = context.watch<AuthCubit>().state;
    final canOpenAllRequests = authState.isHR || authState.isAdmin || authState.isSuperAdmin;

    final currentList = _currentList;
    final currentTab = _tabs[_selectedFilterIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: RequestsHeader(
                  title: 'طلباتي',
                  subtitle: 'إجازاتك، أذوناتك، مأمورياتك، وعملك الإضافي',
                  countLabel: 'إجمالي الطلبات',
                  requestCount: _allRequests.length,
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (value) {
                    if (_selectedMonth == value) return;
                    setState(() => _selectedMonth = value);
                    _loadData();
                  },
                  icon: Icons.inventory_2_rounded,
                  accentColor: AppColors.primaryLight,
                  actionLabel: canOpenAllRequests ? 'كل طلبات الموظفين' : null,
                  onActionPressed: canOpenAllRequests
                      ? () => context.push('/all-requests')
                      : null,
                ),
              ),
              if (canOpenAllRequests)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/all-requests'),
                        icon: const Icon(Icons.groups_rounded),
                        label: const Text('عرض كل طلبات الموظفين'),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ActivityOverview(
                        totalCount: _allRequests.length,
                        pendingCount: _pendingCount,
                        acceptedCount: _approvedCount,
                        rejectedCount: _rejectedCount,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final isSelected = _selectedFilterIndex == index;
                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: index == _tabs.length - 1 ? 0 : 8,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  _tabs[index].label,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
                                    setState(() => _selectedFilterIndex = index);
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (_isLoading && _allRequests.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (currentList.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(currentTab.emptyLabel),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    0,
                    14,
                    16 + MediaQuery.of(context).padding.bottom + 72,
                  ),
                  sliver: SliverList.separated(
                    itemCount: currentList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return RecentActivityCard(activity: currentList[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'requests_fab',
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateExitPermissionBottomSheet(),
          );
          if (result == true) await _loadData();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إذن جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
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
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final String emptyLabel;

  const _Tab({required this.label, required this.emptyLabel});
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
        _ActivityCountPill(label: 'الكل', value: '$totalCount', color: AppColors.primary),
        _ActivityCountPill(label: 'معلقة', value: '$pendingCount', color: const Color(0xFFD97706)),
        _ActivityCountPill(label: 'مقبولة', value: '$acceptedCount', color: const Color(0xFF0F7D3E)),
        _ActivityCountPill(label: 'مرفوضة', value: '$rejectedCount', color: const Color(0xFFC41E3A)),
      ],
    );
  }
}

class _ActivityCountPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ActivityCountPill({required this.label, required this.value, required this.color});

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
        style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
