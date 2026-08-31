import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/service_locator.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/approve_reject_sheet.dart';
import '../admin/repository/admin_leaves_repository.dart';
import '../admin/repository/admin_permissions_repository.dart';
import '../admin/repository/admin_assignments_repository.dart';
import '../leaves/repository/leaves_repository.dart';
import '../missions/repository/assignment_repository.dart';
import '../permissions/repository/permission_repository.dart';
import '../home/models/recent_activity.dart';

class RequestDetailsScreen extends StatefulWidget {
  final RecentActivity request;
  final bool showRemindButton;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    this.showRemindButton = true,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  bool _isReminding = false;
  bool _isApproving = false;

  RecentActivity get request => widget.request;

  bool get _canRemind {
    if (!widget.showRemindButton) return false;
    if (request.status != RequestStatus.pending) return false;
    if (request.type == RequestType.leave) return true;
    if (request.type == RequestType.permission) return true;
    if (request.type == RequestType.assignment) return true;
    return false;
  }

  bool get _canApproveReject {
    if (request.status == RequestStatus.approved) return true;
    if (request.status == RequestStatus.rejected) return true;
    if (request.status != RequestStatus.pending) return false;
    return request.type == RequestType.leave ||
        request.type == RequestType.permission ||
        request.type == RequestType.assignment;
  }

  bool get _isPending => request.status == RequestStatus.pending;
  bool get _isApproved => request.status == RequestStatus.approved;
  bool get _isRejected => request.status == RequestStatus.rejected;

