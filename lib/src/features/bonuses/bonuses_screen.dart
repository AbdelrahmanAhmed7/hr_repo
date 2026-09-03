import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediconsult_internal/src/core/theme/app_colors.dart';
import 'package:mediconsult_internal/src/core/theme/app_text_styles.dart';
import 'package:mediconsult_internal/src/features/bonuses/cubit/bonuses_cubit.dart';
import 'package:mediconsult_internal/src/features/bonuses/cubit/bonuses_state.dart';
import 'package:mediconsult_internal/src/features/bonuses/models/employee_bonus.dart';
import 'package:mediconsult_internal/src/features/hr/models/employee.dart';
import 'package:mediconsult_internal/src/features/hr/repository/employees_repository.dart';
import 'package:mediconsult_internal/src/shared/components/custom_toast.dart';
import 'package:mediconsult_internal/src/shared/widgets/app_back_button.dart';
import 'package:mediconsult_internal/src/shared/widgets/searchable_dropdown_field.dart';

import '../../core/services/service_locator.dart';

class BonusesScreen extends StatefulWidget {
  const BonusesScreen({super.key});

  @override
  State<BonusesScreen> createState() => _BonusesScreenState();
}

class _BonusesScreenState extends State<BonusesScreen> {
  List<Employee> _employees = const [];
  bool _employeesLoading = true;

  @override
  void initState() {
    super.initState();
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
        leading: const AppBackButton(),
        backgroundColor: AppColors.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'المكافآت',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: BlocConsumer<BonusesCubit, BonusesState>(
        listenWhen: (prev, curr) =>
            prev.isSaving != curr.isSaving || prev.saveError != curr.saveError,
        listener: (context, state) {
          if (state.saveError != null) {
            CustomToast.showError(state.saveError!);
            context.read<BonusesCubit>().clearSaveState();
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
                    _buildBonusesSection(state),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(BonusesState state) {
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

  Widget _buildEmployeeDropdown(BonusesState state) {
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
        context.read<BonusesCubit>().selectEmployee(emp.id, emp.fullName);
      },
    );
  }

  Widget _buildBonusesSection(BonusesState state) {
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
                Icons.workspace_premium_rounded,
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
                    'المكافآت',
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
                    '${state.bonuses.length} مكافأة',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openBonusDialog(context, state),
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
          BonusesStatus.loading => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          BonusesStatus.failure => _buildErrorBox(state.error),
          _ =>
            state.bonuses.isEmpty ? const _EmptyList() : _buildBonusList(state),
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
            onPressed: () => context.read<BonusesCubit>().loadBonuses(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusList(BonusesState state) {
    return Column(
      children: [
        for (final b in state.bonuses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BonusCard(
              bonus: b,
              onEdit: () => _openBonusDialog(context, state, bonus: b),
            ),
          ),
      ],
    );
  }

  void _openBonusDialog(
    BuildContext context,
    BonusesState state, {
    EmployeeBonus? bonus,
  }) {
    final cubit = context.read<BonusesCubit>();
    cubit.clearSaveState();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BonusDialog(
        editing: bonus,
        onSave: (amount, date, reason) async {
          if (bonus == null) {
            return cubit.saveBonus(
              amount: amount,
              bonusDate: date,
              reason: reason,
            );
          }
          return cubit.saveBonus(
            id: bonus.id,
            amount: amount,
            bonusDate: date,
            reason: reason,
          );
        },
      ),
    );
  }
}

class _BonusCard extends StatelessWidget {
  final EmployeeBonus bonus;
  final VoidCallback onEdit;

  const _BonusCard({required this.bonus, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dateText = _dateText(bonus.bonusDate);
    final reason = bonus.reason.isEmpty ? 'مكافأة' : bonus.reason;

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
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${bonus.amount.toStringAsFixed(0)} ج.م • $dateText',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
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
          Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.textTertiary,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'لا توجد مكافآت لهذا الموظف',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Add / edit dialog ─────────────────────────────────────────────────────

class _BonusDialog extends StatefulWidget {
  final EmployeeBonus? editing;
  final Future<bool> Function(double amount, String date, String reason) onSave;

  const _BonusDialog({required this.editing, required this.onSave});

  @override
  State<_BonusDialog> createState() => _BonusDialogState();
}

class _BonusDialogState extends State<_BonusDialog> {
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _amountController = TextEditingController(
      text: editing != null ? editing.amount.toStringAsFixed(0) : '',
    );
    _reasonController = TextEditingController(text: editing?.reason ?? '');
    _date = editing?.bonusDate ?? DateTime.now();
  }

  @override
  void dispose() {
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
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final reason = _reasonController.text.trim();

    if (amount <= 0) {
      CustomToast.showError('أدخل المبلغ');
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSave(amount, _fmtDate(_date), reason);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      CustomToast.showSuccess(
        widget.editing == null ? 'تمت إضافة المكافأة' : 'تم تعديل المكافأة',
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
              widget.editing == null ? 'إضافة مكافأة' : 'تعديل المكافأة',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('المبلغ (ج.م)'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration('مثال: 500'),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('تاريخ المكافأة'),
            const SizedBox(height: 8),
            _buildDateField(),
            const SizedBox(height: 16),
            const _FieldLabel('السبب'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: _inputDecoration('مثال: أداء متميز'),
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
                        widget.editing == null ? 'حفظ المكافأة' : 'حفظ التعديل',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
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
