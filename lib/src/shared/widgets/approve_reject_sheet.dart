import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Shows a bottom sheet with approve / reject / revert-to-pending options.
///
/// Returns `ApproveRejectResult` with the chosen action.
/// Returns `null` if the user dismissed the sheet.
Future<ApproveRejectResult?> showApproveRejectSheet(
  BuildContext context, {
  required String requestType,
}) {
  return showModalBottomSheet<ApproveRejectResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ApproveRejectSheet(requestType: requestType),
  );
}

class ApproveRejectResult {
  final ApproveRejectAction action;
  final String? rejectionReason;

  const ApproveRejectResult({required this.action, this.rejectionReason});

  bool get isApproved => action == ApproveRejectAction.approve;
  bool get isRejected => action == ApproveRejectAction.reject;
  bool get isRevertToPending => action == ApproveRejectAction.revertToPending;
}

enum ApproveRejectAction { approve, reject, revertToPending }

class _ApproveRejectSheet extends StatefulWidget {
  final String requestType;
  const _ApproveRejectSheet({required this.requestType});

  @override
  State<_ApproveRejectSheet> createState() => _ApproveRejectSheetState();
}

class _ApproveRejectSheetState extends State<_ApproveRejectSheet> {
  final _reasonController = TextEditingController();
  bool _showReasonField = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitReject() {
    Navigator.pop(
      context,
      ApproveRejectResult(
        action: ApproveRejectAction.reject,
        rejectionReason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'إدارة الطلب',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اختر الإجراء المطلوب على ${widget.requestType}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            if (!_showReasonField) ...[
              // ── Approve card ──────────────────────────────────────────
              _ActionCard(
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
                title: 'قبول',
                subtitle: 'الطلب سيتم اعتماده فوراً',
                onTap: () => Navigator.pop(
                  context,
                  const ApproveRejectResult(
                      action: ApproveRejectAction.approve),
                ),
              ),
              const SizedBox(height: 10),
              // ── Reject card (shows reason field) ─────────────────────
              _ActionCard(
                icon: Icons.cancel_rounded,
                iconColor: AppColors.error,
                title: 'رفض',
                subtitle: 'يمكنك إضافة سبب اختياري',
                onTap: () => setState(() => _showReasonField = true),
              ),
              const SizedBox(height: 10),
              // ── Revert to Pending card ──────────────────────────────
              _ActionCard(
                icon: Icons.undo_rounded,
                iconColor: AppColors.warning,
                title: 'إعادة للانتظار',
                subtitle: 'إرجاع الطلب لحالة الانتظار',
                onTap: () => Navigator.pop(
                  context,
                  const ApproveRejectResult(
                      action: ApproveRejectAction.revertToPending),
                ),
              ),
            ] else ...[
              // ── Rejection reason field ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          'سبب الرفض',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'اكتب سبب الرفض (اختياري)',
                        hintStyle: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _showReasonField = false;
                        _reasonController.clear();
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('رجوع'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Action Card ───────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded,
                color: AppColors.textTertiary, size: 22),
          ],
        ),
      ),
    );
  }
}
