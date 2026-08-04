import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/today_attendance.dart';

class CheckInOutSection extends StatelessWidget {
  final TodayAttendance todayAttendance;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final bool isLoading;

  const CheckInOutSection({
    super.key,
    required this.todayAttendance,
    this.onCheckIn,
    this.onCheckOut,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
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
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحضور والانصراف',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _sectionSubtitle(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionArea(),
            if (isLoading) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'جاري التحقق من الموقع وتنفيذ العملية...',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sectionSubtitle() {
    if (!todayAttendance.isCheckedIn) {
      return 'ابدأ يومك بتسجيل الحضور من هنا.';
    }
    if (!todayAttendance.isCheckedOut) {
      return 'تم تسجيل الدخول، والخطوة التالية هي تسجيل الانصراف.';
    }
    return 'اليوم مكتمل، ويمكنك مراجعة الملخص اليومي بالأسفل.';
  }

  Widget _buildActionArea() {
    if (!todayAttendance.isCheckedIn) {
      return _ActionSurface(
        title: 'ابدأ يومك الآن',
        subtitle: 'سجّل الحضور وسيتم حفظ وقت الدخول الحالي',
        buttonLabel: 'تسجيل الحضور',
        icon: Icons.login_rounded,
        colorA: AppColors.primary,
        colorB: AppColors.primaryDark,
        onTap: isLoading ? null : onCheckIn,
      );
    }

    if (!todayAttendance.isCheckedOut) {
      return _ActionSurface(
        title: 'أنهِ يومك',
        subtitle: 'تم تسجيل الدخول، يمكنك الآن تسجيل الانصراف',
        buttonLabel: 'تسجيل الانصراف',
        icon: Icons.logout_rounded,
        colorA: AppColors.error,
        colorB: AppColors.error.withValues(alpha: 0.78),
        onTap: isLoading ? null : onCheckOut,
      );
    }

    // When both checked in and out, don't show the "اليوم مكتمل" indicator
    // The summary section will be shown separately
    return const SizedBox.shrink();
  }
}

class _ActionSurface extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final VoidCallback? onTap;

  const _ActionSurface({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorA, colorB],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorA,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonLabel,
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorA,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
