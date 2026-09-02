import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../shared/widgets/searchable_dropdown_field.dart';
import 'cubit/payslip_cubit.dart';
import 'cubit/payslip_state.dart';
import 'models/payslip.dart';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PayslipCubit>().loadPayslip();
      }
    });
  }

  Future<void> _openPdf() async {
    final cubit = context.read<PayslipCubit>();

    try {
      final bytes = await cubit.downloadPdf();
      if (bytes.isEmpty) {
        throw Exception('لم يتم العثور على ملف PDF لهذه الفترة.');
      }

      final directory = await getTemporaryDirectory();
      final fileName =
          'payslip_${cubit.state.selectedYear}_${cubit.state.selectedMonth.toString().padLeft(2, '0')}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFile.open(file.path);
      if (!mounted) return;

      if (result.type == ResultType.done) {
        CustomToast.showSuccess('تم فتح ملف بيان المرتب.');
      } else {
        CustomToast.showInfo(
          result.message.isNotEmpty
              ? result.message
              : 'تم تجهيز الملف، لكن تعذر فتحه تلقائيًا.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PayslipCubit, PayslipState>(
          builder: (context, state) {
            final isFuturePeriod = state.isFuturePeriod;
            final isPreHirePeriod = state.isPreHirePeriod;
            final isLoading =
                state.loadStatus == PayslipLoadStatus.loading &&
                state.payslip == null;

            return RefreshIndicator(
              onRefresh: context.read<PayslipCubit>().refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: [
                          _PayslipHeroCard(state: state, onOpenPdf: _openPdf),
                          const SizedBox(height: 14),
                          _PayslipFilterCard(
                            selectedMonth: state.selectedMonth,
                            selectedYear: state.selectedYear,
                            onMonthChanged: (month) {
                              context.read<PayslipCubit>().selectMonth(month);
                              context.read<PayslipCubit>().loadPayslip();
                            },
                            onYearChanged: (year) {
                              context.read<PayslipCubit>().selectYear(year);
                              context.read<PayslipCubit>().loadPayslip();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (isFuturePeriod && state.payslip == null)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.schedule_outlined,
                        title: 'بيان المرتب لم يصدر بعد',
                        message:
                            'الشهر المختار ما زال مستقبليًا، لذلك لن يتم عرض بيانات بيان المرتب قبل صدوره.',
                        iconColor: AppColors.warning,
                      ),
                    )
                  else if (isPreHirePeriod && state.payslip != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.person_off_outlined,
                        title: 'لم يكن الموظف متواجد',
                        message:
                            'لم يكن الموظف متواجد في العمل خلال هذه الفترة. ${state.hireDate != null ? "تاريخ التعيين: ${_formatDate(state.hireDate!)}" : ""}',
                        iconColor: AppColors.info,
                      ),
                    )
                  else if (state.payslip != null &&
                      state.payslip!.isEmployeeNotActive)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.person_off_outlined,
                        title: 'الموظف غير متواجد',
                        message: state.payslip!.employeeStatusNote!,
                        iconColor: AppColors.info,
                      ),
                    )
                  else if (state.loadStatus == PayslipLoadStatus.failure)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorStateWidget(
                        title: 'تعذر تحميل بيان المرتب',
                        error: state.errorMessage ?? 'حدث خطأ غير متوقع.',
                        buttonLabel: 'إعادة المحاولة',
                        onRetry: context.read<PayslipCubit>().loadPayslip,
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else if (state.payslip == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'لا يوجد بيان مرتب متاح',
                        message:
                            'اختر شهرًا مختلفًا أو أعد المحاولة لاحقًا إذا لم يتم إصدار البيان بعد.',
                        buttonLabel: 'إعادة التحميل',
                        onButtonPressed: context
                            .read<PayslipCubit>()
                            .loadPayslip,
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
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _SummaryStrip(payslip: state.payslip!),
                          const SizedBox(height: 14),
                          _NetSalaryCard(payslip: state.payslip!),
                          const SizedBox(height: 14),
                          _DatesSection(payslip: state.payslip!),
                          const SizedBox(height: 14),
                          _WorkingHoursDetailsSection(
                            details: state.payslip!.salaryDetails,
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'الملخص المالي',
                            subtitle:
                                'أهم أرقام المرتب لهذا الشهر في مكان واحد.',
                            children: [
                              _MoneyRow(
                                label: 'إجمالي المرتب',
                                value: state.payslip!.salaryDetails.grossSalary,
                              ),
                              _MoneyRow(
                                label: 'إجمالي الاستحقاقات',
                                value:
                                    state.payslip!.salaryDetails.totalEarnings,
                                positive: true,
                              ),
                              _MoneyRow(
                                label: 'إجمالي الخصومات',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .total,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'صافي المرتب',
                                value: state.payslip!.salaryDetails.netSalary,
                                emphasize: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'الاستحقاقات والإضافات',
                            subtitle: 'بدلات ومبالغ إضافية دخلت ضمن البيان.',
                            children: [
                              _MoneyRow(
                                label: 'بدل سكن',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .allowances
                                    .housing,
                              ),
                              _MoneyRow(
                                label: 'بدل وجبات',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .allowances
                                    .meal,
                              ),
                              _MoneyRow(
                                label: 'بدل انتقالات',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .allowances
                                    .transportation,
                              ),
                              _MoneyRow(
                                label: 'التأمين (بدلات)',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .allowances
                                    .insurance,
                              ),
                              _MoneyRow(
                                label: 'إضافي',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .allowances
                                    .additional,
                                positive: true,
                              ),
                              _MoneyRow(
                                label: 'بدلات أخرى',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .allowances
                                    .other,
                              ),
                              _MoneyRow(
                                label: 'مكافآت',
                                value: state.payslip!.salaryDetails.bonusAmount,
                              ),
                              _MoneyRow(
                                label: 'أجر إضافي',
                                value: state.payslip!.salaryDetails.overtimePay,
                              ),
                              _MoneyRow(
                                label: 'تسويات إضافة',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .settlementAdditions,
                                positive: true,
                              ),
                              _MoneyRow(
                                label: 'قيمة التسوية',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .settlementAmount,
                              ),
                              _MoneyRow(
                                label: 'إجمالي البدلات',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .allowances
                                    .total,
                                positive: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'الخصومات',
                            subtitle:
                                'تفاصيل التأخير والغياب والجزاءات والضرائب.',
                            footer:
                                state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .penaltyDetails
                                    .isEmpty
                                ? null
                                : _PenaltyDetails(
                                    details: state
                                        .payslip!
                                        .salaryDetails
                                        .deductions
                                        .penaltyDetails,
                                  ),
                            children: [
                              _MoneyRow(
                                label: 'خصم التأخير',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .lateAmount,
                                negative: true,
                                trailing:
                                    '${_formatNumber(state.payslip!.salaryDetails.deductions.lateHours)} ساعة',
                              ),
                              _MoneyRow(
                                label: 'خصم الغياب',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .absenceAmount,
                                negative: true,
                                trailing:
                                    '${_formatNumber(state.payslip!.salaryDetails.deductions.absenceDays)} يوم',
                              ),
                              _MoneyRow(
                                label: 'جزاءات',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .penaltiesAmount,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'سلف',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .advancesAmount,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'تأمين صحي',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .healthInsuranceAmount,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'تسويات خصم',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .deductions
                                    .settlementDeductions,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'الضرائب',
                                value: state.payslip!.salaryDetails.taxAmount,
                                negative: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'التأمينات',
                            subtitle:
                                'القيم المرتبطة بالتأمين الاجتماعي والصحي إن وجدت.',
                            children: [
                              _MoneyRow(
                                label: 'تأمين اجتماعي',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .insurance
                                    .social,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'تأمين صحي',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .insurance
                                    .health,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'إجمالي المخصوم',
                                value: state
                                    .payslip!
                                    .salaryDetails
                                    .insurance
                                    .totalDeducted,
                                negative: true,
                              ),
                              _MoneyRow(
                                label: 'مرتب التأمين',
                                value:
                                    state
                                        .payslip!
                                        .salaryDetails
                                        .insuranceSalary ??
                                    state
                                        .payslip!
                                        .salaryDetails
                                        .insurance
                                        .insuranceSalary,
                              ),
                            ],
                          ),
                          if (state
                                  .payslip!
                                  .salaryDetails
                                  .settlementDetails
                                  .isNotEmpty ||
                              state
                                  .payslip!
                                  .salaryDetails
                                  .deductions
                                  .penaltyDetails
                                  .isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _DetailsListsSection(
                              details: state.payslip!.salaryDetails,
                            ),
                          ],
                        ]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PayslipHeroCard extends StatelessWidget {
  final PayslipState state;
  final VoidCallback onOpenPdf;

  const _PayslipHeroCard({required this.state, required this.onOpenPdf});

  @override
  Widget build(BuildContext context) {
    final isFuturePeriod = state.isFuturePeriod;
    final payslip = state.payslip;

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
                      'بيان المرتب',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'راجع صافي المرتب والاستحقاقات والخصومات وافتح نسخة PDF من نفس الشاشة.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
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
                  Icons.receipt_long_rounded,
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
              _HeroChip(
                label:
                    '${_monthName(state.selectedMonth)} ${state.selectedYear}',
              ),
              if (isFuturePeriod) const _HeroChip(label: 'شهر مستقبلي'),
              if (payslip != null)
                _HeroChip(
                  label:
                      'صافي ${_formatMoney(payslip.salaryDetails.netSalary)}',
                ),
              if (payslip?.issuedAt != null)
                _HeroChip(
                  label:
                      'إصدار ${DateFormat('dd/MM/yyyy').format(payslip!.issuedAt!)}',
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                state.pdfStatus == PayslipPdfStatus.downloading ||
                    isFuturePeriod
                ? null
                : onOpenPdf,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            icon: state.pdfStatus == PayslipPdfStatus.downloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              state.pdfStatus == PayslipPdfStatus.downloading
                  ? 'جاري تجهيز الملف'
                  : isFuturePeriod
                  ? 'غير متاح لهذا الشهر'
                  : 'فتح نسخة PDF',
            ),
          ),
        ],
      ),
    );
  }
}

class _PayslipFilterCard extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const _PayslipFilterCard({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(5, (index) => currentYear - index);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختيار الفترة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختر الشهر والسنة لعرض بيان مرتب محدد أو فتح ملف الـ PDF الخاص به.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DropdownField<int>(
                  value: selectedMonth,
                  label: 'الشهر',
                  searchHintText: 'ابحث عن شهر',
                  items: List<int>.generate(12, (index) => index + 1),
                  itemLabel: _monthName,
                  onChanged: onMonthChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField<int>(
                  value: selectedYear,
                  label: 'السنة',
                  searchHintText: 'ابحث عن سنة',
                  items: years,
                  itemLabel: (year) => year.toString(),
                  onChanged: onYearChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final String label;
  final String searchHintText;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  const _DropdownField({
    required this.value,
    required this.label,
    required this.searchHintText,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SearchableDropdownField<T>(
      value: value,
      labelText: label,
      searchHintText: searchHintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      items: items
          .map(
            (item) =>
                SearchableDropdownItem<T?>(value: item, label: itemLabel(item)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final Payslip payslip;

  const _SummaryStrip({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'أيام العمل',
        value: payslip.actualWorkingDays.toString(),
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF246BFD),
      ),
      _SummaryItem(
        label: 'ساعات العمل',
        value: _formatNumber(payslip.salaryDetails.hoursWorked),
        icon: Icons.timer_outlined,
        color: const Color(0xFF0F9D58),
      ),
      _SummaryItem(
        label: 'ساعات إضافية',
        value: _formatNumber(payslip.salaryDetails.overtimeHours),
        icon: Icons.more_time_rounded,
        color: const Color(0xFFF2994A),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) => _SummaryCard(item: item)).toList(),
    );
  }
}

class _NetSalaryCard extends StatelessWidget {
  final Payslip payslip;

  const _NetSalaryCard({required this.payslip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'صافي المرتب',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(payslip.salaryDetails.netSalary),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _employeeMetaLine(payslip),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DatesSection extends StatelessWidget {
  final Payslip payslip;

  const _DatesSection({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final lateDates = payslip.salaryDetails.lateDates;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pastAbsences = <String>[];
    final futureAbsences = <String>[];

    for (final dateStr in payslip.salaryDetails.absenceDates) {
      try {
        final date = DateTime.parse(dateStr);
        if (date.isAfter(today)) {
          futureAbsences.add(dateStr);
        } else {
          pastAbsences.add(dateStr);
        }
      } catch (_) {
        pastAbsences.add(dateStr);
      }
    }

    return _SectionCard(
      title: 'أيام التأخير والغياب',
      subtitle: 'تفاصيل الأيام التي تم تسجيلها كتأخير أو غياب خلال الشهر.',
      children: [
        _DateListBlock(
          title: 'أيام التأخير',
          dates: lateDates,
          emptyLabel: 'لا يوجد أيام تأخير مسجلة',
          chipColor: AppColors.warning,
        ),
        if (payslip.salaryDetails.incompleteDates.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DateListBlock(
            title: 'أيام الحضور الناقص',
            dates: payslip.salaryDetails.incompleteDates,
            emptyLabel: 'لا يوجد أيام حضور ناقص',
            chipColor: AppColors.info,
          ),
        ],
        const SizedBox(height: 12),
        _DateListBlock(
          title: 'أيام الغياب',
          dates: pastAbsences,
          emptyLabel: 'لا يوجد أيام غياب مسجلة',
          chipColor: AppColors.error,
        ),
        if (futureAbsences.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DateListBlock(
            title: 'أيام لسة هتيجي',
            dates: futureAbsences,
            emptyLabel: '',
            chipColor: AppColors.info,
          ),
        ],
      ],
    );
  }
}

class _WorkingHoursDetailsSection extends StatelessWidget {
  final SalaryDetails details;

  const _WorkingHoursDetailsSection({required this.details});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'تفاصيل الحضور والعمل',
      subtitle: 'ساعات العمل والشيفتات والأيام المؤثرة على حساب المرتب.',
      children: [
        _InfoRow('أيام العمل المدفوعة', '${details.paidShiftDays} يوم'),
        _InfoRow('إجمالي أيام العمل', '${details.totalWorkingDays} يوم'),
        _InfoRow('ساعات العمل', '${_formatNumber(details.hoursWorked)} ساعة'),
        _InfoRow(
          'الساعات الإضافية',
          '${_formatNumber(details.overtimeHours)} ساعة',
        ),
        _MoneyRow(label: 'أجر الساعات الإضافية', value: details.overtimePay),
        if (details.overtimeDates.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DateListBlock(
            title: 'أيام العمل الإضافي',
            dates: details.overtimeDates,
            emptyLabel: '',
            chipColor: AppColors.success,
          ),
        ],
        if (details.shiftRate != null && details.shiftRate != 0) ...[
          const Divider(height: 24),
          _MoneyRow(label: 'أجر يوم الشيفت', value: details.shiftRate!),
        ],
        if (details.shiftMonthlyRequiredWorkingDays != 0 ||
            details.shiftMonthlyRequiredHours != 0 ||
            details.shiftMonthlyActualHours != 0 ||
            details.shiftMonthlyMissingHours != 0 ||
            details.shiftMonthlyDeductionDays != 0 ||
            details.shiftMonthlyAbsentDays != 0 ||
            details.shiftMonthlyHourDeficitDays != 0) ...[
          const Divider(height: 24),
          _InfoRow(
            'أيام العمل المطلوبة',
            '${details.shiftMonthlyRequiredWorkingDays} يوم',
          ),
          _InfoRow(
            'الساعات المطلوبة',
            '${_formatNumber(details.shiftMonthlyRequiredHours)} ساعة',
          ),
          _InfoRow(
            'الساعات الفعلية',
            '${_formatNumber(details.shiftMonthlyActualHours)} ساعة',
          ),
          _InfoRow(
            'الساعات الناقصة',
            '${_formatNumber(details.shiftMonthlyMissingHours)} ساعة',
            valueColor: AppColors.error,
          ),
          _InfoRow(
            'أيام خصم الشيفت',
            '${details.shiftMonthlyDeductionDays} يوم',
            valueColor: AppColors.error,
          ),
          _InfoRow(
            'أيام غياب الشيفت',
            '${details.shiftMonthlyAbsentDays} يوم',
            valueColor: AppColors.error,
          ),
          _InfoRow(
            'أيام عجز الساعات',
            '${details.shiftMonthlyHourDeficitDays} يوم',
            valueColor: AppColors.error,
          ),
        ],
      ],
    );
  }
}

class _DetailsListsSection extends StatelessWidget {
  final SalaryDetails details;

  const _DetailsListsSection({required this.details});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'تفاصيل إضافية',
      subtitle: 'بنود التسويات والجزاءات كما وردت من نظام الرواتب.',
      children: [
        if (details.settlementDetails.isNotEmpty)
          _TextDetailsBlock(
            title: 'تفاصيل التسويات',
            details: details.settlementDetails,
          ),
        if (details.settlementDetails.isNotEmpty &&
            details.deductions.penaltyDetails.isNotEmpty)
          const SizedBox(height: 14),
        if (details.deductions.penaltyDetails.isNotEmpty)
          _PenaltyDetails(details: details.deductions.penaltyDetails),
      ],
    );
  }
}

class _DateListBlock extends StatelessWidget {
  final String title;
  final List<String> dates;
  final String emptyLabel;
  final Color chipColor;

  const _DateListBlock({
    required this.title,
    required this.dates,
    required this.emptyLabel,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = dates
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();

    normalized.sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${normalized.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: chipColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (normalized.isEmpty)
          Text(
            emptyLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: normalized.map((date) {
              final formatted = _tryFormatDate(date);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: chipColor.withValues(alpha: 0.18)),
                ),
                child: Text(
                  formatted,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _TextDetailsBlock extends StatelessWidget {
  final String title;
  final List<String> details;

  const _TextDetailsBlock({required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    final values = details
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            'لا توجد تفاصيل',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          )
        else
          ...values.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _tryFormatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('dd/MM/yyyy').format(parsed);
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...children,
          ?footer,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool positive;
  final bool negative;
  final bool emphasize;
  final String? trailing;

  const _MoneyRow({
    required this.label,
    required this.value,
    this.positive = false,
    this.negative = false,
    this.emphasize = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = emphasize
        ? AppColors.primary
        : negative
        ? AppColors.error
        : positive
        ? AppColors.success
        : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    trailing!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatMoney(value),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyDetails extends StatelessWidget {
  final List<PayslipPenaltyDetail> details;

  const _PenaltyDetails({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'تفاصيل الجزاءات',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...details.map((detail) {
          final mainValue = detail.isDayPenalty
              ? '${_formatNumber(detail.days)} يوم'
              : _formatMoney(detail.amount);
          final date = detail.penaltyDate == null
              ? null
              : _tryFormatDate(detail.penaltyDate!);
          final reason = detail.reason ?? detail.description;
          final title = detail.isDayPenalty
              ? 'جزاء أيام'
              : detail.isAmountPenalty
              ? 'جزاء مبلغ'
              : 'جزاء';

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 6, color: AppColors.warning),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$title: $mainValue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (reason != null && reason.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          reason,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      if (date != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!detail.isDayPenalty && detail.amount == 0)
                  const SizedBox.shrink()
                else if (detail.isDayPenalty && detail.amount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatMoney(detail.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final formatter = NumberFormat.currency(
    locale: 'en',
    symbol: 'EGP ',
    decimalDigits: value % 1 == 0 ? 0 : 2,
  );
  return formatter.format(value);
}

String _formatNumber(double value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

String _monthName(int month) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return months[month - 1];
}

String _employeeMetaLine(Payslip payslip) {
  final parts = <String>[
    if (payslip.fullNameAr.trim().isNotEmpty) payslip.fullNameAr,
    if ((payslip.jobTitle ?? '').trim().isNotEmpty) payslip.jobTitle!,
    if ((payslip.employmentMode ?? '').trim().isNotEmpty)
      payslip.employmentMode!,
    if ((payslip.departmentName ?? '').trim().isNotEmpty)
      payslip.departmentName!,
  ];
  return parts.join(' • ');
}
