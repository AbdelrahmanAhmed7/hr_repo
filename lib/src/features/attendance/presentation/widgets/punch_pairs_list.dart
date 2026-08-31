import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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

  List<Widget> _buildDateBanners(List<PunchPairModel> items) {
    final allPermissions = <PunchPairPermission>[];
    final allAssignments = <PunchPairAssignment>[];
    for (final p in items) {
      allPermissions.addAll(p.permissions);
      allAssignments.addAll(p.assignments);
    }
    final widgets = <Widget>[];
    if (allPermissions.isNotEmpty) {
      widgets.addAll([
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: BigRequestBanner(
            icon: Icons.logout_rounded,
            color: AppColors.warning,
            label: 'أذن',
            reason: allPermissions.first.reason,
            time: allPermissions.first.displayTime,
            count: allPermissions.length,
          ),
        ),
      ]);
    }
    if (allAssignments.isNotEmpty) {
      widgets.addAll([
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: BigRequestBanner(
            icon: Icons.flight_takeoff_rounded,
            color: AppColors.info,
            label: 'مأمورية',
            reason: allAssignments.first.reason,
            time: allAssignments.first.displayTime,
            count: allAssignments.length,
          ),
        ),
      ]);
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PunchCubit, PunchState>(
      builder: (context, state) {
        final pairs = state.pairsCache[userId] ?? [];
        final grouped = _groupByDate(pairs);
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

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
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dateHeader,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ...items.map((item) => PunchPairItem(item: item)),
                // ── One banner per date for permissions ────────────
                ..._buildDateBanners(items),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }
}
