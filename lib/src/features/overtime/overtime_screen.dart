import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/skeleton/skeleton_list_item.dart';
import 'cubit/overtime_cubit.dart';
import 'cubit/overtime_state.dart';
import 'models/overtime_request.dart';
import 'widgets/create_overtime_bottom_sheet.dart';
import 'widgets/overtime_request_card.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OvertimeCubit>().loadData();
      }
    });
  }

  Future<void> _openCreateSheet() async {
    final cubit = context.read<OvertimeCubit>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const CreateOvertimeBottomSheet(),
      ),
    );

    if (!mounted || result != true) return;
      CustomToast.showSuccess('تم إرسال طلب العمل الإضافي بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('طلب جديد'),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<OvertimeCubit, OvertimeState>(
          builder: (context, state) {
            final filteredRequests = state.filteredRequests;
            final pendingCount = state.requests
                .where((item) => item.status == OvertimeRequestStatus.pending)
                .length;
            final approvedCount = state.requests
                .where((item) => item.status == OvertimeRequestStatus.approved)
                .length;
            final rejectedCount = state.requests
                .where((item) => item.status == OvertimeRequestStatus.rejected)
                .length;

            return RefreshIndicator(
              onRefresh: context.read<OvertimeCubit>().refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: [
                          _OvertimeHeroCard(
                            totalCount: state.requests.length,
                            pendingCount: pendingCount,
                            onCreatePressed: _openCreateSheet,
                          ),
                          const SizedBox(height: 14),
                          _OvertimeStatusFilterBar(
                            selectedFilter: state.selectedFilter,
                            allCount: state.requests.length,
                            pendingCount: pendingCount,
                            approvedCount: approvedCount,
                            rejectedCount: rejectedCount,
                            onChanged: context.read<OvertimeCubit>().setFilter,
                          ),
                          if (state.loadStatus == OvertimeLoadStatus.failure &&
                              state.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (state.loadStatus == OvertimeLoadStatus.loading)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        100 + MediaQuery.of(context).padding.bottom,
                      ),
                      sliver: SliverList.separated(
                        itemCount: 4,
                        itemBuilder: (_, _) =>
                            const SkeletonListItem(showAvatar: false),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                      ),
                    )
                  else if (filteredRequests.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        child: EmptyStateWidget(
                          icon: Icons.schedule_send_outlined,
                          title: state.selectedFilter == 'all'
                              ? 'لا توجد طلبات عمل إضافي'
                              : 'لا توجد طلبات في هذا القسم',
                          message: state.selectedFilter == 'all'
                              ? 'ابدأ بطلب جديد وحدد اليوم والوقت والسبب بشكل واضح.'
                              : 'جرّب تغيير الحالة أو أنشئ طلبًا جديدًا إذا كنت تحتاج عملًا إضافيًا.',
                          buttonLabel: 'إنشاء طلب',
                          onButtonPressed: _openCreateSheet,
                          iconColor: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        100 + MediaQuery.of(context).padding.bottom,
                      ),
                      sliver: SliverList.separated(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) => OvertimeRequestCard(
                          request: filteredRequests[index],
                        ),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OvertimeHeroCard extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final VoidCallback onCreatePressed;

  const _OvertimeHeroCard({
    required this.totalCount,
    required this.pendingCount,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102349),
            Color(0xFF1F4E98),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلبات العمل الإضافي',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'قدّم الطلب بسرعة وتابع حالته من نفس الشاشة بدون تعقيد.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: 'إجمالي $totalCount'),
              _HeroPill(label: 'معلق $pendingCount'),
              _HeroPill(label: 'تقديم سريع'),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: onCreatePressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إنشاء طلب إضافي'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OvertimeStatusFilterBar extends StatelessWidget {
  final String selectedFilter;
  final int allCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final ValueChanged<String> onChanged;

  const _OvertimeStatusFilterBar({
    required this.selectedFilter,
    required this.allCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusChip(
            label: 'الكل',
            count: allCount,
            isSelected: selectedFilter == 'all',
            onTap: () => onChanged('all'),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'معلقة',
            count: pendingCount,
            isSelected: selectedFilter == 'pending',
            onTap: () => onChanged('pending'),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'مقبولة',
            count: approvedCount,
            isSelected: selectedFilter == 'approved',
            onTap: () => onChanged('approved'),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'مرفوضة',
            count: rejectedCount,
            isSelected: selectedFilter == 'rejected',
            onTap: () => onChanged('rejected'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
