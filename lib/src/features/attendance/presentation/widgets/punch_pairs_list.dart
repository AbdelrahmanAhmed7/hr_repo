import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/punch_pair_model.dart';
import '../cubit/punch_cubit.dart';
import '../cubit/punch_state.dart';
import 'punch_pair_item.dart';

/// Used standalone only (e.g. from a direct route). Displays pairs from the
/// inline pairsCache for the given userId already loaded in the cubit.
class PunchPairsList extends StatelessWidget {
  final String userId;

  const PunchPairsList({super.key, required this.userId});

  Map<String, List<PunchPairModel>> _groupByDate(
      List<PunchPairModel> items) {
    final map = <String, List<PunchPairModel>>{};
    for (final item in items) {
      map.putIfAbsent(item.date, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (context, state) {
        final pairs = state.pairsCache[userId] ?? [];
        final grouped = _groupByDate(pairs);
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        final theme = Theme.of(context);
        final surface2 = theme.colorScheme.surfaceContainerHighest;
        final textSecondary =
            theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                Colors.grey;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dateStr = sortedKeys[index];
            final items = grouped[dateStr]!;

            String dateHeader = dateStr;
            try {
              final d = DateTime.parse(dateStr);
              dateHeader = DateFormat('EEEE، d MMMM yyyy', 'ar').format(d);
            } catch (_) {}

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: surface2,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: Text(
                    dateHeader,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ...items.map((item) => PunchPairItem(item: item)),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }
}
