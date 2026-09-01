import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'package:mediconsult_internal/src/core/theme/app_text_styles.dart';
import 'package:mediconsult_internal/src/features/home/models/employee_penalty.dart';
import 'package:mediconsult_internal/src/features/hr/models/employee.dart';
import 'package:mediconsult_internal/src/features/hr/repository/employees_repository.dart';
import 'package:mediconsult_internal/src/features/penalties/cubit/penalties_cubit.dart';
import 'package:mediconsult_internal/src/features/penalties/cubit/penalties_state.dart';
import 'package:mediconsult_internal/src/features/penalties/models/penalty_type.dart';
import 'package:mediconsult_internal/src/shared/components/custom_toast.dart';
import 'package:mediconsult_internal/src/shared/widgets/searchable_dropdown_field.dart';

import '../../core/services/service_locator.dart';

class PenaltiesScreen extends StatefulWidget {
  const PenaltiesScreen({super.key});

  @override
  State<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends State<PenaltiesScreen> {
  List<Employee> _employees = const [];
  bool _employeesLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<PenaltiesCubit>().loadTypes();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final repo = getIt<EmployeesRepository>();
      final page = await repo.getEmployees(
        pageNumber: 1,
        pageSize: 1000,
        isActive: true,
      );
      if (!mounted) return;
      setState(() {
        _employees = page.items;
        _employeesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _employeesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'إدارة الجزاءات',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: BlocConsumer<PenaltiesCubit, PenaltiesState>(
        listenWhen: (prev, curr) =>
            prev.isSaving != curr.isSaving || prev.saveError != curr.saveError,
        listener: (context, state) {
          if (state.saveError != null) {
            CustomToast.showError(state.saveError!);
            context.read<PenaltiesCubit>().clearSaveState();
          }
        },
        builder: (context, state) {
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeCard(state),
                  if (state.selectedEmployeeId != null) ...[
                    const SizedBox(height: 16),
                    _buildPenaltiesSection(state),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(PenaltiesState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر الموظف',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildEmployeeDropdown(state),
        ],
      ),
    );
  }

  Widget _buildEmployeeDropdown(PenaltiesState state) {
    if (_employeesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_employees.isEmpty) {
      return const Text(
        'تعذر تحميل الموظفين',
        style: TextStyle(fontSize: 13, color: AppColors.error),
      );
    }

    return SearchableDropdownField<String>(
      value: state.selectedEmployeeId,
      hintText: 'اختر الموظف',
      searchHintText: 'ابحث عن موظف',
      isDense: true,
      items: _employees
          .map(
            (e) =>
                SearchableDropdownItem<String?>(value: e.id, label: e.fullName),
          )
          .toList(),
      onChanged: (id) {
        if (id == null) return;
        final emp = _employees.firstWhere((e) => e.id == id);
        context.read<PenaltiesCubit>().selectEmployee(emp.id, emp.fullName);
      },
    );
  }

  Widget _buildPenaltiesSection(PenaltiesState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جزاءات ${state.selectedEmployeeName ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.penalties.length} جزاء',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openPenaltyDialog(context, state),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        switch (state.status) {
          PenaltiesStatus.loading => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          PenaltiesStatus.failure => _buildErrorBox(state.error),
          _ =>
            state.penalties.isEmpty
                ? const _EmptyList()
                : _buildPenaltyList(state),
        },
      ],
    );
  }

