import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/service_locator.dart';
import '../cubit/punch_cubit.dart';
import '../cubit/punch_state.dart';
import '../widgets/punch_pairs_list.dart';

/// Standalone screen kept for potential future use.
/// The main entry point is now the expandable card inside PunchSummaryList.
class PunchPairsScreen extends StatefulWidget {
  final String userId;
  final String employeeName;

  const PunchPairsScreen({
    super.key,
    required this.userId,
    required this.employeeName,
  });

  @override
  State<PunchPairsScreen> createState() => _PunchPairsScreenState();
}

class _PunchPairsScreenState extends State<PunchPairsScreen> {
  late final PunchCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PunchCubit>();
    // Preload pairs for this user
    if (!_cubit.state.pairsCache.containsKey(widget.userId)) {
      _cubit.toggleExpand(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PunchCubit, PunchState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final isLoading = state.pairsLoadingUserId == widget.userId;
          final pairs = state.pairsCache[widget.userId];

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.employeeName,
                  overflow: TextOverflow.ellipsis),
            ),
            body: Builder(
              builder: (ctx) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (pairs == null || pairs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 48, color: theme.hintColor),
                        const SizedBox(height: 12),
                        Text(
                          'لا يوجد بيانات لهذا الموظف',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: PunchPairsList(userId: widget.userId),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
