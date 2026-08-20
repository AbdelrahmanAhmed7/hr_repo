import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/punch_cubit.dart';
import '../cubit/punch_state.dart';
import 'punch_summary_employee_card.dart';

class PunchSummaryList extends StatelessWidget {
  const PunchSummaryList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (context, state) {
        final items = state.filteredSummaryItems;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent * 0.8) {
              context.read<PunchCubit>().loadMoreSummary();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: items.length + (state.isLoadingMoreSummary ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return PunchSummaryEmployeeCard(item: items[index]);
            },
          ),
        );
      },
    );
  }
}
