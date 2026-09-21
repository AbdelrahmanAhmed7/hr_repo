import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/service_locator.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../data/models/winner_model.dart';
import '../../domain/repositories/employee_of_month_repository.dart';

/// Celebration banner shown on the home screen when the signed-in user is the
/// Employee of the Month winner (current or previous award period).
///
/// Renders nothing when the user is not a winner, or when the winners lookup
/// fails/loads — the banner must never disturb the home layout for everyone
/// else.
class HomeWinnerBanner extends StatefulWidget {
  const HomeWinnerBanner({super.key});

  @override
  State<HomeWinnerBanner> createState() => _HomeWinnerBannerState();
}

class _HomeWinnerBannerState extends State<HomeWinnerBanner> {
  final EmployeeOfMonthRepository _repository =
      getIt<EmployeeOfMonthRepository>();

  WinnerModel? _myWin;

  @override
  void initState() {
    super.initState();
    _checkWin();
  }

  Future<void> _checkWin() async {
    final userId = getIt<AuthCubit>().state.userId;
    if (userId == null || userId.isEmpty) return;

    final now = DateTime.now();
    final prevMonth = now.month == 1
        ? (month: 12, year: now.year - 1)
        : (month: now.month - 1, year: now.year);

    WinnerModel? won;
    for (final period in [
      (month: now.month, year: now.year),
      (month: prevMonth.month, year: prevMonth.year),
    ]) {
      try {
        final winners =
            await _repository.getWinners(month: period.month, year: period.year);
        for (final w in winners) {
          if (w.userId == userId) {
            won = w;
            break;
          }
        }
      } catch (_) {
        // Silent: a lookup failure must never block or break the home screen.
      }
      if (won != null) break;
    }

    if (!mounted) return;
    setState(() => _myWin = won);
  }

  @override
  Widget build(BuildContext context) {
    final win = _myWin;
    if (win == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/employee-of-month/winner', extra: win),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'مبروك 🎉 فزت بجايزة موظف الشهر',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}