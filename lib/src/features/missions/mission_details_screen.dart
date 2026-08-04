import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/mission.dart';

class MissionDetailsScreen extends StatelessWidget {
  final Mission mission;

  const MissionDetailsScreen({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 244,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _MissionHero(mission: mission),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                children: [
                  _SectionCard(
                    title: 'لوحة سريعة',
                    icon: Icons.dashboard_customize_rounded,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _DetailMetric(
                          label: 'الحالة',
                          value: mission.statusText,
                          icon: Icons.flag_rounded,
                          accent: mission.statusColor,
                        ),
                        _DetailMetric(
                          label: 'المدة',
                          value: '${mission.numberOfDays} يوم',
                          icon: Icons.timelapse_rounded,
                        ),
                        _DetailMetric(
                          label: 'بداية المأمورية',
                          value: _formatDateTime(mission.startDate),
                          icon: Icons.play_circle_outline_rounded,
                        ),
                        _DetailMetric(
                          label: 'نهاية المأمورية',
                          value: _formatDateTime(mission.endDate),
                          icon: Icons.stop_circle_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'ملخص المأمورية',
                    icon: Icons.notes_rounded,
                    child: Text(
                      mission.description.trim().isNotEmpty
                          ? mission.description
                          : 'لا توجد تفاصيل إضافية لهذه المأمورية.',
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'الخط الزمني',
                    icon: Icons.alt_route_rounded,
                    child: Column(
                      children: [
                        _TimelineTile(
                          title: 'تم تقديم الطلب',
                          subtitle: _formatDateTime(mission.submittedDate),
                          icon: Icons.upload_file_rounded,
                          color: const Color(0xFF246BFD),
                        ),
                        const _TimelineDivider(),
                        _TimelineTile(
                          title: 'بداية التنفيذ',
                          subtitle: _formatDateTime(mission.startDate),
                          icon: Icons.login_rounded,
                          color: const Color(0xFF0F9D58),
                        ),
                        const _TimelineDivider(),
                        _TimelineTile(
                          title: 'نهاية التنفيذ',
                          subtitle: _formatDateTime(mission.endDate),
                          icon: Icons.logout_rounded,
                          color: const Color(0xFFF2994A),
                        ),
                      ],
                    ),
                  ),
                  if (mission.status == MissionStatus.rejected &&
                      mission.rejectionReason != null &&
                      mission.rejectionReason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'ملاحظة الإدارة',
                      icon: Icons.info_outline_rounded,
                      accent: AppColors.error,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          mission.rejectionReason!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionHero extends StatelessWidget {
  final Mission mission;

  const _MissionHero({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B1734),
            const Color(0xFF163B7A),
            mission.statusColor.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(mission.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            mission.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _HeroTag(label: 'مأمورية'),
              _HeroTag(label: mission.statusText),
              _HeroTag(label: _formatDateTime(mission.startDate)),
              _HeroTag(label: '${mission.numberOfDays} يوم'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;

  const _HeroTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accent;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: resolvedAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: resolvedAccent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  const _DetailMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.of(context).size.width - 58;
    final cardWidth = availableWidth > 360 ? availableWidth / 2 : availableWidth;
    final resolvedAccent = accent ?? AppColors.primary;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: resolvedAccent, size: 18),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TimelineTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 19, top: 6, bottom: 6),
      child: Container(
        width: 2,
        height: 22,
        color: AppColors.border,
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} - $hour:$minute';
}
