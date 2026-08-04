import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/public_holiday_model.dart';

class HolidayFormDialog extends StatefulWidget {
  final PublicHolidayModel? holiday;
  final Function(PublicHolidayModel) onSave;

  const HolidayFormDialog({super.key, this.holiday, required this.onSave});

  @override
  State<HolidayFormDialog> createState() => _HolidayFormDialogState();
}

class _HolidayFormDialogState extends State<HolidayFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nameArController;
  late DateTime _selectedDate;
  late int _year;
  bool _isActive = true;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final holiday = widget.holiday;
    _nameController = TextEditingController(text: holiday?.name ?? '');
    _nameArController = TextEditingController(text: holiday?.nameAr ?? '');
    _selectedDate = holiday?.date ?? DateTime.now();
    _year = holiday?.year ?? DateTime.now().year;
    _isActive = holiday?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _year = picked.year;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final holiday = PublicHolidayModel(
      id: widget.holiday?.id ?? 0,
      date: _selectedDate,
      name: _nameController.text.trim(),
      nameAr: _nameArController.text.trim(),
      isActive: _isActive,
      exceptions: widget.holiday?.exceptions ?? [],
    );

    widget.onSave(holiday);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.holiday != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'تعديل الإجازة' : 'إضافة إجازة جديدة',
        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arabic Name
                TextFormField(
                  controller: _nameArController,
                  decoration: InputDecoration(
                    labelText: 'اسم الإجازة',
                    hintText: 'مثال: عيد الفطر المبارك',
                    prefixIcon: const Icon(Icons.celebration_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم الإجازة بالعربية';
                    }
                    return null;
                  },
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),

                // English Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الوصف (بالإنجليزية)',
                    hintText: 'مثال: Eid Al-Fitr',
                    prefixIcon: const Icon(Icons.language_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الوصف بالإنجليزية';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'تاريخ الإجازة',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          _getDayName(_selectedDate),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Year
                TextFormField(
                  initialValue: '$_year',
                  decoration: InputDecoration(
                    labelText: 'السنة',
                    prefixIcon: const Icon(Icons.date_range_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _year = int.tryParse(value) ?? _year;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال السنة';
                    }
                    final year = int.tryParse(value);
                    if (year == null || year < 2020 || year > 2035) {
                      return 'يرجى إدخال سنة صحيحة بين 2020 و 2035';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active Status
                SwitchListTile(
                  title: Text(
                    'الإجازة نشطة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'يمكن إلغاء تفعيل الإجازة بدلاً من حذفها',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'حفظ التغييرات' : 'إضافة الإجازة'),
        ),
      ],
    );
  }

  String _getDayName(DateTime date) {
    final days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[date.weekday - 1];
  }
}
