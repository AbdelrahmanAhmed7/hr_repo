import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_toast.dart';
import '../repository/assignment_repository.dart';
import '../models/mission.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;

  const MissionCard({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = mission.statusColor;

    return Container(
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    mission.icon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.dateRangeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mission.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label:
                      '${mission.numberOfDays} ${mission.numberOfDays == 1 ? 'يوم' : 'أيام'}',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: _formatDate(mission.submittedDate),
                ),
                const Spacer(),
                _MissionQuickRemindIcon(mission: mission),
              ],
            ),
            if (mission.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              _QuoteBlock(
                title: 'التفاصيل',
                body: mission.description,
                color: AppColors.primary,
              ),
            ],
            if (mission.rejectionReason != null) ...[
              const SizedBox(height: 10),
              _QuoteBlock(
                title: 'ملاحظة الإدارة',
                body: mission.rejectionReason!,
                color: AppColors.error,
                isError: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final bool isError;

  const _QuoteBlock({
    required this.title,
    required this.body,
    required this.color,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? color.withValues(alpha: 0.05)
            : AppColors.backgroundSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: isError ? color : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: isError ? color : AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionQuickRemindIcon extends StatefulWidget {
  final Mission mission;

  const _MissionQuickRemindIcon({required this.mission});

  @override
  State<_MissionQuickRemindIcon> createState() => _MissionQuickRemindIconState();
}

class _MissionQuickRemindIconState extends State<_MissionQuickRemindIcon> {
  bool _isLoading = false;

  bool get _canRemind => widget.mission.status == MissionStatus.pending;

  Future<void> _handleRemind() async {
    if (_isLoading || !_canRemind) return;

    final id = int.tryParse(widget.mission.id);
    if (id == null) {
      CustomToast.showError('تعذر إرسال التذكير: رقم المأمورية غير صحيح');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = (await getIt<AssignmentRepository>().remindAssignment(
        id: id,
      ))
          .message;

      if (!mounted) return;
      CustomToast.showSuccess(message.isNotEmpty ? message : 'تم إرسال التذكير بنجاح');
    } catch (_) {
      if (!mounted) return;
      CustomToast.showError('تعذر إرسال التذكير الآن. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRemind) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleRemind,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.notifications_active_outlined,
                    size: 17,
                    color: AppColors.warning,
                  ),
          ),
        ),
      ),
    );
  }
}
