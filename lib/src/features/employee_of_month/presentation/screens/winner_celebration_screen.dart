import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../cubit/employee_of_month_cubit.dart';
import '../cubit/employee_of_month_state.dart';
import '../employee_of_month_helpers.dart';
import '../../data/models/winner_model.dart';

/// Full-screen celebration shown to the Employee of the Month winner.
///
/// Accepts the [WinnerModel] directly (passed from the home banner). When
/// opened without one (e.g. deep link), it resolves the current user's win
/// through [EmployeeOfMonthCubit] and falls back to a neutral state.
class WinnerCelebrationScreen extends StatefulWidget {
  final WinnerModel? winner;

  const WinnerCelebrationScreen({super.key, this.winner});

  @override
  State<WinnerCelebrationScreen> createState() =>
      _WinnerCelebrationScreenState();
}

class _WinnerCelebrationScreenState extends State<WinnerCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    final rng = math.Random(20240729);
    for (var i = 0; i < 38; i++) {
      _particles.add(_ConfettiParticle.random(rng));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _shareResult(WinnerModel winner) async {
    final message =
        '🏆 فزت بجايزة موظف الشهر (${employeeOfMonthMonthName(winner.month)} ${winner.year})!\n'
        '${winner.fullNameAr} — ${winner.departmentName}';
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ النتيجة، شاركها مع زميلك 🎉'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.winner;
    if (winner != null) {
      return _frame(
        _CelebrationContent(winner: winner, onShare: () => _shareResult(winner)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B3D),
      body: BlocBuilder<EmployeeOfMonthCubit, EmployeeOfMonthState>(
        builder: (context, state) {
          if (state.status != EmployeeOfMonthStatus.success) {
            return const _CenteredLoader();
          }
          final userId = getIt<AuthCubit>().state.userId;
          for (final w in state.winners) {
            if (w.userId == userId) {
              return _frame(
                _CelebrationContent(
                  winner: w,
                  onShare: () => _shareResult(w),
                ),
              );
            }
          }
          return _frame(const _NoWinState());
        },
      ),
    );
  }

  Widget _frame(Widget body) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B3D),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F1B3D), Color(0xFF1E3A8A)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) => CustomPaint(
              painter: _ConfettiPainter(
                progress: _confettiController.value,
                particles: _particles,
              ),
            ),
          ),
          body,
        ],
      ),
    );
  }
}

// ─── Celebration Content ───────────────────────────────────────────────────────

class _CelebrationContent extends StatelessWidget {
  final WinnerModel winner;
  final VoidCallback onShare;
  const _CelebrationContent({required this.winner, required this.onShare});

  String get _initial {
    final trimmed = winner.fullNameAr.trim();
    return trimmed.isNotEmpty ? trimmed[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _Reveal(
              delay: Duration(milliseconds: 400),
              child: const _Trophy(),
            ),
            const SizedBox(height: 14),
            _Reveal(
              delay: const Duration(milliseconds: 550),
              child: Text(
                'مبروك 🎉',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _Reveal(
              delay: const Duration(milliseconds: 700),
              child: Text(
                'فزت بجايزة موظف الشهر',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Reveal(
              delay: const Duration(milliseconds: 850),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD34D).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFCD34D).withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '🥇 ${employeeOfMonthMonthName(winner.month)} ${winner.year}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFFFDE68A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Reveal(
              delay: const Duration(milliseconds: 1000),
              child: _WinnerDetailCard(winner: winner, initial: _initial),
            ),
            const Spacer(),
            _Reveal(
              delay: const Duration(milliseconds: 1150),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onShare,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: Text(
                        'شارك النتيجة',
                        style: AppTextStyles.buttonLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.push('/employee-of-month'),
                    child: Text(
                      'فتح صفحة التصويت',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: const Color(0xFFFDE68A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Trophy ───────────────────────────────────────────────────────────────────

class _Trophy extends StatelessWidget {
  const _Trophy();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
            blurRadius: 30,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        color: Colors.white,
        size: 58,
      ),
    );
  }
}

// ─── Winner Detail Card ───────────────────────────────────────────────────────

class _WinnerDetailCard extends StatelessWidget {
  final WinnerModel winner;
  final String initial;

  const _WinnerDetailCard({required this.winner, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CachedAvatarWidget(
            imageUrl: winner.imageUrl,
            initials: initial,
            size: 64,
            backgroundColor: AppColors.primaryTint,
            textColor: AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  winner.fullNameAr,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  winner.departmentName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.how_to_vote_rounded,
                  color: Color(0xFFB45309),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${winner.voteCount} صوت',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section reveal wrapper (delayed fade + slide) ────────────────────────────

class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _Reveal({required this.child, this.delay = Duration.zero});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _shown = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.2),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ─── Centered loader ──────────────────────────────────────────────────────────

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFFCD34D)),
    );
  }
}

// ─── Neutral state when the user is not a winner ──────────────────────────────

class _NoWinState extends StatelessWidget {
  const _NoWinState();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: Color(0xFFFCD34D),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'لا يوجد فوز مسجل لك حالياً',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'شارك في التصويت، وشجّع زملاءك ✨',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFDE68A),
                  side: const BorderSide(color: Color(0xFFFCD34D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('عودة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Confetti ─────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double phase;
  final double speed;
  final double size;
  final Color color;
  final double sway;
  final double rotation;

  const _ConfettiParticle({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.color,
    required this.sway,
    required this.rotation,
  });

  factory _ConfettiParticle.random(math.Random rng) {
    const palette = [
      Color(0xFFFCD34D),
      Color(0xFFF59E0B),
      Color(0xFFFDE68A),
      Color(0xFFFB7185),
      Color(0xFFA5B4FC),
      Colors.white,
    ];
    return _ConfettiParticle(
      x: rng.nextDouble(),
      phase: rng.nextDouble(),
      speed: 0.18 + rng.nextDouble() * 0.4,
      size: 4 + rng.nextDouble() * 7,
      color: palette[rng.nextInt(palette.length)],
      sway: 0.03 + rng.nextDouble() * 0.05,
      rotation: rng.nextDouble() * math.pi,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  const _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final y = (p.phase + progress * p.speed) % 1.0;
      final x =
          p.x + math.sin((progress * 6.28 * 3) + p.phase * 12.56) * p.sway;
      final px = x * size.width;
      final py = y * size.height;
      // Fade particles near the top edge out (they re-enter there).
      final alpha = (1.0 - (p.phase + progress * p.speed)) * 0.9;
      if (alpha <= 0) continue;

      paint.color = p.color.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + progress * 6.28);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 1.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}