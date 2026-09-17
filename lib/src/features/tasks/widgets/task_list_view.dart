import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../models/task.dart';
import '../utils/task_labels.dart';
import 'task_card.dart';
import 'task_chips.dart';

/// Reusable tasks list with status filter row, pull-to-refresh, infinite
/// scroll and loading/error/empty states. Shared by the "my tasks" and
/// "all tasks" views (the parent only wires data + callbacks).
class TaskListView extends StatefulWidget {
  final List<TaskModel> items;
  final bool initialLoading;
  final bool initialFailed;
  final String errorTitle;
  final String errorMessage;
  final VoidCallback onRetry;
  final int? selectedStatus;
  final ValueChanged<int?> onStatusChanged;
  final bool loadingMore;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget emptyWidget;

  const TaskListView({
    super.key,
    required this.items,
    required this.initialLoading,
    required this.initialFailed,
    required this.errorTitle,
    required this.errorMessage,
    required this.onRetry,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.loadingMore,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.emptyWidget,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialLoading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.initialFailed && widget.items.isEmpty) {
      return ErrorStateWidget(
        title: widget.errorTitle,
        error: widget.errorMessage,
        buttonLabel: 'إعادة المحاولة',
        onRetry: widget.onRetry,
        icon: Icons.task_outlined,
      );
    }
    return Column(
      children: [
        Container(
          color: AppColors.backgroundSecondary,
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                TaskFilterChip(
                  label: 'الكل',
                  selected: widget.selectedStatus == null,
                  onTap: () => widget.onStatusChanged(null),
                ),
                for (var s = 0; s <= 6; s++)
                  TaskFilterChip(
                    label: TaskLabels.statusText(s),
                    selected: widget.selectedStatus == s,
                    color: TaskLabels.statusColor(s),
                    onTap: () => widget.onStatusChanged(s),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: widget.items.isEmpty
              ? widget.emptyWidget
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      16 + MediaQuery.of(context).padding.bottom + 80,
                    ),
                    itemCount: widget.items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      if (i >= widget.items.length) {
                        return _BottomLoader(
                          loading: widget.loadingMore,
                          hasMore: widget.hasMore,
                        );
                      }
                      return TaskCard(task: widget.items[i]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _BottomLoader extends StatelessWidget {
  final bool loading;
  final bool hasMore;
  const _BottomLoader({required this.loading, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'لا توجد صفحات أخرى',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}
