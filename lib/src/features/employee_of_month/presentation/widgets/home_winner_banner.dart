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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/employee-of-month/winner', extra: win),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مبروك 🎉 فزت بجايزة موظف الشهر',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          win.departmentName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFB45309),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFFB45309),
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