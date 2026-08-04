import 'package:flutter/material.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/components/custom_toast.dart';
import '../leave_details_screen.dart';
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  LeaveDetailsScreen(leaveRequest: leaveRequest),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: leaveRequest.statusColor.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: leaveRequest.statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      leaveRequest.typeIcon,
                      color: leaveRequest.statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leaveRequest.typeText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          leaveRequest.dateRangeText,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(
                    text: leaveRequest.statusText,
                    color: leaveRequest.statusColor,
                  ),
                  _LeaveQuickRemindIcon(leaveRequest: leaveRequest),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: '${leaveRequest.numberOfDays} يوم',
                  ),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: _formatDate(leaveRequest.submittedDate),
                  ),
                  _InfoChip(
                    icon: Icons.label_outline_rounded,
                    label: leaveRequest.leaveType,
                  ),
                ],
              ),
              if (leaveRequest.reason?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 14),
                _DetailPanel(
                  icon: Icons.notes_rounded,
                  title: 'السبب',
                  body: leaveRequest.reason!,
                  color: AppColors.primary,
                ),
              ],
              if (leaveRequest.rejectionReason?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                _DetailPanel(
                  icon: Icons.info_outline_rounded,
                  title: 'سبب الرفض',
                  body: leaveRequest.rejectionReason!,
                  color: AppColors.error,
                  isError: true,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'عرض التفاصيل',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: leaveRequest.statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: leaveRequest.statusColor,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
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

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        tooltip: 'تذكير',
        onPressed: _isLoading ? null : _handleRemind,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: AppColors.warning.withValues(alpha: 0.95),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
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

class _DetailPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final bool isError;

  const _DetailPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? color.withValues(alpha: 0.08)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? color.withValues(alpha: 0.14) : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isError ? color : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isError ? color : AppColors.textSecondary,
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
