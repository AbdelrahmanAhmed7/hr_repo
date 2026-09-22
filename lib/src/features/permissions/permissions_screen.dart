import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import '../home/models/recent_activity.dart';
import '../requests/services/requests_refresh_service.dart';
import '../requests/widgets/create_permission_bottom_sheet.dart';
import '../requests/widgets/unified_request_card.dart';
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
        title: Text('الإذونات', style: Theme.of(context).textTheme.titleLarge),
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
                    _buildList(
                      _filter(null),
                      emptyTitle: 'لا توجد إذونات',
                      emptyMessage: 'ستظهر طلبات الإذن هنا بمجرد إضافتها.',
                    ),
                    _buildList(
                      _filter(PermissionStatus.pending),
                      emptyTitle: 'ليس لديك أذونات معلقة',
                      emptyMessage: 'مفيش أذونات مستنية القرار دلوقتي.',
                    ),
                    _buildList(
                      _filter(PermissionStatus.approved),
                      emptyTitle: 'ليس لديك أذونات مقبولة',
                      emptyMessage: 'لسه مفيش أذونات اتقبلت.',
                    ),
                    _buildList(
                      _filter(PermissionStatus.rejected),
                      emptyTitle: 'ليس لديك أذونات مرفوضة',
                      emptyMessage: 'مفيش أذونات مرفوضة — اي خدمه.',
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<PermissionRequest> items, {
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.access_time_outlined,
        title: emptyTitle,
        message: emptyMessage,
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
      itemBuilder: (_, index) => UnifiedRequestCard(
        request: RecentActivity.fromPermissionRequest(items[index]),
      ),
    );
  }
}
