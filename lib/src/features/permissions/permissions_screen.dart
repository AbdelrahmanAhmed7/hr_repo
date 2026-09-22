import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'الإذونات',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
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
            SliverPersistentHeader(
              pinned: true,
              delegate: StatusTabsSliverDelegate(
                StatusTabsBar(
                  controller: _tabController,
                  pendingLabel: 'معلقة',
                  style: StatusTabsStyle.segmented,
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
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final PermissionRequest permission;

  const _PermissionCard({required this.permission});

  @override
  Widget build(BuildContext context) {
    final statusColor = permission.statusColor;

    return Container(
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    permission.icon,
                    color: statusColor,
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
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                const SizedBox(width: 10),
                _StatusBadge(status: permission.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: permission.timeRangeText,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: permission.durationText,
                ),
                const Spacer(),
                _PermissionQuickRemindIcon(permission: permission),
              ],
            ),
            if (permission.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _QuoteBlock(
                title: 'السبب',
                body: permission.reason,
                color: AppColors.primary,
              ),
            ],
            if (permission.rejectionReason != null &&
                permission.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _QuoteBlock(
                title: 'ملاحظة الإدارة',
                body: permission.rejectionReason!,
                color: AppColors.error,
                isError: true,
              ),
            ],
          ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleRemind,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.notifications_active_outlined,
                    size: 17,
                    color: AppColors.warning,
                  ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final bool isError;

  const _QuoteBlock({
    required this.title,
    required this.body,
    required this.color,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? color.withValues(alpha: 0.05)
            : AppColors.backgroundSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: isError ? color : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: isError ? color : AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
