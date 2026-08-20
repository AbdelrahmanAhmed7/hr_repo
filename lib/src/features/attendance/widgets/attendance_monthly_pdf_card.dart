import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_exception.dart';
import '../../../shared/components/custom_toast.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';

class AttendanceMonthlyPdfCard extends StatelessWidget {
  const AttendanceMonthlyPdfCard({super.key});

  Future<void> _download(BuildContext context) async {
    final cubit = context.read<AttendanceCubit>();
    try {
      final path = await cubit.downloadMonthlyAttendancePdf();
      if (!context.mounted) return;

      final result = await OpenFile.open(path);
      if (!context.mounted) return;

      if (result.type == ResultType.done) {
        CustomToast.showSuccess('تم فتح ملف الحضور بنجاح.');
      } else {
        CustomToast.showInfo(
          result.message.isNotEmpty
              ? result.message
              : 'تم تجهيز الملف، لكن تعذر فتحه تلقائيًا.',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      CustomToast.showError(AppException.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      buildWhen: (prev, curr) =>
          prev.pdfStatus != curr.pdfStatus ||
          prev.selectedPdfMonth != curr.selectedPdfMonth ||
          prev.selectedPdfYear != curr.selectedPdfYear,
      builder: (context, state) {
        final isDownloading =
            state.pdfStatus == AttendancePdfStatus.downloading;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقرير الحضور الشهري',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اختر الشهر والسنة ثم حمّل تقرير حضورك',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Month / Year pickers ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _CustomDropdown<int>(
                      label: 'الشهر',
                      value: state.selectedPdfMonth,
                      items: List<int>.generate(12, (i) => i + 1),
                      itemLabel: _monthName,
                      onChanged: (v) =>
                          context.read<AttendanceCubit>().selectPdfMonth(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CustomDropdown<int>(
                      label: 'السنة',
                      value: state.selectedPdfYear,
                      items: List<int>.generate(
                        5,
                        (i) => DateTime.now().year - i,
                      ),
                      itemLabel: (y) => y.toString(),
                      onChanged: (v) =>
                          context.read<AttendanceCubit>().selectPdfYear(v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Download button ──────────────────────────────────────────
              FilledButton.icon(
                onPressed: isDownloading ? null : () => _download(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                ),
                icon: isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        size: 22,
                      ),
                label: Text(
                  isDownloading ? 'جاري التحميل...' : 'تحميل التقرير',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String _monthName(int month) {
  const names = [
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
  return names[month - 1];
}

/// Custom dropdown widget for attendance pdf card.
class _CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  const _CustomDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              iconEnabledColor: AppColors.primary,
              iconSize: 26,
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
