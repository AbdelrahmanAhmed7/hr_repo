import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/custom_toast.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../data/models/meeting_model.dart';
import '../cubit/meetings_cubit.dart';
import '../cubit/meetings_state.dart';
import '../widgets/meeting_card.dart';
import '../widgets/meeting_form_sheet.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  Future<void> _openForm(BuildContext context, {MeetingModel? meeting}) async {
    final cubit = context.read<MeetingsCubit>();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: MeetingFormSheet(cubit: cubit, meeting: meeting),
      ),
    );

    if (created == true && context.mounted) {
      CustomToast.showSuccess(
        meeting == null
            ? 'تم إنشاء الاجتماع بنجاح'
            : 'تم تعديل الاجتماع بنجاح',
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, MeetingModel meeting) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الاجتماع'),
        content: Text('هل أنت متأكد من حذف "${meeting.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (deleted != true || !context.mounted) return;

    final ok = await context.read<MeetingsCubit>().deleteMeeting(meeting.id);
    if (!context.mounted) return;
    if (ok) {
      CustomToast.showSuccess('تم حذف الاجتماع بنجاح');
    } else {
      CustomToast.showError('فشل حذف الاجتماع');
    }
  }

  Widget _buildBody(BuildContext context, MeetingsState state) {
    if (state.loadStatus == MeetingsLoadStatus.loading &&
        state.meetings.isEmpty) {
      return const _MeetingListShimmer();
    }

    if (state.loadStatus == MeetingsLoadStatus.failure &&
        state.meetings.isEmpty) {
      return ErrorStateWidget(
        error: state.errorMessage ?? 'حدث خطأ ما',
        title: 'تعذر تحميل الاجتماعات',
        buttonLabel: 'إعادة المحاولة',
        onRetry: () =>
            context.read<MeetingsCubit>().loadMeetings(refresh: true),
      );
    }

    if (state.meetings.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.groups_outlined,
        title: 'لا توجد اجتماعات',
        message: 'اضغط على زر "اجتماع جديد" لإنشاء أول اجتماع',
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
          context.read<MeetingsCubit>().loadMoreMeetings();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () =>
            context.read<MeetingsCubit>().loadMeetings(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.separated(
                itemCount: state.meetings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meeting = state.meetings[index];
                  return MeetingCard(
                    meeting: meeting,
                    onEdit: () => _openForm(context, meeting: meeting),
                    onDelete: () => _confirmDelete(context, meeting),
                  );
                },
              ),
            ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              )
            else if (state.currentPage > state.totalPages)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'لا مزيد من الاجتماعات',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetingsCubit, MeetingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          appBar: AppBar(
            title: const Text('الاجتماعات'),
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('اجتماع جديد'),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }
}

class _MeetingListShimmer extends StatelessWidget {
  const _MeetingListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const _MeetingSkeleton(),
    );
  }
}

class _MeetingSkeleton extends StatelessWidget {
  const _MeetingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 160,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _pill(80),
                const SizedBox(width: 8),
                _pill(60),
                const SizedBox(width: 8),
                _pill(90),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(double width) {
    return Container(
      width: width,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}