  Widget _buildErrorBox(String? error) {
    return Container(
      width: double.infinity,
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
          Expanded(
            child: Text(
              error ?? 'حدث خطأ',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => context.read<PenaltiesCubit>().loadPenalties(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyList(PenaltiesState state) {
    final types = state.types;
    return Column(
      children: [
        for (final p in state.penalties)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PenaltyCard(
              penalty: p,
              typeLabel: _typeLabel(types, p.penaltyType),
              onEdit: () => _openPenaltyDialog(context, state, penalty: p),
            ),
          ),
      ],
    );
  }

  String _typeLabel(List<PenaltyType> types, int value) {
    for (final t in types) {
      if (t.value == value) return t.displayName;
    }
    return value == 1 ? 'أيام' : 'مبلغ ثابت';
  }

  void _openPenaltyDialog(
    BuildContext context,
    PenaltiesState state, {
    EmployeePenalty? penalty,
  }) {
    final cubit = context.read<PenaltiesCubit>();
    cubit.clearSaveState();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PenaltyDialog(
        types: state.types,
        editing: penalty,
        onSave: (type, days, amount, date, reason) async {
          if (penalty == null) {
            return cubit.savePenalty(
              penaltyType: type,
              days: days,
              amount: amount,
              penaltyDate: date,
              reason: reason,
            );
          }
          return cubit.savePenalty(
            id: penalty.id,
            penaltyType: type,
            days: days,
            amount: amount,
            penaltyDate: date,
            reason: reason,
          );
        },
      ),
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  final EmployeePenalty penalty;
  final String typeLabel;
  final VoidCallback onEdit;

  const _PenaltyCard({
    required this.penalty,
    required this.typeLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDays = penalty.penaltyType == 1;
    final valueText = isDays
        ? '${penalty.days} يوم'
        : '${penalty.amount.toStringAsFixed(0)} ج.م';
    final dateText = _dateText(penalty.penaltyDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  penalty.reason.isEmpty ? typeLabel : penalty.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$typeLabel • $valueText • $dateText',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (penalty.isApplied)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'مطبق — ${penalty.appliedMonth}/${penalty.appliedYear}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  String _dateText(DateTime? d) {
    if (d == null) return '--';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.textTertiary, size: 40),
          SizedBox(height: 10),
          Text(
            'لا توجد جزاءات لهذا الموظف',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Add / edit dialog ─────────────────────────────────────────────────────

class _PenaltyDialog extends StatefulWidget {
  final List<PenaltyType> types;
  final EmployeePenalty? editing;
  final Future<bool> Function(
    int type,
    int days,
    double amount,
    String date,
    String reason,
  )
  onSave;

  const _PenaltyDialog({
    required this.types,
    required this.editing,
    required this.onSave,
  });

  @override
  State<_PenaltyDialog> createState() => _PenaltyDialogState();
}

class _PenaltyDialogState extends State<_PenaltyDialog> {
  late int _type;
  late TextEditingController _daysController;
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late DateTime _date;
  bool _isTimeDays = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _type = editing.penaltyType;
      _isTimeDays = editing.penaltyType == 1;
      _daysController = TextEditingController(text: editing.days.toString());
      _amountController = TextEditingController(
        text: editing.amount.toStringAsFixed(0),
      );
      _date = editing.penaltyDate ?? DateTime.now();
    } else {
      _type = widget.types.isNotEmpty ? widget.types.first.value : 1;
      _isTimeDays = _type == 1;
      _daysController = TextEditingController();
      _amountController = TextEditingController();
      _date = DateTime.now();
    }
    _reasonController = TextEditingController(text: editing?.reason ?? '');
  }

  @override
  void dispose() {
    _daysController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _save() async {
    final days = int.tryParse(_daysController.text.trim()) ?? 0;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      CustomToast.showError('السبب مطلوب');
      return;
    }
    if (_isTimeDays && days <= 0) {
      CustomToast.showError('أدخل عدد الأيام');
      return;
    }
    if (!_isTimeDays && amount <= 0) {
      CustomToast.showError('أدخل المبلغ');
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSave(
      _type,
      days,
      amount,
      _fmtDate(_date),
      reason,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      CustomToast.showSuccess(
        widget.editing == null ? 'تمت إضافة الجزاء' : 'تم تعديل الجزاء',
      );
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editing == null ? 'إضافة جزاء' : 'تعديل الجزاء',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel('نوع الجزاء'),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            if (_isTimeDays) ...[
              _FieldLabel('عدد الأيام'),
              _buildNumberField(_daysController, 'مثال: 2'),
            ] else ...[
              _FieldLabel('المبلغ (ج.م)'),
              _buildNumberField(_amountController, 'مثال: 500'),
            ],
            const SizedBox(height: 16),
            _FieldLabel('تاريخ الجزاء'),
            const SizedBox(height: 8),
            _buildDateField(),
            const SizedBox(height: 16),
            _FieldLabel('السبب'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: _inputDecoration('مثال: تقصير في العمل'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.editing == null ? 'حفظ الجزاء' : 'حفظ التعديل',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    if (widget.types.isEmpty) {
      return const Text('لا تتوفر أنواع', style: TextStyle(fontSize: 13));
    }
    return Row(
      children: widget.types
          .map(
            (t) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _type = t.value;
                  _isTimeDays = t.value == 1;
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _type == t.value
                        ? AppColors.primary
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _type == t.value
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    t.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _type == t.value
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildNumberField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _fmtDate(_date),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
