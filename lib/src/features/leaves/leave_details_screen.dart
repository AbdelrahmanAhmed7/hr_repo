import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/service_locator.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/approve_reject_sheet.dart';
import '../admin/repository/admin_leaves_repository.dart';
import 'models/leave_request_model.dart';

class LeaveDetailsScreen extends StatefulWidget {
  final LeaveRequestModel leaveRequest;

  const LeaveDetailsScreen({
    super.key,
    required this.leaveRequest,
  });

  @override
  State<LeaveDetailsScreen> createState() => _LeaveDetailsScreenState();
}

class _LeaveDetailsScreenState extends State<LeaveDetailsScreen> {
  bool _isLoading = false;

  bool get _isPending =>
      widget.leaveRequest.status.toLowerCase() == 'pending';
  bool get _isApproved =>
      widget.leaveRequest.status.toLowerCase() == 'approved';
  bool get _isRejected =>
      widget.leaveRequest.status.toLowerCase() == 'rejected';
  bool get _canChangeDecision => _isPending || _isApproved || _isRejected;

  LeaveRequestModel get leaveRequest => widget.leaveRequest;

  Future<void> _handleApprove() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await getIt<AdminLeavesRepository>().approveLeave(leaveRequest.id);
      if (!mounted) return;
      CustomToast.showSuccess('تم قبول الطلب بنجاح');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject(String? reason) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await getIt<AdminLeavesRepository>().rejectLeave(
        leaveRequest.id,
        rejectionReason: reason,
      );
      if (!mounted) return;
      CustomToast.showSuccess('تم رفض الطلب');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRevertToPending() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await getIt<AdminLeavesRepository>().revertLeaveToPending(
        leaveRequest.id,
      );
      if (!mounted) return;
      CustomToast.showSuccess('تم إرجاع الطلب لحالة الانتظار');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onApproveRejectPressed({bool? approve}) async {
    final shouldApprove = approve ?? true;
    if (shouldApprove) {
      await _handleApprove();
    } else {
      final result = await showApproveRejectSheet(
        context,
        requestType: 'الإجازة',
      );
      if (result == null || !mounted) return;
      if (result.isRevertToPending) {
        await _handleRevertToPending();
      } else if (result.isApproved) {
        await _handleApprove();
      } else {
        await _handleReject(result.rejectionReason);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'تفاصيل الإجازة',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            _SummaryCard(leaveRequest: leaveRequest),
            const SizedBox(height: 12),
            _DetailCard(
              title: 'السبب',
              icon: Icons.notes_rounded,
              child: Text(
                leaveRequest.reason?.trim().isNotEmpty == true
                    ? leaveRequest.reason!
                    : 'لم يتم إضافة سبب لهذا الطلب.',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
              ),
            ),
            if (leaveRequest.rejectionReason?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              _DetailCard(
                title: 'ملاحظة الإدارة',
                icon: Icons.info_outline_rounded,
                tintColor: AppColors.error,
                child: Text(
                  leaveRequest.rejectionReason!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    height: 1.7,
                  ),
                ),
              ),
            ],
            // ── Approve / Reject actions ──────────────────────────
            if (_canChangeDecision) ...[
              const SizedBox(height: 14),
              _DecisionCard(
                leaveRequest: leaveRequest,
                isLoading: _isLoading,
                isApproved: _isApproved,
                isRejected: _isRejected,
                isPending: _isPending,
                onApproveRejectPressed: _onApproveRejectPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One compact card holding everything about the request: type + status,
/// dates, duration and submission date.
class _SummaryCard extends StatelessWidget {
  final LeaveRequestModel leaveRequest;

  const _SummaryCard({required this.leaveRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  leaveRequest.typeIcon,
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
                      leaveRequest.typeText,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'قُدم في ${_formatDateTime(leaveRequest.submittedDate)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: leaveRequest.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  leaveRequest.statusText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: leaveRequest.statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5, color: AppColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  value: _formatDate(leaveRequest.startDateDateTime),
                  label: 'من',
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.border),
              Expanded(
                child: _MiniStat(
                  value: _formatDate(leaveRequest.endDateDateTime),
                  label: 'إلى',
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.border),
              Expanded(
                child: _MiniStat(
                  value: '${leaveRequest.numberOfDays} يوم',
                  label: 'المدة',
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} - $hour:$minute';
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;

  const _MiniStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? tintColor;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tintColor != null
            ? tint.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tintColor != null
              ? tint.withValues(alpha: 0.20)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: tint, size: 17),
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  final LeaveRequestModel leaveRequest;
  final bool isLoading;
  final bool isApproved;
  final bool isRejected;
  final bool isPending;
  final Future<void> Function({bool? approve}) onApproveRejectPressed;

  const _DecisionCard({
    required this.leaveRequest,
    required this.isLoading,
    required this.isApproved,
    required this.isRejected,
    required this.isPending,
    required this.onApproveRejectPressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = isApproved
        ? 'تم القبول مسبقاً'
        : isRejected
            ? 'تم الرفض مسبقاً'
            : 'بانتظار القرار';
    final statusColor = isApproved
        ? AppColors.success
        : isRejected
            ? AppColors.error
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.success,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'القرار',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Reject button: show when pending OR approved (to change decision)
              if (isPending || isApproved) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => onApproveRejectPressed(approve: false),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded, size: 16),
                    label: Text(isApproved ? 'تغيير إلى رفض' : 'رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      textStyle: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
                if (isPending || isRejected) const SizedBox(width: 10),
              ],
              // Approve button: show when pending OR rejected (to change decision)
              if (isPending || isRejected) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => onApproveRejectPressed(approve: true),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(isRejected ? 'تغيير إلى قبول' : 'قبول'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      textStyle: AppTextStyles.labelMedium,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onApproveRejectPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.undo_rounded, size: 16),
                label: const Text('إعادة للانتظار'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  textStyle: AppTextStyles.labelMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
