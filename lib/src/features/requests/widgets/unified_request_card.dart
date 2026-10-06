import 'package:flutter/material.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/components/custom_toast.dart';
import '../../home/models/recent_activity.dart';
import '../../leaves/repository/leaves_repository.dart';
import '../../missions/repository/assignment_repository.dart';
import '../../permissions/repository/permission_repository.dart';

/// The single request card used on every screen (employee lists, home,
/// all-requests, admin lists, notification sheet).
///
/// Same look as the department request cards: white card, icon header with
/// employee/title + creation date + status badge, [_InfoRow] details,
/// rejection note and decision buttons. Employee actions (remind) show for
/// pending requests; admin decision buttons appear only when [onApprove] /
/// [onReject] are provided by the parent.
class UnifiedRequestCard extends StatelessWidget {
  final RecentActivity request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isLoading;
  final bool showRemind;

  const UnifiedRequestCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.isLoading = false,
    this.showRemind = true,
  });

  IconData _getTypeIcon() {
    switch (request.type) {
      case RequestType.leave:
        return Icons.beach_access_rounded;
      case RequestType.permission:
        return Icons.exit_to_app_rounded;
      case RequestType.overtime:
        return Icons.schedule_rounded;
      case RequestType.assignment:
        return Icons.assignment_rounded;
      case RequestType.other:
        return Icons.description_rounded;
    }
  }

  (Color, Color) _getIconColors() {
    switch (request.type) {
      case RequestType.assignment:
        return (const Color(0xFFFFF3E0), const Color(0xFFFF9800));
      default:
        return (AppColors.primaryTint, AppColors.primary);
    }
  }

  bool get _isPending => request.status == RequestStatus.pending;

  bool get _canRemind {
    if (!showRemind || !_isPending) return false;
    return request.type == RequestType.leave ||
        request.type == RequestType.permission ||
        request.type == RequestType.assignment;
  }

  static String _formatShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _hasTime(DateTime d) => d.hour != 0 || d.minute != 0;

  /// Ordered detail rows for this request type.
  List<(IconData, String, String)> _detailRows() {
    final r = request;
    final rows = <(IconData, String, String)>[];

    switch (r.type) {
      case RequestType.leave:
        if (r.startDate != null && r.endDate != null) {
          if (_isSameDay(r.startDate!, r.endDate!)) {
            rows.add((
              Icons.calendar_today_rounded,
              'التاريخ',
              _formatShort(r.startDate!),
            ));
          } else {
            rows.add((
              Icons.calendar_today_rounded,
              'من',
              _formatShort(r.startDate!),
            ));
            rows.add((
              Icons.calendar_month_rounded,
              'إلى',
              _formatShort(r.endDate!),
            ));
          }
        }
        if (r.leaveType?.trim().isNotEmpty == true) {
          rows.add((
            Icons.category_outlined,
            'نوع الإجازة',
            r.leaveType!.trim(),
          ));
        }
        if (r.deductionType?.trim().isNotEmpty == true) {
          rows.add((
            Icons.money_off_outlined,
            'الخصم',
            r.deductionType!.trim(),
          ));
        }
        if (r.remainingVacationBalance != null) {
          rows.add((
            Icons.account_balance_wallet_outlined,
            'الرصيد المتبقي',
            '${r.remainingVacationBalance} يوم',
          ));
        }
      case RequestType.permission:
      case RequestType.overtime:
        if (r.startDate != null) {
          rows.add((
            Icons.calendar_today_rounded,
            'التاريخ',
            _formatShort(r.startDate!),
          ));
        }
        if (r.startTime?.trim().isNotEmpty == true &&
            r.endTime?.trim().isNotEmpty == true) {
          rows.add((
            Icons.schedule_rounded,
            'الوقت',
            AppDateUtils.formatTimeRange12h(
              r.startTime!.trim(),
              r.endTime!.trim(),
            ),
          ));
        }
        if (r.deductionType?.trim().isNotEmpty == true) {
          rows.add((
            Icons.money_off_outlined,
            'نوع الخصم',
            r.deductionType!.trim(),
          ));
        }
        if (r.totalHours != null) {
          rows.add((
            Icons.timer_outlined,
            'عدد الساعات',
            '${r.totalHours}',
          ));
        }
        if (r.amount != null) {
          rows.add((
            Icons.payments_outlined,
            'القيمة',
            AppFormatters.currency(r.amount),
          ));
        }
      case RequestType.assignment:
        if (r.location?.trim().isNotEmpty == true) {
          rows.add((
            Icons.location_on_rounded,
            'الموقع',
            r.location!.trim(),
          ));
        }
        if (r.startDate != null && r.endDate != null) {
          if (_isSameDay(r.startDate!, r.endDate!)) {
            rows.add((
              Icons.calendar_today_rounded,
              'التاريخ',
              _formatShort(r.startDate!),
            ));
          } else {
            rows.add((
              Icons.calendar_today_rounded,
              'من',
              _formatShort(r.startDate!),
            ));
            rows.add((
              Icons.calendar_month_rounded,
              'إلى',
              _formatShort(r.endDate!),
            ));
          }
          if (_hasTime(r.startDate!) || _hasTime(r.endDate!)) {
            rows.add((
              Icons.schedule_rounded,
              'الوقت',
              '${AppDateUtils.formatTime12h(r.startDate!)} - ${AppDateUtils.formatTime12h(r.endDate!)}',
            ));
          }
        }
      case RequestType.other:
        break;
    }

    if (r.userName?.trim().isNotEmpty == true) {
      rows.add((
        Icons.person_rounded,
        'الموظف',
        r.userName!.trim(),
      ));
    }

    final reason = r.reason?.trim() ?? '';
    if (reason.isNotEmpty) {
      rows.add((Icons.description_outlined, 'السبب', reason));
    } else {
      final details = r.description?.trim() ?? '';
      if (details.isNotEmpty) {
        rows.add((Icons.notes_outlined, 'التفاصيل', details));
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = request.statusColor;
    final iconColors = _getIconColors();
    final rows = _detailRows();
    final showDecisions =
        _isPending && (onApprove != null || onReject != null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColors.$1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: iconColors.$2,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'تاريخ إنشاء الطلب: ${AppDateUtils.formatDateTime12h(request.effectiveCreatedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canRemind) ...[
                  _RemindButton(request: request),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    request.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            if (rows.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _InfoRow(
                  icon: rows[i].$1,
                  label: rows[i].$2,
                  value: rows[i].$3,
                ),
              ],
            ],

            // Rejection reason
            if (request.rejectionReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${request.rejectionReason!.trim()}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Action buttons ───────────────────────────────────────
            if (showDecisions) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('رفض'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: AppTextStyles.labelMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  if (onReject != null && onApprove != null)
                    const SizedBox(width: 10),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : onApprove,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('قبول'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: AppTextStyles.labelMedium,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Info Row (same as department cards) ──────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RemindButton extends StatefulWidget {
  final RecentActivity request;

  const _RemindButton({required this.request});

  @override
  State<_RemindButton> createState() => _RemindButtonState();
}

class _RemindButtonState extends State<_RemindButton> {
  bool _isLoading = false;

  RecentActivity get request => widget.request;

  Future<void> _handleRemind() async {
    if (_isLoading) return;

    final id = int.tryParse(request.id);
    if (id == null) {
      CustomToast.showError('تعذر إرسال التذكير: رقم الطلب غير صحيح');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = switch (request.type) {
        RequestType.leave =>
          (await getIt<LeavesRepository>().remindLeave(id: id)).message,
        RequestType.permission =>
          (await getIt<PermissionRepository>().remindPermission(id: id))
              .message,
        RequestType.assignment =>
          (await getIt<AssignmentRepository>().remindAssignment(id: id))
              .message,
        RequestType.overtime => null,
        RequestType.other => null,
      };

      if (!mounted) return;
      CustomToast.showSuccess(message ?? 'تم إرسال التذكير بنجاح');
    } catch (_) {
      if (!mounted) return;
      CustomToast.showError('تعذر إرسال التذكير الآن. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                : const Icon(
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
