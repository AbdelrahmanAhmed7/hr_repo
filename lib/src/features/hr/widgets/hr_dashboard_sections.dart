import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/attendance_status.dart';
import '../models/employee.dart';
import '../models/hr_home_response.dart';

class HrDashboardHero extends StatelessWidget {
  final HrHomeResponse? data;
  final AttendanceInfo attendanceInfo;
  final bool isLoading;
  final VoidCallback? onCheckInOut;

  const HrDashboardHero({
    super.key,
    required this.data,
    required this.attendanceInfo,
    required this.isLoading,
    required this.onCheckInOut,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = attendanceInfo.status == AttendanceStatus.checkedIn;
    final isCheckedOut = attendanceInfo.status == AttendanceStatus.checkedOut;
    final departmentName = data?.departmentName ?? 'الموارد البشرية';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizing.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            departmentName,
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'لوحة تشغيل الموارد البشرية',
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (isLoading || isCheckedOut) ? null : onCheckInOut,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isCheckedOut
                                ? Colors.grey
                                : (isCheckedIn
                                    ? AppColors.error
                                    : AppColors.success))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : Icon(
                              isCheckedOut
                                  ? Icons.lock_rounded
                                  : (isCheckedIn
                                      ? Icons.logout_rounded
                                      : Icons.fingerprint_rounded),
                              color: isCheckedOut
                                  ? Colors.grey.shade700
                                  : (isCheckedIn
                                      ? AppColors.error
                                      : AppColors.success),
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCheckedOut
                                ? 'اليوم مكتمل'
                                : (isCheckedIn
                                    ? 'تسجيل الانصراف'
                                    : 'تسجيل الحضور'),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            attendanceInfo.statusText,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HrOperationsOverview extends StatelessWidget {
  final HrHomeResponse? data;

  const HrOperationsOverview({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final employees = data?.statistics.totalEmployees ?? 0;
    final pending = data?.pendingRequests.length ?? 0;
    final accepted = data?.acceptedRequests.length ?? 0;
    final rejected = data?.rejectedRequests.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ملخص التشغيل', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HrKpiCard(
                  title: 'الموظفون',
                  value: '$employees',
                  color: AppColors.primary,
                  tint: AppColors.primaryTint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HrKpiCard(
                  title: 'معلق',
                  value: '$pending',
                  color: AppColors.warning,
                  tint: AppColors.warning.withValues(alpha: 0.14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HrKpiCard(
                  title: 'مقبول',
                  value: '$accepted',
                  color: AppColors.success,
                  tint: AppColors.successTint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HrKpiCard(
                  title: 'مرفوض',
                  value: '$rejected',
                  color: AppColors.error,
                  tint: AppColors.errorTint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HrPrimaryActions extends StatelessWidget {
  final VoidCallback? onViewEmployees;
  final VoidCallback? onViewDepartments;
  final VoidCallback? onViewOrganization;
  final VoidCallback? onViewMissions;
  final VoidCallback? onViewAllRequests;
  final VoidCallback? onViewHolidays;

  const HrPrimaryActions({
    super.key,
    this.onViewEmployees,
    this.onViewDepartments,
    this.onViewOrganization,
    this.onViewMissions,
    this.onViewAllRequests,
    this.onViewHolidays,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('أدوات العمل', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.28,
            children: [
              _HrActionCard(
                icon: Icons.people_outline_rounded,
                title: 'إدارة الموظفين',
                subtitle: 'إضافة ومتابعة الملفات',
                color: AppColors.primary,
                onTap: onViewEmployees,
              ),
              _HrActionCard(
                icon: Icons.apartment_rounded,
                title: 'الأقسام',
                subtitle: 'عرض الأقسام وتوزيع الموظفين',
                color: AppColors.success,
                onTap: onViewDepartments,
              ),
              _HrActionCard(
                icon: Icons.account_tree_outlined,
                title: 'الهيكل التنظيمي',
                subtitle: 'استعراض الأقسام والفرق',
                color: const Color(0xFF0EA5E9),
                onTap: onViewOrganization,
              ),
              _HrActionCard(
                icon: Icons.timeline_outlined,
                title: 'سجل الأنشطة',
                subtitle: 'مراجعة المأموريات والطلبات',
                color: AppColors.warning,
                onTap: onViewMissions,
              ),
              _HrActionCard(
                icon: Icons.library_books_outlined,
                title: 'كل الطلبات',
                subtitle: 'إجازات وأذونات ومأموريات وأوفرتايم',
                color: const Color(0xFF7C3AED),
                onTap: onViewAllRequests,
              ),
              _HrActionCard(
                icon: Icons.celebration_outlined,
                title: 'الإجازات العامة',
                subtitle: 'عرض الإجازات الرسمية',
                color: const Color(0xFF8B5CF6),
                onTap: onViewHolidays,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HrAttentionQueue extends StatelessWidget {
  final HrHomeResponse? data;

  const HrAttentionQueue({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final pending = data?.pendingRequests.length ?? 0;
    final allRequests = data?.allRequests.length ?? 0;

    final items = [
      _QueueItemData(
        icon: Icons.pending_actions_outlined,
        title: 'طلبات تحتاج متابعة',
        subtitle: pending == 0
            ? 'لا توجد طلبات عاجلة الآن'
            : '$pending طلب في انتظار إجراء',
        color: AppColors.warning,
      ),
      _QueueItemData(
        icon: Icons.approval_outlined,
        title: 'إجمالي الطلبات',
        subtitle: allRequests == 0
            ? 'لم يتم تسجيل طلبات بعد'
            : '$allRequests طلبًا في السجل',
        color: AppColors.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تحتاج متابعة الآن', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QueueTile(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class HrDepartmentSnapshot extends StatelessWidget {
  final HrHomeResponse? data;

  const HrDepartmentSnapshot({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<DepartmentEmployeeCount> departments =
        data?.statistics.employeesPerDepartment ??
            const <DepartmentEmployeeCount>[];
    if (departments.isEmpty) return const SizedBox.shrink();

    final visibleDepartments = departments.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('توزيع الموظفين', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          ...visibleDepartments.map(
            (department) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            department.departmentName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${department.employeeCount} موظف',
                            style: AppTextStyles.bodyMedium,
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
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${department.employeeCount}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HrEmployeePulse extends StatelessWidget {
  final List<Employee> employees;
  final VoidCallback? onViewEmployees;

  const HrEmployeePulse({
    super.key,
    required this.employees,
    this.onViewEmployees,
  });

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) return const SizedBox.shrink();

    final visibleEmployees = employees.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الموظفون في المتابعة',
                  style: AppTextStyles.titleLarge,
                ),
              ),
              if (onViewEmployees != null)
                TextButton(
                  onPressed: onViewEmployees,
                  child: const Text('عرض الموظفين'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...visibleEmployees.map(
            (employee) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: employee.profileImageUrl != null &&
                              employee.profileImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                employee.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _EmployeeInitials(employee: employee),
                              ),
                            )
                          : _EmployeeInitials(employee: employee),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.fullName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employee.position ??
                                employee.role ??
                                'بدون مسمى وظيفي',
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.department ?? employee.email,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        color: (employee.isActive ?? false)
                            ? AppColors.successTint
                            : AppColors.errorTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        (employee.isActive ?? false) ? 'نشط' : 'غير نشط',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: (employee.isActive ?? false)
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeInitials extends StatelessWidget {
  final Employee employee;

  const _EmployeeInitials({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        employee.initials,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HrKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color tint;

  const _HrKpiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(color: color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HrActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _HrActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QueueItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _QueueTile extends StatelessWidget {
  final _QueueItemData item;

  const _QueueTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


