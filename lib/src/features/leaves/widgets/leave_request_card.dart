import 'package:flutter/material.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/components/custom_toast.dart';
import '../models/leave_request_model.dart';
import '../repository/leaves_repository.dart';

class LeaveRequestCard extends StatelessWidget {
  final LeaveRequestModel leaveRequest;

  const LeaveRequestCard({
    super.key,
    required this.leaveRequest,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = leaveRequest.statusColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          right: BorderSide(color: statusColor, width: 4),
          top: const BorderSide(color: AppColors.border),
          left: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
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
                  leaveRequest.typeIcon,
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
                      leaveRequest.typeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.date_range_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            leaveRequest.dateRangeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(
                text: leaveRequest.statusText,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: '${leaveRequest.numberOfDays} يوم',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: _formatDate(leaveRequest.submittedDate),
              ),
              const Spacer(),
              _LeaveQuickRemindIcon(leaveRequest: leaveRequest),
            ],
          ),
          if (leaveRequest.reason?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            _QuoteBlock(
              title: 'السبب',
              body: leaveRequest.reason!,
              color: AppColors.primary,
            ),
          ],
          if (leaveRequest.rejectionReason?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            _QuoteBlock(
              title: 'ملاحظة الإدارة',
              body: leaveRequest.rejectionReason!,
              color: AppColors.error,
              isError: true,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'اليوم';
    if (difference.inDays == 1) return 'أمس';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} أيام';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Slim quote-style block with a colored side accent instead of a boxed card.
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
        border: Border(
          right: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: isError ? color : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: isError ? color : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveQuickRemindIcon extends StatefulWidget {
  final LeaveRequestModel leaveRequest;

  const _LeaveQuickRemindIcon({required this.leaveRequest});

  @override
  State<_LeaveQuickRemindIcon> createState() => _LeaveQuickRemindIconState();
}

class _LeaveQuickRemindIconState extends State<_LeaveQuickRemindIcon> {
  bool _isLoading = false;

  bool get _canRemind =>
      widget.leaveRequest.status.toLowerCase().trim() == 'pending';

  Future<void> _handleRemind() async {
    if (_isLoading || !_canRemind) return;

    setState(() => _isLoading = true);
    try {
      final message = (await getIt<LeavesRepository>().remindLeave(
        id: widget.leaveRequest.id,
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

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
