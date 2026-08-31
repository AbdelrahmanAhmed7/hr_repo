import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/service_locator.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/approve_reject_sheet.dart';
import '../admin/repository/admin_permissions_repository.dart';
import 'models/permission_request.dart';

class PermissionDetailsScreen extends StatefulWidget {
  final PermissionRequest permission;

  const PermissionDetailsScreen({super.key, required this.permission});

  @override
  State<PermissionDetailsScreen> createState() =>
      _PermissionDetailsScreenState();
}

class _PermissionDetailsScreenState extends State<PermissionDetailsScreen> {
  bool _isLoading = false;

  bool get _isPending =>
      widget.permission.status == PermissionStatus.pending;
  bool get _isApproved =>
      widget.permission.status == PermissionStatus.approved;
  bool get _isRejected =>
      widget.permission.status == PermissionStatus.rejected;
  bool get _canChangeDecision => _isPending || _isApproved || _isRejected;

  PermissionRequest get permission => widget.permission;

  static String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
  static String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _handleApprove() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await getIt<AdminPermissionsRepository>().approvePermission(
        int.parse(permission.id),
      );
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
      await getIt<AdminPermissionsRepository>().rejectPermission(
        int.parse(permission.id),
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
      await getIt<AdminPermissionsRepository>().revertPermissionToPending(
        int.parse(permission.id),
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
        requestType: 'الإذن',
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
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 220,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _Hero(permission: permission),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              child: Column(
                children: [
                  _Section(
                    title: 'ملخص سريع',
                    icon: Icons.dashboard_customize_rounded,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Tile(
                          icon: Icons.calendar_today_rounded,
                          label: 'تاريخ الإذن',
                          value:
                              '${permission.dateText}\n${permission.timeRangeText}',
                        ),
                        _Tile(
                          icon: Icons.schedule_rounded,
                          label: 'الوقت',
                          value: permission.timeRangeText,
                        ),
                        _Tile(
                          icon: Icons.timer_outlined,
                          label: 'المدة',
                          value: permission.durationText,
                        ),
                        _Tile(
                          icon: Icons.send_rounded,
                          label: 'تاريخ التقديم',
                          value:
                              '${_fmt(permission.submittedDate)}\n${_fmtTime(permission.submittedDate)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'الخط الزمني',
                    icon: Icons.route_rounded,
                    child: Column(
                      children: [
                        _TimelineRow(
                          title: 'تم تقديم الطلب',
                          subtitle: _fmt(permission.submittedDate),
                          color: AppColors.primary,
                          isDone: true,
                        ),
                        _TimelineRow(
                          title: 'وقت الإذن',
                          subtitle:
                              '${permission.dateText} — ${permission.timeRangeText}',
                          color: AppColors.warning,
                          isDone: true,
                        ),
                        _TimelineRow(
                          title: 'الحالة الحالية',
                          subtitle: permission.statusText,
                          color: permission.statusColor,
                          isDone: permission.status != PermissionStatus.pending,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    title: 'السبب',
                    icon: Icons.notes_rounded,
                    child: Text(
                      permission.reason.trim().isNotEmpty
                          ? permission.reason
                          : 'لم يتم إضافة سبب.',
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
                    ),
                  ),
                  if (permission.rejectionReason?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _Section(
                        title: 'ملاحظة الإدارة',
                        icon: Icons.info_outline_rounded,
                        borderColor: AppColors.error.withValues(alpha: 0.20),
                        backgroundColor:
                            AppColors.error.withValues(alpha: 0.05),
                        child: Text(
                          permission.rejectionReason!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                  if (_canChangeDecision) ...[
                    const SizedBox(height: 18),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final statusLabel = _isApproved
        ? 'تم القبول مسبقاً'
        : _isRejected
            ? 'تم الرفض مسبقاً'
            : 'بانتظار القرار';

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.gavel_rounded,
                    color: AppColors.success, size: 18),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isApproved
                          ? AppColors.success
                          : _isRejected
                              ? AppColors.error
                              : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _isApproved
                        ? AppColors.success
                        : _isRejected
                            ? AppColors.error
                            : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (_isPending || _isApproved) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _onApproveRejectPressed(approve: false),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded, size: 16),
                    label: Text(_isApproved ? 'تغيير إلى رفض' : 'رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
                if (_isPending || _isRejected) const SizedBox(width: 10),
              ],
              if (_isPending || _isRejected) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _onApproveRejectPressed(approve: true),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(_isRejected ? 'تغيير إلى قبول' : 'قبول'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: AppTextStyles.labelMedium,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!_isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _onApproveRejectPressed,
                icon: _isLoading
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
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

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final PermissionRequest permission;
  const _Hero({required this.permission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 76, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B1734),
            const Color(0xFF12306A),
            permission.statusColor.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إذن خروج',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Chip(icon: Icons.flag_rounded, label: permission.statusText),
              _Chip(
                  icon: Icons.schedule_rounded,
                  label: permission.timeRangeText),
              _Chip(
                  icon: Icons.timer_outlined, label: permission.durationText),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Section ─────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? AppColors.border),
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
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Metric Tile ─────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Tile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 58) / 2;
    return SizedBox(
      width: w,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.labelMedium),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline Row ─────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isDone;
  final bool isLast;

  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDone,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12)
                  : null,
            ),
            if (!isLast)
              Container(width: 2, height: 38, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
