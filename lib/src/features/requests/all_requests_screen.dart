import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/network/dio_client.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_tabs_bar.dart';
import '../auth/cubit/auth_cubit.dart';
import '../home/models/recent_activity.dart';
import 'repository/requests_repository.dart';
import 'services/requests_refresh_service.dart';
import 'widgets/request_card.dart';
import 'widgets/requests_header.dart';

class AllRequestsScreen extends StatefulWidget {
  final int initialTab;

  const AllRequestsScreen({super.key, this.initialTab = 0});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

enum _RequestTypeFilter { all, leaves, permissions, missions, overtime }

class _AllRequestsScreenState extends State<AllRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RecentActivity> _allRequests = [];
  List<RecentActivity> _pendingRequests = [];
  List<RecentActivity> _approvedRequests = [];
  List<RecentActivity> _rejectedRequests = [];
  bool _isLoading = false;
  int? _selectedMonth;
  _RequestTypeFilter _selectedTypeFilter = _RequestTypeFilter.all;
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3).toInt(),
    );
    _tabController.addListener(_handleTabChanged);
    _refreshSubscription = getIt<RequestsRefreshService>().stream.listen((_) {
      if (mounted) {
        _loadData();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = getIt<AuthCubit>().state;
      final isManagementRole =
          authState.isHR || authState.isAdmin || authState.isSuperAdmin;

      List<RecentActivity> all;
      List<RecentActivity> pending;
      List<RecentActivity> approved;
      List<RecentActivity> rejected;

      if (isManagementRole) {
        all = await _loadManagementRequests();
        pending = all
            .where((item) => item.status == RequestStatus.pending)
            .toList();
        approved = all
            .where((item) => item.status == RequestStatus.approved)
            .toList();
        rejected = all
            .where((item) => item.status == RequestStatus.rejected)
            .toList();
      } else {
        final repository = getIt<RequestsRepository>();
        final results = await Future.wait([
          repository.getAllRequests(),
          repository.getPendingRequests(),
          repository.getAcceptedRequests(),
          repository.getRejectedRequests(),
        ]);

        List<RecentActivity> mapItems(List items) {
          final mapped = items
              .map((item) => RecentActivity.fromHomeRequestItem(item))
              .where(
                (activity) =>
                    _selectedMonth == null ||
                    activity.date.month == _selectedMonth,
              )
              .toList();
          mapped.sort((a, b) => b.date.compareTo(a.date));
          return mapped;
        }

        all = mapItems(results[0]);
        pending = mapItems(results[1]);
        approved = mapItems(results[2]);
        rejected = mapItems(results[3]);
      }

      if (!mounted) return;
      setState(() {
        _allRequests = all;
        _pendingRequests = pending;
        _approvedRequests = approved;
        _rejectedRequests = rejected;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CustomToast.showError('تعذر تحميل كل الطلبات. حاول مرة أخرى.');
      });
    }
  }

  Future<List<RecentActivity>> _loadManagementRequests() async {
    final dio = getIt<DioClient>().dio;

    Future<dynamic> safeGet(
      String path, {
      Map<String, dynamic>? queryParameters,
    }) async {
      try {
        return await dio.get(path, queryParameters: queryParameters);
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait<dynamic>([
      safeGet(
        '/api/Assignment/all',
        queryParameters: {'pageNumber': 1, 'pageSize': 500},
      ),
      safeGet('/api/Permission/all'),
      safeGet('/api/Overtime/all'),
      safeGet('/api/Leave/pending'),
    ]);

    final assignments = _extractItems(results[0]?.data)
        .map((item) => _mapManagementItem(item, fallbackType: 'assignment'))
        .whereType<RecentActivity>();
    final permissions = _extractItems(results[1]?.data)
        .map((item) => _mapManagementItem(item, fallbackType: 'permission'))
        .whereType<RecentActivity>();
    final overtimes = _extractItems(results[2]?.data)
        .map((item) => _mapManagementItem(item, fallbackType: 'overtime'))
        .whereType<RecentActivity>();
    final leaves = _extractItems(results[3]?.data)
        .map((item) => _mapManagementItem(item, fallbackType: 'leave'))
        .whereType<RecentActivity>();

    final merged = [...assignments, ...permissions, ...overtimes, ...leaves];

    final needsUserLookup = merged.any(
      (item) =>
          (item.userName == null || item.userName!.trim().isEmpty) &&
          item.userId != null &&
          item.userId!.trim().isNotEmpty,
    );

    final usersLookup = needsUserLookup
        ? await _loadUsersLookup(dio)
        : const <String, String>{};

    final all =
        merged
            .map((item) {
              final fallbackUserName = usersLookup[item.userId];
              return RecentActivity(
                id: item.id,
                type: item.type,
                status: item.status,
                title: item.title,
                date: item.date,
                description: item.description,
                userId: item.userId,
                userName: (item.userName?.trim().isNotEmpty ?? false)
                    ? item.userName
                    : fallbackUserName,
                remainingVacationBalance: item.remainingVacationBalance,
                reason: item.reason,
                startDate: item.startDate,
                endDate: item.endDate,
                startTime: item.startTime,
                endTime: item.endTime,
                location: item.location,
                leaveType: item.leaveType,
                rejectionReason: item.rejectionReason,
                totalHours: item.totalHours,
                amount: item.amount,
              );
            })
            .where(
              (item) =>
                  _selectedMonth == null || item.date.month == _selectedMonth,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return all;
  }

  Future<Map<String, String>> _loadUsersLookup(dynamic dio) async {
    final Map<String, String> usersById = {};
    int pageNumber = 1;
    int totalPages = 1;

    while (pageNumber <= totalPages) {
      try {
        final response = await dio.get(
          '/api/Auth/users',
          queryParameters: {'pageNumber': pageNumber, 'pageSize': 200},
        );

        final data = response.data;
        final items = _extractItems(data);

        for (final item in items) {
          final id = item['id']?.toString();
          final name = _extractUserName(item);
          if (id != null &&
              id.trim().isNotEmpty &&
              name != null &&
              name.isNotEmpty) {
            usersById[id] = name;
          }
        }

        if (data is Map<String, dynamic>) {
          final parsedTotalPages = int.tryParse(
            data['totalPages']?.toString() ?? '',
          );
          totalPages = parsedTotalPages != null && parsedTotalPages > 0
              ? parsedTotalPages
              : 1;
        } else {
          break;
        }

        if (items.isEmpty) break;
        pageNumber++;
      } catch (_) {
        break;
      }
    }

    return usersById;
  }

  String? _extractUserName(Map<String, dynamic> item) {
    final fullArabic = [
      item['firstNameAr']?.toString(),
      item['middleNameAr']?.toString(),
      item['lastNameAr']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();
    if (fullArabic.isNotEmpty) return fullArabic;

    final fullEnglish = [
      item['firstNameEn']?.toString(),
      item['middleNameEn']?.toString(),
      item['lastNameEn']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();
    if (fullEnglish.isNotEmpty) return fullEnglish;

    final employeeNameAr = item['employeeNameAr']?.toString();
    if (employeeNameAr != null && employeeNameAr.trim().isNotEmpty) {
      return employeeNameAr.trim();
    }

    final employeeNameEn = item['employeeNameEn']?.toString();
    if (employeeNameEn != null && employeeNameEn.trim().isNotEmpty) {
      return employeeNameEn.trim();
    }

    final email = item['email']?.toString();
    if (email != null && email.trim().isNotEmpty) return email.trim();

    return null;
  }

  List<Map<String, dynamic>> _extractItems(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      final items = payload['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return const [];
  }

  RecentActivity? _mapManagementItem(
    Map<String, dynamic> json, {
    required String fallbackType,
  }) {
    final typeRaw = (json['type']?.toString() ?? fallbackType).toLowerCase();
    final statusRaw = (json['status']?.toString() ?? 'pending').toLowerCase();

    final RequestType type = switch (typeRaw) {
      'leave' => RequestType.leave,
      'permission' => RequestType.permission,
      'overtime' => RequestType.overtime,
      'assignment' => RequestType.other,
      _ => RequestType.other,
    };

    final RequestStatus status;
    if (statusRaw == 'approved' || statusRaw == 'accepted') {
      status = RequestStatus.approved;
    } else if (statusRaw == 'rejected') {
      status = RequestStatus.rejected;
    } else {
      status = RequestStatus.pending;
    }

    DateTime date = DateTime.now();
    final dateCandidates = [
      json['date']?.toString(),
      json['startDate']?.toString(),
      json['createdAt']?.toString(),
    ];
    for (final value in dateCandidates) {
      if (value == null || value.trim().isEmpty) continue;
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        date = parsed;
        break;
      }
    }

    final descriptionParts = <String>[
      if ((json['where']?.toString().isNotEmpty ?? false))
        json['where'].toString(),
      if ((json['reason']?.toString().isNotEmpty ?? false))
        json['reason'].toString(),
      if ((json['startTime']?.toString().isNotEmpty ?? false) &&
          (json['endTime']?.toString().isNotEmpty ?? false))
        '${json['startTime']} - ${json['endTime']}',
      if (json['totalHours'] != null) 'عدد الساعات: ${json['totalHours']}',
      if (json['amount'] != null) 'القيمة: ${json['amount']}',
    ];

    final title = switch (type) {
      RequestType.leave => 'إجازة',
      RequestType.permission => 'إذن',
      RequestType.overtime => 'عمل إضافي',
      RequestType.other => typeRaw == 'assignment' ? 'مأمورية' : 'طلب',
    };

    return RecentActivity(
      id:
          json['id']?.toString() ??
          '${fallbackType}_${date.millisecondsSinceEpoch}',
      type: type,
      status: status,
      title: title,
      date: date,
      description: descriptionParts.isEmpty
          ? null
          : descriptionParts.join(' | '),
      userId: json['userId']?.toString(),
      userName:
          json['employeeNameAr']?.toString() ??
          json['employeeNameEn']?.toString(),
      reason: json['reason']?.toString(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      location: json['where']?.toString(),
      leaveType: json['leaveType']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      totalHours: _toDouble(json['totalHours']),
      amount: _toDouble(json['amount']),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
            .where((item) => item.type == RequestType.other)
            .toList();
      case _RequestTypeFilter.overtime:
        return requests
            .where((item) => item.type == RequestType.overtime)
            .toList();
    }
  }

  List<RecentActivity> get _activeRequests {
    switch (_tabController.index) {
      case 1:
        return _pendingRequests;
      case 2:
        return _approvedRequests;
      case 3:
        return _rejectedRequests;
      default:
        return _allRequests;
    }
  }

  String get _activeTabLabel {
    switch (_tabController.index) {
      case 1:
        return 'المعلقة';
      case 2:
        return 'المقبولة';
      case 3:
        return 'المرفوضة';
      default:
        return 'كل الحالات';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRequests = _activeRequests;
    final activeFilteredRequests = _applyTypeFilter(activeRequests);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: RequestsHeader(
                  title: 'كل الطلبات',
                  subtitle: 'الإجازات والأذونات والمأموريات في لوحة واحدة',
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RequestsInsightCard(
                        title: 'عرض $_activeTabLabel',
                        subtitle:
                            'تم العثور على ${activeFilteredRequests.length} طلب بعد تطبيق الفلاتر الحالية.',
                        totalCount: activeRequests.length,
                        filteredCount: activeFilteredRequests.length,
                      ),
                      const SizedBox(height: 12),
                      _RequestsTypeFilterBar(
                        selectedFilter: _selectedTypeFilter,
                        onChanged: (filter) {
                          setState(() => _selectedTypeFilter = filter);
                        },
                        allCount: activeRequests.length,
                        leavesCount: activeRequests
                            .where((item) => item.type == RequestType.leave)
                            .length,
                        permissionsCount: activeRequests
                            .where(
                              (item) => item.type == RequestType.permission,
                            )
                            .length,
                        missionsCount: activeRequests
                            .where((item) => item.type == RequestType.other)
                            .length,
                        overtimeCount: activeRequests
                            .where((item) => item.type == RequestType.overtime)
                            .length,
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(_allRequests),
              _buildRequestsList(_pendingRequests),
              _buildRequestsList(_approvedRequests),
              _buildRequestsList(_rejectedRequests),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<RecentActivity> requests) {
    final filteredRequests = _applyTypeFilter(requests);

    if (_isLoading && _allRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredRequests.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: requests.isEmpty
            ? 'لا توجد طلبات في هذا القسم'
            : 'لا توجد نتائج لهذه الفلترة',
        message: requests.isEmpty
            ? 'ستظهر الطلبات هنا بمجرد إنشائها أو تحديث حالتها.'
            : 'جرّب تغيير نوع الطلب أو اختيار تبويب حالة مختلف.',
        iconColor: AppColors.textTertiary,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          14,
          84,
          14,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: filteredRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return RequestCard(request: filteredRequests[index]);
        },
      ),
    );
  }
}

class _RequestsInsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int totalCount;
  final int filteredCount;

  const _RequestsInsightCard({
    required this.title,
    required this.subtitle,
    required this.totalCount,
    required this.filteredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$filteredCount / $totalCount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
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
  final int overtimeCount;

  const _RequestsTypeFilterBar({
    required this.selectedFilter,
    required this.onChanged,
    required this.allCount,
    required this.leavesCount,
    required this.permissionsCount,
    required this.missionsCount,
    required this.overtimeCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TypeChip(
            label: 'الكل',
            count: allCount,
            isSelected: selectedFilter == _RequestTypeFilter.all,
            onTap: () => onChanged(_RequestTypeFilter.all),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'إجازات',
            count: leavesCount,
            isSelected: selectedFilter == _RequestTypeFilter.leaves,
            onTap: () => onChanged(_RequestTypeFilter.leaves),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'أذونات',
            count: permissionsCount,
            isSelected: selectedFilter == _RequestTypeFilter.permissions,
            onTap: () => onChanged(_RequestTypeFilter.permissions),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'مأموريات',
            count: missionsCount,
            isSelected: selectedFilter == _RequestTypeFilter.missions,
            onTap: () => onChanged(_RequestTypeFilter.missions),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'أوفرتايم',
            count: overtimeCount,
            isSelected: selectedFilter == _RequestTypeFilter.overtime,
            onTap: () => onChanged(_RequestTypeFilter.overtime),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        '$label $count',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) => onTap(),
    );
  }
}
