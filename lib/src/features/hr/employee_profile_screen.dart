import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/components/custom_toast.dart';
import '../../core/services/service_locator.dart';
import '../auth/cubit/auth_cubit.dart';
import 'cubit/employees_cubit.dart';
import 'models/employee.dart';
import 'salary_calculation_screen.dart';
import 'widgets/employee_profile_header.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeProfileScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Employee? _details;

  Employee get _employee => _details ?? widget.employee;

  bool get _isSuperAdmin => getIt<AuthCubit>().state.isSuperAdmin;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cubit = context.read<EmployeesCubit>();
      final employee = await cubit.getEmployeeDetails(widget.employee.id);

      if (!mounted) return;
      setState(() {
        _details = employee;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppException.from(e).message;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatAmount(double? value) {
    if (value == null) return '--';
    final text =
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return '$text ج.م';
  }

  String _workTypeLabel(int? value) {
    switch (value) {
      case 1:
        return 'داخل المكتب';
      case 2:
        return 'عن بُعد';
      case 3:
        return 'هجين';
      case 4:
        return 'دوام جزئي';
      default:
        return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: EmployeeProfileHeader(employee: _employee),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!, onRetry: _loadEmployee),
                    const SizedBox(height: 16),
                  ],
                  _buildSummaryBlock(),
                  const SizedBox(height: 20),
                  _SectionCard(
                    icon: Icons.person_rounded,
                    color: AppColors.primary,
                    title: 'المعلومات الشخصية',
                    child: _InfoGrid(
                      items: [
                        _InfoItem(Icons.badge_outlined, 'الاسم الكامل',
                            _employee.fullName),
                        _InfoItem(Icons.phone_rounded, 'رقم الهاتف',
                            _employee.phone),
                        _InfoItem(Icons.email_outlined, 'البريد الإلكتروني',
                            _employee.email),
                        _InfoItem(Icons.credit_card_rounded, 'الرقم القومي',
                            _employee.nationalId ?? '--'),
                        _InfoItem(Icons.public_rounded, 'الجنسية',
                            _employee.nationalityName ?? '--'),
                        _InfoItem(Icons.wc_rounded, 'النوع',
                            _employee.gender ?? '--'),
                        _InfoItem(Icons.cake_outlined, 'تاريخ الميلاد',
                            _formatDate(_employee.birthDate)),
                        _InfoItem(Icons.family_restroom_rounded,
                            'الحالة الاجتماعية',
                            _employee.maritalStatusName ?? '--'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.work_rounded,
                    color: AppColors.info,
                    title: 'المعلومات الوظيفية',
                    child: _InfoGrid(
                      items: [
                        _InfoItem(Icons.point_of_sale_rounded, 'كود الموظف',
                            _employee.employeeCode ?? '--'),
                        _InfoItem(Icons.business_rounded, 'القسم',
                            _employee.department ?? '--'),
                        _InfoItem(Icons.work_history_rounded, 'الوظيفة',
                            _employee.position ?? '--'),
                        _InfoItem(Icons.account_tree_rounded, 'المدير المباشر',
                            _employee.managerName ?? '--'),
                        _InfoItem(Icons.store_rounded, 'الفرع',
                            _employee.branchName ?? '--'),
                        _InfoItem(Icons.auto_awesome_rounded, 'نظام العمل',
                            _workTypeLabel(_employee.workType)),
                        _InfoItem(Icons.event_rounded, 'تاريخ التعيين',
                            _formatDate(_employee.hireDate)),
                        _InfoItem(Icons.event_available_rounded,
                            'نهاية العقد',
                            _formatDate(_employee.contractEndDate)),
                        _InfoItem(Icons.fingerprint_rounded, 'بصمة',
                            _employee.fingerprintKey ?? '--'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.location_on_rounded,
                    color: AppColors.warning,
                    title: 'العنوان والتواصل',
                    child: _InfoGrid(
                      items: [
                        _InfoItem(Icons.home_rounded, 'العنوان',
                            _employee.addressAr ?? '--'),
                        _InfoItem(Icons.location_city_rounded, 'المحافظة',
                            _employee.governorateName ?? '--'),
                        _InfoItem(Icons.map_rounded, 'المدينة',
                            _employee.cityName ?? '--'),
                        _InfoItem(Icons.phone_in_talk_rounded,
                            'هاتف الشركة',
                            _employee.companyPhoneNumber ?? '--'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.account_balance_rounded,
                    color: AppColors.success,
                    title: 'الراتب والبنك',
                    child: _InfoGrid(
                      items: [
                        _InfoItem(Icons.payments_rounded, 'الراتب الأساسي',
                            _formatAmount(_employee.grossSalary)),
                        _InfoItem(Icons.account_balance_rounded, 'اسم البنك',
                            _employee.bankInfo?.bankName ?? '--'),
                        _InfoItem(Icons.numbers_rounded, 'رقم الحساب',
                            _employee.bankInfo?.accountNumber ?? '--'),
                        _InfoItem(Icons.qr_code_rounded, 'IBAN',
                            _employee.bankInfo?.ibanNumber ?? '--'),
                        _InfoItem(Icons.bolt_rounded, 'SWIFT/BIC',
                            _employee.bankInfo?.swiftBicCode ?? '--'                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isSuperAdmin) ...[
                    _SalaryEntryCard(
                      employee: _employee,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SectionCard(
                    icon: Icons.school_rounded,
                    color: AppColors.warning,
                    title: 'التعليم',
                    child: _EducationList(
                        educations: _employee.educations),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.attach_file_rounded,
                    color: AppColors.info,
                    title: 'المرفقات',
                    child: _AttachmentList(
                        attachments: _employee.attachments),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBlock() {
    final e = _employee;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.business_rounded,
              label: 'القسم',
              value: e.department ?? '--',
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.work_outline_rounded,
              label: 'الوظيفة',
              value: e.position ?? '--',
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.circle_rounded,
              label: 'الحالة',
              value: e.isActive == true ? 'نشط' : 'غير نشط',
              color: e.isActive == true
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: color.withValues(alpha: 0.06),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i < items.length - 1)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.border,
            ),
        ],
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationList extends StatelessWidget {
  final List<EmployeeEducation> educations;

  const _EducationList({required this.educations});

  @override
  Widget build(BuildContext context) {
    if (educations.isEmpty) {
      return _EmptyInline(message: 'لا توجد سجلات تعليمية');
    }

    return Column(
      children: educations
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.universityName ?? '--',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (item.degree?.isNotEmpty == true)
                              'الشهادة: ${item.degree}',
                            if (item.finalGrade?.isNotEmpty == true)
                              'التقدير: ${item.finalGrade}',
                            if (item.graduationYear != null)
                              'السنة: ${item.graduationYear!.year}',
                          ].join(' • '),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AttachmentList extends StatelessWidget {
  final List<EmployeeAttachment> attachments;

  const _AttachmentList({required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const _EmptyInline(message: 'لا توجد مرفقات');
    }

    return Column(
      children: attachments
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insert_drive_file_outlined,
                        color: AppColors.info, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.originalFileName ?? 'مرفق',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (item.contentType?.isNotEmpty == true)
                              item.contentType!,
                            if (item.fileSize != null)
                              _formatSize(item.fileSize!),
                          ].join(' • '),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.fileUrl?.isNotEmpty == true)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: AppColors.textTertiary, size: 20),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: item.fileUrl!));
                        if (!context.mounted) return;
                        CustomToast.showSuccess('تم نسخ رابط المرفق');
                      },
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _EmptyInline extends StatelessWidget {
  final String message;

  const _EmptyInline({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.inbox_outlined, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

// ── Salary calculation entry card (super admin) ────────────────────────────

class _SalaryEntryCard extends StatelessWidget {
  final Employee employee;

  const _SalaryEntryCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          final cubit = context.read<EmployeesCubit>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: SalaryCalculationScreen(employee: employee),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حساب الراتب الشهري',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'عرض تفاصيل راتب الموظف الشهرية',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

