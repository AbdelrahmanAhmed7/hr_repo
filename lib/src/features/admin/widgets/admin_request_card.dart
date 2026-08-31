import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/recent_activity.dart';
import '../../requests/request_details_screen.dart';

class AdminRequestCard extends StatelessWidget {
  final RecentActivity request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isLoading;

  const AdminRequestCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.isLoading = false,
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

  Color _getTypeColor() {
    switch (request.type) {
      case RequestType.leave:
        return const Color(0xFF0284C7);
      case RequestType.permission:
        return const Color(0xFFD97706);
      case RequestType.overtime:
        return const Color(0xFF7C3AED);
      case RequestType.assignment:
        return const Color(0xFF0F766E);
      case RequestType.other:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<String> _detailChips() {
    final chips = <String>[];

    switch (request.type) {
      case RequestType.leave:
        if (request.startDate != null && request.endDate != null) {
          chips.add(
            '${_formatDate(request.startDate!)} → ${_formatDate(request.endDate!)}',
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
          chips.add(_formatDate(request.startDate!));
        }
      case RequestType.assignment:
        if (request.location?.trim().isNotEmpty == true) {
          chips.add(request.location!);
        }
        if (request.startDate != null && request.endDate != null) {
          chips.add(
            '${_formatDate(request.startDate!)} → ${_formatDate(request.endDate!)}',
          );
        } else {
          chips.add(_formatDate(request.date));
        }
      case RequestType.other:
        break;
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == RequestStatus.pending;
    final typeColor = _getTypeColor();
    final chips = _detailChips();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestDetailsScreen(request: request, showRemindButton: false),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: type icon + title/status ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_getTypeIcon(), color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.typeText,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(request: request),
            ],
          ),

          // ── Employee name ──
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
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Reason ──
          if (request.reason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              request.reason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          // ── Type-specific detail chips ──
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Text(
                      chip,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // ── Created date ──
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'تم الإنشاء: ${_formatDate(request.date)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),

          // ── Remaining vacation balance (leave only) ──
          if (request.type == RequestType.leave &&
              request.remainingVacationBalance != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryTint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'الرصيد المتبقي: ${request.remainingVacationBalance} يوم',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          // ── Rejection reason ──
          if (request.status == RequestStatus.rejected) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.block_rounded,
                        size: 15,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'سبب الرفض',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (request.rejectionReason?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      request.rejectionReason!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'لم يتم تحديد سبب الرفض.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Action buttons (only for pending requests) ──
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC41E3A),
                      side: const BorderSide(color: Color(0xFFC41E3A)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

class _StatusPill extends StatelessWidget {
  final RecentActivity request;

  const _StatusPill({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: request.statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: request.statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        request.statusText,
        style: AppTextStyles.labelSmall.copyWith(
          color: request.statusColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}