  Future<void> _handleRemind() async {
    if (_isReminding || !_canRemind) return;

    final id = int.tryParse(request.id);
    if (id == null) {
      CustomToast.showError('تعذر إرسال التذكير: رقم الطلب غير صحيح');
      return;
    }

    setState(() => _isReminding = true);

    try {
      final message = switch (request.type) {
        RequestType.leave =>
          (await getIt<LeavesRepository>().remindLeave(id: id)).message,
        RequestType.permission =>
          (await getIt<PermissionRepository>().remindPermission(id: id)).message,
        RequestType.assignment =>
          (await getIt<AssignmentRepository>().remindAssignment(id: id)).message,
        RequestType.overtime => null,
        RequestType.other => null,
      };

      if (!mounted) return;
      CustomToast.showSuccess(message ?? 'تم إرسال التذكير بنجاح');
    } catch (_) {
      if (!mounted) return;
      CustomToast.showError('تعذر إرسال التذكير الآن. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isReminding = false);
    }
  }

  Future<void> _handleApprove() async {
    if (_isApproving) return;
    final id = int.tryParse(request.id);
    if (id == null) {
      CustomToast.showError('رقم الطلب غير صحيح');
      return;
    }
    setState(() => _isApproving = true);
    try {
      switch (request.type) {
        case RequestType.leave:
          await getIt<AdminLeavesRepository>().approveLeave(id);
          break;
        case RequestType.permission:
          await getIt<AdminPermissionsRepository>().approvePermission(id);
          break;
        case RequestType.assignment:
          await getIt<AdminAssignmentsRepository>().approveAssignment(id);
          break;
        default:
          break;
      }
      if (!mounted) return;
      CustomToast.showSuccess('تم قبول الطلب بنجاح');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _handleReject(String? reason) async {
    if (_isApproving) return;
    final id = int.tryParse(request.id);
    if (id == null) {
      CustomToast.showError('رقم الطلب غير صحيح');
      return;
    }
    setState(() => _isApproving = true);
    try {
      switch (request.type) {
        case RequestType.leave:
          await getIt<AdminLeavesRepository>().rejectLeave(
            id,
            rejectionReason: reason,
          );
          break;
        case RequestType.permission:
          await getIt<AdminPermissionsRepository>().rejectPermission(
            id,
            rejectionReason: reason,
          );
          break;
        case RequestType.assignment:
          await getIt<AdminAssignmentsRepository>().rejectAssignment(
            id,
            rejectionReason: reason,
          );
          break;
        default:
          break;
      }
      if (!mounted) return;
      CustomToast.showSuccess('تم رفض الطلب');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _handleRevertToPending() async {
    if (_isApproving) return;
    final id = int.tryParse(request.id);
    if (id == null) {
      CustomToast.showError('رقم الطلب غير صحيح');
      return;
    }
    setState(() => _isApproving = true);
    try {
      switch (request.type) {
        case RequestType.leave:
          await getIt<AdminLeavesRepository>().revertLeaveToPending(id);
          break;
        case RequestType.permission:
          await getIt<AdminPermissionsRepository>().revertPermissionToPending(id);
          break;
        case RequestType.assignment:
          await getIt<AdminAssignmentsRepository>().revertAssignmentToPending(id);
          break;
        default:
          break;
      }
      if (!mounted) return;
      CustomToast.showSuccess('تم إرجاع الطلب لحالة الانتظار');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _onApproveRejectPressed({bool? approve}) async {
    final shouldApprove = approve ?? true;
    if (shouldApprove) {
      await _handleApprove();
    } else {
      final result = await showApproveRejectSheet(
        context,
        requestType: request.typeText,
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
            expandedHeight: 228,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _RequestHero(request: request),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                children: [
                  if (_canRemind) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
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
                                  'تذكير بالطلب',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'إرسال تنبيه لإدارة الموارد البشرية بوجود طلب معلّق.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _isReminding ? null : _handleRemind,
                              icon: _isReminding
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                _isReminding ? 'جارٍ الإرسال' : 'تذكير',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _SectionCard(
                    title: 'بطاقة الطلب',
                    icon: _getTypeIcon(request.type),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _DetailMetric(
                          label: 'نوع الطلب',
                          value: request.typeText,
                          icon: Icons.layers_outlined,
                        ),
                        _DetailMetric(
                          label: 'التاريخ',
                          value: _formatDateTime(request.date),
                          icon: Icons.calendar_today_rounded,
                        ),
                        _DetailMetric(
                          label: 'الحالة',
                          value: request.statusText,
                          icon: Icons.flag_rounded,
                        ),
                        if (request.remainingVacationBalance != null)
                          _DetailMetric(
                            label: 'الرصيد المتبقي',
                            value: '${request.remainingVacationBalance} يوم',
                            icon: Icons.beach_access_rounded,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'الملخص',
                    icon: Icons.notes_rounded,
                    child: Text(
                      request.reason?.trim().isNotEmpty == true
                          ? request.reason!
                          : (request.description?.trim().isNotEmpty == true
                                ? request.description!
                                : 'لا توجد تفاصيل إضافية لهذا الطلب.'),
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
                    ),
                  ),
                  if (request.userName != null) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'مقدم الطلب',
                      icon: Icons.person_rounded,
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              request.userName!,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_extraDetails(request).isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'تفاصيل إضافية',
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        children: _extraDetails(request)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        entry.$1,
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.$2,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  if (_canApproveReject) ...[
                    const SizedBox(height: 14),
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

    return _SectionCard(
      title: 'القرار',
      icon: Icons.gavel_rounded,
      child: Column(
        children: [
          Row(
            children: [
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
                    onPressed: _isApproving
                        ? null
                        : () => _onApproveRejectPressed(approve: false),
                    icon: _isApproving
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
                    onPressed: _isApproving
                        ? null
                        : () => _onApproveRejectPressed(approve: true),
                    icon: _isApproving
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
                onPressed: _isApproving ? null : _onApproveRejectPressed,
                icon: _isApproving
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

  static IconData _getTypeIcon(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return Icons.calendar_today_rounded;
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

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} - $hour:$minute';
  }

  static List<(String, String)> _extraDetails(RecentActivity request) {
    final items = <(String, String)>[];
    if (request.startDate != null) {
      items.add(('تاريخ البداية', _formatDate(request.startDate!)));
    }
    if (request.endDate != null) {
      items.add(('تاريخ النهاية', _formatDate(request.endDate!)));
    }
    if (request.startTime?.trim().isNotEmpty == true &&
        request.endTime?.trim().isNotEmpty == true) {
      items.add(('الوقت', '${request.startTime} - ${request.endTime}'));
    }
    if (request.leaveType?.trim().isNotEmpty == true) {
      items.add(('نوع الإجازة', request.leaveType!));
    }
    if (request.deductionType?.trim().isNotEmpty == true) {
      items.add(('نوع الخصم', request.deductionType!));
    }
    if (request.location?.trim().isNotEmpty == true) {
      items.add(('المكان', request.location!));
    }
    if (request.totalHours != null) {
      items.add(('عدد الساعات', '${request.totalHours}'));
    }
    if (request.amount != null) {
      items.add(('القيمة', '${request.amount} EGP'));
    }
    if (request.rejectionReason?.trim().isNotEmpty == true) {
      items.add(('سبب الرفض', request.rejectionReason!));
    }
    return items;
  }
}

class _RequestHero extends StatelessWidget {
  final RecentActivity request;

  const _RequestHero({required this.request});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 220;

        return Container(
          padding: EdgeInsets.fromLTRB(20, isCompact ? 72 : 78, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0B1734),
                const Color(0xFF12306A),
                request.statusColor.withValues(alpha: 0.92),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: isCompact ? 48 : 54,
                height: isCompact ? 48 : 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _RequestDetailsScreenState._getTypeIcon(request.type),
                  color: Colors.white,
                  size: isCompact ? 22 : 24,
                ),
              ),
              SizedBox(height: isCompact ? 10 : 12),
              Text(
                request.title,
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
                  _HeroTag(label: request.typeText),
                  _HeroTag(label: request.statusText),
                  _HeroTag(label: _RequestDetailsScreenState._formatDateTime(request.date)),
                ],
              ),
            ],
          ),
        );
      },
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

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
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

  const _DetailMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.of(context).size.width - 58;
    final cardWidth = availableWidth > 360 ? availableWidth / 2 : availableWidth;

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
            Icon(icon, color: AppColors.primary, size: 18),
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
