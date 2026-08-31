import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/skeleton/skeleton_list_item.dart';
import 'cubit/department_requests_cubit.dart';
import 'cubit/department_requests_state.dart';
import 'models/department_requests_response.dart';

const _kMonths = <int?, String>{
  null: 'كل الشهور',
  1: 'يناير',
  2: 'فبراير',
  3: 'مارس',
  4: 'أبريل',
  5: 'مايو',
  6: 'يونيو',
  7: 'يوليو',
  8: 'أغسطس',
  9: 'سبتمبر',
  10: 'أكتوبر',
  11: 'نوفمبر',
  12: 'ديسمبر',
};

class DepartmentRequestsScreen extends StatelessWidget {
  const DepartmentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: BlocConsumer<DepartmentRequestsCubit, DepartmentRequestsState>(
        listener: (context, state) {
          if (state.status == DepartmentRequestsStatus.error &&
              state.departments.isEmpty &&
              state.errorMessage != null) {
            // Error is rendered inline in body.
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () =>
                context.read<DepartmentRequestsCubit>().refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                _buildBody(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DepartmentRequestsState state) {
    switch (state.status) {
      case DepartmentRequestsStatus.initial:
      case DepartmentRequestsStatus.loading:
        return const _LoadingSkeleton();
      case DepartmentRequestsStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorView(
            message: state.errorMessage ?? 'تعذر تحميل البيانات',
            onRetry: () => context.read<DepartmentRequestsCubit>().load(),
          ),
        );
      case DepartmentRequestsStatus.success:
        if (state.departments.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(),
          );
        }
        return _DepartmentsList(state: state);
    }
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DepartmentRequestsCubit>();
    final state = cubit.state;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1F46),
            Color(0xFF173C7A),
            Color(0xFF2354A5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.domain_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلبات الأقسام',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.departments.length} قسم • ${state.totalRequests} طلب',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PeriodDropdown(
                        icon: Icons.calendar_month_rounded,
                        value: state.selectedMonth == 0
                            ? null
                            : state.selectedMonth,
                        items: _kMonths.entries
                            .map((e) => DropdownMenuItem<int?>(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (m) => cubit.changeMonth(m),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PeriodDropdown<int>(
                        icon: Icons.date_range_rounded,
                        value: state.selectedYear,
                        items: List.generate(5, (i) {
                          final y = DateTime.now().year - i;
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text('$y'),
                          );
                        }),
                        onChanged: (y) {
                          if (y != null) cubit.changeYear(y);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodDropdown<T> extends StatelessWidget {
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PeriodDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item.value,
                    child: DefaultTextStyle(
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      child: item.child,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Departments list ────────────────────────────────────────────────────────

class _DepartmentsList extends StatelessWidget {
  final DepartmentRequestsState state;

  const _DepartmentsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final departments = state.departments
        .where((d) => d.employees.isNotEmpty)
        .toList();

    if (departments.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyView(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverList.separated(
        itemCount: departments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) =>
            _DepartmentCard(department: departments[i]),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final DepartmentRequestsItem department;

  const _DepartmentCard({required this.department});

  @override
  Widget build(BuildContext context) {
    final employeesWithRequests =
        department.employees.where((e) => e.hasRequests).toList();
    final hasContent = employeesWithRequests.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.white,
          child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department.departmentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasContent
                          ? '${employeesWithRequests.length} موظف لديه طلبات'
                          : '${department.employees.length} موظف',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: department.totalRequests > 0
                  ? AppColors.primaryTint
                  : AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${department.totalRequests} طلب',
              style: AppTextStyles.labelSmall.copyWith(
                color: department.totalRequests > 0
                    ? AppColors.primary
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          children: hasContent
              ? [
                  for (final employee in employeesWithRequests)
                    _EmployeeSection(employee: employee),
                ]
              : [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'لا توجد طلبات في هذا القسم خلال هذه الفترة',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
        ),
        ),
      ),
    );
  }
}

// ─── Employee section inside a department ────────────────────────────────────

class _EmployeeSection extends StatelessWidget {
  final DepartmentEmployee employee;

  const _EmployeeSection({required this.employee});

  String get _initials {
    final parts = employee.employeeName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0];
    return '؟';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Text(
                  _initials,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  employee.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${employee.totalRequests}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          // Requests
          ...[
            ...employee.leaves.map(
              (r) => _RequestRow(
                kind: DeptRequestKind.leave,
                id: r.id,
                icon: Icons.beach_access_rounded,
                accent: const Color(0xFF9C27B0),
                title: 'إجازة ${_leaveTypeLabel(r.leaveType)}',
                description:
                    'من ${r.startDate} إلى ${r.endDate}${r.reason != null ? ' • ${r.reason}' : ''}',
                statusText: r.statusText,
              ),
            ),
            ...employee.permissions.map(
              (r) => _RequestRow(
                kind: DeptRequestKind.permission,
                id: r.id,
                icon: Icons.exit_to_app_rounded,
                accent: AppColors.info,
                title: 'إذن خروج',
                description:
                    '${r.date} من ${r.startTime ?? '--'} إلى ${r.endTime ?? '--'}${r.reason != null ? ' • ${r.reason}' : ''}',
                statusText: r.statusText,
              ),
            ),
            ...employee.assignments.map(
              (r) => _RequestRow(
                kind: DeptRequestKind.assignment,
                id: r.id,
                icon: Icons.assignment_rounded,
                accent: const Color(0xFFFF9800),
                title: 'مأمورية${r.where.isNotEmpty ? ' — ${r.where}' : ''}',
                description:
                    'من ${r.startDate} إلى ${r.endDate}${r.reason != null ? ' • ${r.reason}' : ''}',
                statusText: r.statusText,
              ),
            ),
          ].map(
            (row) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: row,
            ),
          ),
        ],
      ),
    );
  }

  String _leaveTypeLabel(String leaveType) {
    switch (leaveType.toLowerCase()) {
      case 'annual':
        return 'سنوية';
      case 'casual':
        return 'عارضة';
      case 'sick':
        return 'مرضية';
      case 'unpaid':
        return 'بدون مرتب';
      default:
        return leaveType;
    }
  }
}

// ─── Single request row ──────────────────────────────────────────────────────

class _RequestRow extends StatelessWidget {
  final DeptRequestKind kind;
  final int id;
  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final String statusText;

  const _RequestRow({
    required this.kind,
    required this.id,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.statusText,
  });

  (Color, String) get _statusInfo {
    final status = parseDeptRequestStatus(statusText);
    switch (status) {
      case DeptRequestStatus.approved:
        return (AppColors.success, 'مقبول');
      case DeptRequestStatus.rejected:
        return (AppColors.error, 'مرفوض');
      case DeptRequestStatus.pending:
        return (AppColors.warning, 'معلق');
      default:
        return (AppColors.textSecondary, statusText);
    }
  }

  Future<void> _updateStatus(
    BuildContext context, {
    required int status,
    String? rejectionReason,
  }) async {
    await context.read<DepartmentRequestsCubit>().updateRequestStatus(
          kind: kind,
          id: id,
          status: status,
          rejectionReason: rejectionReason,
        );
  }

  Future<void> _reject(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (اختياري)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final reason = reasonController.text.trim();
    await _updateStatus(
      context,
      status: 3,
      rejectionReason: reason.isEmpty ? null : reason,
    );
  }

  Future<void> _changeDecision(BuildContext context) async {
    final status = parseDeptRequestStatus(statusText);
    final decided =
        status == DeptRequestStatus.approved || status == DeptRequestStatus.rejected;
    if (!decided) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'تغيير القرار',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.check_rounded, color: AppColors.success),
                title: const Text('اعتماد الطلب'),
                onTap: () => Navigator.pop(sheetContext, 'approve'),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded, color: AppColors.error),
                title: const Text('رفض الطلب'),
                onTap: () => Navigator.pop(sheetContext, 'reject'),
              ),
              ListTile(
                leading: const Icon(Icons.undo_rounded, color: AppColors.warning),
                title: const Text('إرجاع لقيد الانتظار'),
                onTap: () => Navigator.pop(sheetContext, 'pending'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.textTertiary),
                title: const Text('إلغاء'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return;
    if (choice == 'approve') {
      await _updateStatus(context, status: 2);
    } else if (choice == 'reject') {
      await _reject(context);
    } else if (choice == 'pending') {
      await _updateStatus(context, status: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _statusInfo;
    final status = parseDeptRequestStatus(statusText);
    final isPending = status == DeptRequestStatus.pending;
    final isDecided =
        status == DeptRequestStatus.approved || status == DeptRequestStatus.rejected;

    final updatingKey = context.select<DepartmentRequestsCubit, String?>(
      (cubit) => cubit.state.updatingRequestKey,
    );
    final isUpdating = updatingKey == requestKey(kind, id);
    final anyUpdating = updatingKey != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            statusLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDecided && !anyUpdating) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: isUpdating ? null : () => _changeDecision(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Action buttons — pending requests only
          if (isPending && !anyUpdating) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUpdating ? null : () => _reject(context),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUpdating ? null : () => _updateStatus(context, status: 2),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('قبول'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: AppTextStyles.labelMedium,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isUpdating) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverList.separated(
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => SkeletonListItem(height: 90),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.errorTint,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد أقسام أو طلبات',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'جرّب تغيير الشهر أو السنة',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
