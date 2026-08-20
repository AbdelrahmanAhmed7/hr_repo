import 'package:flutter/material.dart';
import 'package:mediconsult_internal/src/features/permissions/permission_details_screen.dart';
import 'dart:async';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import '../requests/widgets/create_permission_bottom_sheet.dart';
import '../requests/services/requests_refresh_service.dart';
import 'models/permission_request.dart';
import 'repository/permission_repository.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  List<PermissionRequest> _permissions = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<void>? _refreshSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _refreshSubscription = getIt<RequestsRefreshService>().stream.listen((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = getIt<PermissionRepository>();
      final data = await repo.getMyPermissions();
      data.sort((a, b) => b.submittedDate.compareTo(a.submittedDate));
      if (!mounted) return;
      setState(() {
        _permissions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppException.from(e).message;
        _isLoading = false;
      });
    }
  }

  List<PermissionRequest> _filter(PermissionStatus? status) {
    if (status == null) return _permissions;
    return _permissions.where((p) => p.status == status).toList();
  }

  int get _pendingCount =>
      _permissions.where((p) => p.status == PermissionStatus.pending).length;
  int get _approvedCount =>
      _permissions.where((p) => p.status == PermissionStatus.approved).length;
  int get _rejectedCount =>
      _permissions.where((p) => p.status == PermissionStatus.rejected).length;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'permissions_fab',
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const CreateExitPermissionBottomSheet(),
          );
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إذن جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPersistentHeader(
              pinned: true,
              delegate: StatusTabsSliverDelegate(
                StatusTabsBar(
                  controller: _tabController,
                  pendingLabel: 'معلقة',
                ),
              ),
            ),
          ],
          body: _isLoading
              ? const ListShimmerLoading()
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_filter(null)),
                    _buildList(_filter(PermissionStatus.pending)),
                    _buildList(_filter(PermissionStatus.approved)),
                    _buildList(_filter(PermissionStatus.rejected)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الإذونات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'إجمالي ${_permissions.length} إذن',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatChip(
                    label: 'معلقة',
                    count: _pendingCount,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'مقبولة',
                    count: _approvedCount,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'مرفوضة',
                    count: _rejectedCount,
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<PermissionRequest> items) {
    if (items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.access_time_outlined,
        title: 'لا توجد إذونات',
        message: 'ستظهر طلبات الإذن هنا بمجرد إضافتها.',
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
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _PermissionCard(
        permission: items[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PermissionDetailsScreen(permission: items[index]),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label $count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final PermissionRequest permission;
  final VoidCallback? onTap;

  const _PermissionCard({required this.permission, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.output_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إذن خروج',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          permission.dateText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: permission.status),
                  _PermissionQuickRemindIcon(permission: permission),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              // Time range
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'الوقت',
                value: permission.timeRangeText,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'المدة',
                value: permission.durationText,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.description_outlined,
                label: 'السبب',
                value: permission.reason,
              ),
              if (permission.rejectionReason != null &&
                  permission.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سبب الرفض: ${permission.rejectionReason}',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  final PermissionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case PermissionStatus.pending:
        color = AppColors.warning;
        label = 'معلقة';
        break;
      case PermissionStatus.approved:
        color = AppColors.success;
        label = 'مقبولة';
        break;
      case PermissionStatus.rejected:
        color = AppColors.error;
        label = 'مرفوضة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PermissionQuickRemindIcon extends StatefulWidget {
  final PermissionRequest permission;

  const _PermissionQuickRemindIcon({required this.permission});

  @override
  State<_PermissionQuickRemindIcon> createState() =>
      _PermissionQuickRemindIconState();
}

class _PermissionQuickRemindIconState
    extends State<_PermissionQuickRemindIcon> {
  bool _isLoading = false;

  bool get _canRemind => widget.permission.status == PermissionStatus.pending;

  Future<void> _handleRemind() async {
    if (_isLoading || !_canRemind) return;

    final id = int.tryParse(widget.permission.id);
    if (id == null) {
      CustomToast.showError('تعذر إرسال التذكير: رقم الطلب غير صحيح');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = (await getIt<PermissionRepository>().remindPermission(
        id: id,
      )).message;

      if (!mounted) return;
      CustomToast.showSuccess(
        message.isNotEmpty ? message : 'تم إرسال التذكير بنجاح',
      );
    } catch (_) {
      if (!mounted) return;
      CustomToast.showError('تعذر إرسال التذكير الآن. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRemind) return const SizedBox.shrink();

    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        tooltip: 'تذكير',
        onPressed: _isLoading ? null : _handleRemind,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: AppColors.warning.withValues(alpha: 0.95),
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
