import 'package:flutter/material.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../shared/components/custom_toast.dart';
import '../../home/models/recent_activity.dart';
import '../../leaves/repository/leaves_repository.dart';
import '../../missions/repository/assignment_repository.dart';
import '../../permissions/repository/permission_repository.dart';

/// The single request card used on every screen (employee lists, home,
/// all-requests, admin lists, notification sheet).
///
/// Renders the full request: status strip, header, per-type chips, applicant,
/// reason, rejection note and structured extra details. Employee actions
/// (remind) show for pending requests; admin decision buttons appear only
/// when [onApprove]/[onReject] are provided by the parent.
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
        return Icons.calendar_month_rounded;
      case RequestType.permission:
        return Icons.access_time_rounded;
      case RequestType.overtime:
        return Icons.schedule_rounded;
      case RequestType.assignment:
        return Icons.directions_rounded;
      case RequestType.other:
        return Icons.description_rounded;
    }
  }

  bool get _isPending => request.status == RequestStatus.pending;

  bool get _canRemind {
    if (!showRemind || !_isPending) return false;
    return request.type == RequestType.leave ||
        request.type == RequestType.permission ||
        request.type == RequestType.assignment;
  }

  String _formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'اليوم';
    if (difference.inDays == 1) return 'أمس';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} أيام';
    return _formatShort(date);
  }

  static String _formatShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _detailChips() {
    final chips = <String>[];

    switch (request.type) {
      case RequestType.leave:
        if (request.startDate != null && request.endDate != null) {
          chips.add(
            _isSameDay(request.startDate!, request.endDate!)
                ? _formatShort(request.startDate!)
                : '${_formatShort(request.startDate!)} → ${_formatShort(request.endDate!)}',
          );
        }
        if (request.leaveType?.trim().isNotEmpty == true) {
          chips.add(request.leaveType!);
        }
        if (request.deductionType?.trim().isNotEmpty == true) {
          chips.add('خصم ${request.deductionType}');
        }
      case RequestType.permission:
      case RequestType.overtime:
        if (request.startTime?.trim().isNotEmpty == true &&
            request.endTime?.trim().isNotEmpty == true) {
          chips.add('${request.startTime!.trim()} - ${request.endTime!.trim()}');
        }
        if (request.startDate != null) {
          chips.add(_formatShort(request.startDate!));
        }
      case RequestType.assignment:
        if (request.location?.trim().isNotEmpty == true) {
          chips.add(request.location!);
        }
        if (request.startDate != null && request.endDate != null) {
          chips.add(
            '${_formatShort(request.startDate!)} → ${_formatShort(request.endDate!)}',
          );
        }
      case RequestType.other:
        break;
    }

    return chips;
  }

  /// Structured rows for info NOT already shown in chips
  /// (dates/times/location/type live in chips to avoid duplication).
  List<(String, String)> _detailRows() {
    final r = request;
    return [
      if (r.deductionType?.trim().isNotEmpty == true &&
          r.type != RequestType.leave)
        ('نوع الخصم', r.deductionType!.trim()),
      if (r.totalHours != null) ('عدد الساعات', '${r.totalHours}'),
      if (r.amount != null) ('القيمة', AppFormatters.currency(r.amount)),
      if (r.type == RequestType.leave && r.remainingVacationBalance != null)
        ('الرصيد المتبقي', '${r.remainingVacationBalance} يوم'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = request.statusColor;
    final chips = _detailChips();
    final rows = _detailRows();
    final showDecisions =
        _isPending && (onApprove != null || onReject != null);

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
                    _getTypeIcon(),
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
                        request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRelative(request.date),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
                    request.statusText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: request.typeText),
                      for (final chip in chips) _Chip(label: chip),
                    ],
                  ),
                ),
                if (_canRemind) ...[
                  const SizedBox(width: 8),
                  _RemindButton(request: request),
                ],
              ],
            ),
            if (request.userName?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.userName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (request.reason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _QuoteBlock(
                title: 'السبب',
                body: request.reason!,
                color: AppColors.primary,
              ),
            ],
            if (request.rejectionReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _QuoteBlock(
                title: 'ملاحظة الإدارة',
                body: request.rejectionReason!,
                color: AppColors.error,
                isError: true,
              ),
            ],
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                children: [
                  for (int i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 13,
                        thickness: 0.5,
                        color: AppColors.border,
                      ),
                    Row(
                      children: [
                        Text(
                          rows[i].$1,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            rows[i].$2,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
            if (showDecisions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : onReject,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('رفض'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('موافقة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
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
            ),
          ],
        ),
      ),
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
