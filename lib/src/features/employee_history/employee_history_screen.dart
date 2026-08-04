import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import 'cubit/employee_history_cubit.dart';
import 'cubit/employee_history_state.dart';
import 'models/employee_history_response.dart';
import 'models/employee_history_summary.dart';

class EmployeeHistoryScreen extends StatefulWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  State<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends State<EmployeeHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EmployeeHistoryCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<EmployeeHistoryCubit, EmployeeHistoryState>(
          builder: (context, state) {
            final isInitialLoading =
                state.status == EmployeeHistoryStatus.loading &&
                state.summary == null &&
                state.historyResponse == null;

            return RefreshIndicator(
              onRefresh: context.read<EmployeeHistoryCubit>().load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _EmployeeHistoryHero(summary: state.summary),
                    ),
                  ),
                  if (isInitialLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == EmployeeHistoryStatus.failure &&
                      state.summary == null &&
                      state.historyResponse == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorStateWidget(
                        title: 'تعذر تحميل السجل الوظيفي',
                        error: state.errorMessage ?? 'حدث خطأ غير متوقع.',
                        buttonLabel: 'إعادة المحاولة',
                        onRetry: context.read<EmployeeHistoryCubit>().load,
                        icon: Icons.work_history_outlined,
                      ),
                    )
                  else ...[
                    if (state.summary != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: _SummarySection(summary: state.summary!),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _HistoryHeader(
                          totalCount: state.historyResponse?.totalCount ?? 0,
                        ),
                      ),
                    ),
                    if ((state.historyResponse?.history ?? const []).isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyStateWidget(
                          icon: Icons.work_history_outlined,
                          title: 'لا توجد تغييرات مسجلة',
                          message:
                              'عند وجود تحديثات على بياناتك الوظيفية ستظهر هنا بشكل مرتب وواضح.',
                          buttonLabel: 'تحديث',
                          onButtonPressed:
                              context.read<EmployeeHistoryCubit>().load,
                          iconColor: AppColors.primary,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          14,
                          20,
                          24 + MediaQuery.of(context).padding.bottom,
                        ),
                        sliver: SliverList.separated(
                          itemCount: state.historyResponse!.history.length,
                          itemBuilder: (context, index) {
                            final event = state.historyResponse!.history[index];
                            return _HistoryEventCard(event: event);
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmployeeHistoryHero extends StatelessWidget {
  final EmployeeHistorySummary? summary;

  const _EmployeeHistoryHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final name = _fallback(summary?.employeeName, fallback: 'السجل الوظيفي');
    final total = summary?.totalEvents ?? 0;
    final lastEventDate = summary?.lastEventDate == null
        ? 'لا توجد حركة حديثة'
        : 'آخر تحديث ${DateFormat('dd/MM/yyyy').format(summary!.lastEventDate!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1734), Color(0xFF12306A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السجل الوظيفي',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'راجع التغييرات التي تمت على بياناتك الوظيفية من نفس الشاشة.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.work_history_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(label: '$total حدث'),
              _HeroChip(label: lastEventDate),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final EmployeeHistorySummary summary;

  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'إجمالي الأحداث',
        value: summary.totalEvents.toString(),
        icon: Icons.layers_outlined,
        color: const Color(0xFF246BFD),
      ),
      _SummaryItem(
        label: 'تغييرات المسمى',
        value: summary.jobChanges.toString(),
        icon: Icons.badge_outlined,
        color: const Color(0xFF0F9D58),
      ),
      _SummaryItem(
        label: 'الترقيات',
        value: summary.promotions.toString(),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFF2994A),
      ),
      _SummaryItem(
        label: 'النقل',
        value: summary.transfers.toString(),
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF9B51E0),
      ),
      _SummaryItem(
        label: 'الرواتب',
        value: summary.salaryChanges.toString(),
        icon: Icons.payments_outlined,
        color: const Color(0xFFEB5757),
      ),
      _SummaryItem(
        label: 'العقود والإجراءات',
        value: (summary.contractEvents + summary.disciplinaryActions)
            .toString(),
        icon: Icons.description_outlined,
        color: const Color(0xFF00A3A3),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملخص سريع',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) => _SummaryCard(item: item)).toList(),
        ),
      ],
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final int totalCount;

  const _HistoryHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سجل التغييرات',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount حدث مسجل على ملفك الوظيفي',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEventCard extends StatelessWidget {
  final EmployeeHistoryEvent event;

  const _HistoryEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final eventDate = event.date == null
        ? 'غير محدد'
        : DateFormat('dd/MM/yyyy - hh:mm a').format(event.date!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fallback(event.description, fallback: 'حدث وظيفي'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eventDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _translateEventType(_fallback(event.eventType, fallback: 'Update')),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (event.changes.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...event.changes.map((change) => _ChangeRow(change: change)),
          ],
          if (_hasValue(event.reason) || _hasValue(event.doneBy) || _hasValue(event.notes)) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasValue(event.doneBy))
                    _MetaLine(label: 'تم بواسطة', value: event.doneBy),
                  if (_hasValue(event.reason))
                    _MetaLine(label: 'السبب', value: event.reason!),
                  if (_hasValue(event.notes))
                    _MetaLine(label: 'ملاحظات', value: event.notes!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final EmployeeHistoryChange change;

  const _ChangeRow({required this.change});

  String _translateProperty(String property) {
    if (property.contains('.')) {
      property = property.split('.').last;
    }
    final mappings = {
      'DepartmentId': 'القسم',
      'Department': 'القسم',
      'BranchId': 'الفرع',
      'Branch': 'الفرع',
      'TitleId': 'المسمى الوظيفي',
      'JobTitle': 'المسمى الوظيفي',
      'EmploymentStatus': 'حالة التوظيف',
      'JoinDate': 'تاريخ الالتحاق',
      'ManagerId': 'المدير المباشر',
      'BasicSalary': 'الراتب الأساسي',
      'GrossSalary': 'الراتب الإجمالي',
      'BankId': 'البنك',
      'IBAN': 'رقم الآيبان',
      'BankAccount': 'حساب البنك',
      'InsuranceNumber': 'الرقم التأميني',
      'MedicalInsuranceNumber': 'التأمين الطبي',
      'NationalId': 'الرقم القومي',
      'Gender': 'النوع',
      'BirthDate': 'تاريخ الميلاد',
      'MaritalStatus': 'الحالة الاجتماعية',
      'Address': 'العنوان',
      'Phone': 'رقم الهاتف',
      'Email': 'البريد الإلكتروني',
      'IsActive': 'حالة التفعيل',
      'IsDeleted': 'حالة الحذف',
      'CreatedDate': 'تاريخ الإنشاء',
      'ModifiedDate': 'تاريخ التعديل',
      'StartDate': 'تاريخ البداية',
      'EndDate': 'تاريخ النهاية',
      'ContractType': 'نوع العقد',
      'ContractStatus': 'حالة العقد',
      'LeaveId': 'رقم الطلب',
      'LeaveType': 'نوع الإجازة',
      'Days': 'عدد الأيام',
      'Reason': 'السبب',
      'Status': 'الحالة',
    };
    return mappings[property] ?? property;
  }

  String _translateValue(String? value) {
    if (!_hasValue(value)) return 'غير محدد';
    if (value!.toLowerCase() == 'true') return 'نعم';
    if (value.toLowerCase() == 'false') return 'لا';
    if (value.contains('T00:00:00')) {
      return value.split('T').first;
    }
    
    final valueMappings = {
      'Annual': 'سنوي',
      'Sick': 'مرضي',
      'Casual': 'عارضة',
      'Unpaid': 'بدون أجر',
      'Pending': 'قيد الانتظار',
      'Approved': 'مقبول',
      'Rejected': 'مرفوض',
    };

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        final buffer = StringBuffer();
        decoded.forEach((key, val) {
          final translatedVal = valueMappings[val?.toString()] ?? val?.toString() ?? "غير محدد";
          buffer.writeln('${_translateProperty(key.toString())}: $translatedVal');
        });
        return buffer.toString().trim();
      }
    } catch (_) {}

    return valueMappings[value] ?? value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translateProperty(_fallback(change.property, fallback: 'تفصيل التغيير')),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ValueBox(
                  label: 'من',
                  value: _translateValue(change.from),
                  color: const Color(0xFFFDECEC),
                  textColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ValueBox(
                  label: 'إلى',
                  value: _translateValue(change.to),
                  color: const Color(0xFFEAF7EE),
                  textColor: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _ValueBox({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 420 ? (width - 60) / 3 : (width - 50) / 2;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(height: 12),
            Text(
              item.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _hasValue(String? value) {
  return value != null && value.trim().isNotEmpty && value.trim() != 'null';
}

String _fallback(String? value, {required String fallback}) {
  if (!_hasValue(value)) {
    return fallback;
  }
  return value!.trim();
}

String _translateEventType(String type) {
  final mappings = {
    'Update': 'تحديث',
    'Create': 'إنشاء',
    'Delete': 'حذف',
    'Promote': 'ترقية',
    'Transfer': 'نقل',
    'SalaryChange': 'تعديل راتب',
    'StatusChange': 'تغيير حالة',
  };
  return mappings[type] ?? type;
}
