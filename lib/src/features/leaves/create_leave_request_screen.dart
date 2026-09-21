import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/mixins/keyboard_dismiss_mixin.dart';
import '../auth/services/auth_storage_service.dart';
import '../requests/services/requests_refresh_service.dart';
import 'cubit/leaves_cubit.dart';
import 'cubit/leaves_state.dart';
import 'models/leave_submission_model.dart';
import 'widgets/leave_date_range_picker.dart';
import 'widgets/leave_reason_field.dart';
import 'widgets/leave_type_selector.dart';

/// Single-screen leave request: type → dates → reason & attachment in one
/// scrollable form with a single submit button.
class CreateLeaveRequestScreen extends StatefulWidget {
  const CreateLeaveRequestScreen({super.key});

  @override
  State<CreateLeaveRequestScreen> createState() =>
      _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState extends State<CreateLeaveRequestScreen>
    with KeyboardDismissMixin {
  late LeavesCubit _cubit;

  int? _selectedLeaveTypeId;
  String? _selectedLeaveTypeName;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  String? _attachmentPath;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<LeavesCubit>();
    // Create flow needs types; balance comes from the overview API.
    if (_cubit.state.leaveBalance == null ||
        _cubit.state.leaveRequests.isEmpty) {
      _cubit.loadLeavesOverview();
    }
    // Always force-refresh leave types so the user sees the latest list.
    _cubit.loadLeaveTypes(forceRefresh: true);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    // Don't close the cubit — it's a singleton shared across screens.
    super.dispose();
  }

  bool get _isSingleDay =>
      _selectedLeaveTypeName?.toLowerCase() == 'paternity' ||
      _selectedLeaveTypeName?.toLowerCase() == 'casual';

  void _setDefaultDatesForLeaveType(String leaveType) {
    final today = DateTime.now();

    switch (leaveType.toLowerCase()) {
      case 'casual': // إجازة عرضية - يوم واحد
      case 'sick':
      case 'paternity':
        setState(() {
          _startDate = today;
          _endDate = today;
        });
        break;
      case 'maternity': // إجازة وضع - 90 يوم
        setState(() {
          _startDate = today;
          _endDate = today.add(const Duration(days: 89));
        });
        break;
      case 'hajj': // إجازة حج - 15 يوم
        setState(() {
          _startDate = today;
          _endDate = today.add(const Duration(days: 14));
        });
        break;
      case 'exam': // إجازة امتحانات - يحددها المستخدم
        setState(() {
          _startDate = null;
          _endDate = null;
        });
        break;
      default: // Annual وغيرها - لا يوجد افتراضي
        break;
    }
  }

  void _applyQuickDuration(int days) {
    final today = DateTime.now();
    setState(() {
      _startDate = today;
      _endDate = today.add(Duration(days: days - 1));
    });
  }

  bool _validateForm() {
    if (_selectedLeaveTypeId == null || _selectedLeaveTypeName == null) {
      CustomToast.showError('يرجى اختيار نوع الإجازة');
      return false;
    }
    if (_startDate == null) {
      CustomToast.showError('يرجى اختيار تاريخ البداية');
      return false;
    }
    if (!_isSingleDay && _endDate == null) {
      CustomToast.showError('يرجى اختيار تاريخ النهاية');
      return false;
    }
    if (_endDate != null && _endDate!.isBefore(_startDate!)) {
      CustomToast.showError('تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
      return false;
    }

    // Block early if the annual balance is insufficient.
    final balance = _cubit.state.leaveBalance;
    final requestedDays =
        (_endDate ?? _startDate)!.difference(_startDate!).inDays + 1;
    final leaveType = _selectedLeaveTypeName?.toLowerCase().trim();
    if (balance != null &&
        (leaveType == 'annual' || leaveType == 'سنوية') &&
        requestedDays > balance.annualLeaveRemaining) {
      CustomToast.showError(
        'رصيد الإجازات غير كافٍ (${balance.annualLeaveRemaining} يوم متاح).',
      );
      return false;
    }

    if (_reasonController.text.trim().isEmpty) {
      CustomToast.showError('يرجى إدخال سبب الإجازة');
      return false;
    }
    if (_reasonController.text.trim().length < 5) {
      CustomToast.showError('السبب يجب أن يكون 5 أحرف على الأقل');
      return false;
    }
    if (_selectedLeaveTypeName?.toLowerCase() == 'sick' &&
        _attachmentPath == null) {
      CustomToast.showError('يرجى إرفاق تقرير طبي للإجازة المرضية');
      return false;
    }
    return true;
  }

  Future<void> _submitLeaveRequest() async {
    FocusScope.of(context).unfocus();

    if (_cubit.state.submissionStatus == SubmissionStatus.submitting) return;
    if (!_validateForm()) return;

    try {
      final authState = await AuthStorageService.loadAuthState();
      if (authState.userId == null) {
        if (!mounted) return;
        CustomToast.showError('خطأ في معرف المستخدم');
        return;
      }

      if (_selectedLeaveTypeId == null || _selectedLeaveTypeName == null) {
        if (!mounted) return;
        CustomToast.showError('يرجى اختيار نوع الإجازة');
        return;
      }

      // Format dates as YYYY-MM-DD (date only, no time).
      final startDateStr =
          '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${(_endDate ?? _startDate)!.year}-${(_endDate ?? _startDate)!.month.toString().padLeft(2, '0')}-${(_endDate ?? _startDate)!.day.toString().padLeft(2, '0')}';
      final createdAtStr = DateTime.now().toIso8601String();

      final submission = LeaveSubmissionModel(
        userId: authState.userId!,
        startDate: startDateStr,
        endDate: endDateStr,
        reason: _reasonController.text.trim(),
        createdAt: createdAtStr,
        leaveType: _selectedLeaveTypeName!,
        medicalReportUrl: _attachmentPath,
      );

      await _cubit.submitLeave(submission, leaveTypeId: _selectedLeaveTypeId!);
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError('حدث خطأ أثناء إرسال الطلب');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'طلب إجازة جديدة',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<LeavesCubit, LeavesState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state.submissionStatus == SubmissionStatus.success) {
            // Notify other screens (permissions/leaves/all-requests/home) to refresh.
            getIt<RequestsRefreshService>().notify();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              showDialog<void>(
                context: this.context,
                barrierDismissible: false,
                builder: (_) => const _SuccessDialog(),
              ).then((_) {
                if (!mounted) return;
                if (Navigator.of(this.context).canPop()) {
                  Navigator.of(this.context).pop(true);
                }
              });
            });
          } else if (state.submissionStatus == SubmissionStatus.failure) {
            CustomToast.showError(
              state.submissionErrorMessage ?? 'حدث خطأ أثناء إرسال الطلب',
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle(title: 'نوع الإجازة'),
                    LeaveTypeSelector(
                      selectedTypeId: _selectedLeaveTypeId,
                      leaveTypes: state.leaveTypes,
                      isLoading: state.leaveTypesStatus == LeavesStatus.loading,
                      errorMessage:
                          state.leaveTypesStatus == LeavesStatus.failure
                          ? (state.leaveTypesErrorMessage ??
                                'فشل تحميل أنواع الإجازات')
                          : null,
                      onRetry: () {
                        _cubit.loadLeaveTypes();
                      },
                      onTypeSelected: (type) {
                        setState(() {
                          _selectedLeaveTypeId = type.id;
                          _selectedLeaveTypeName = type.name;
                          _setDefaultDatesForLeaveType(type.name);
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    const _SectionTitle(title: 'التواريخ'),
                    if (_selectedLeaveTypeName != null && !_isSingleDay)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _QuickDurationChips(
                          onSelected: _applyQuickDuration,
                        ),
                      ),
                    LeaveDateRangePicker(
                      startDate: _startDate,
                      endDate: _endDate,
                      currentLeaveBalance:
                          state.leaveBalance?.annualLeaveRemaining,
                      isSingleDay: _isSingleDay,
                      onStartDateSelected: (date) {
                        setState(() {
                          _startDate = date;
                          if (_isSingleDay) {
                            _endDate = date;
                          }
                        });
                      },
                      onEndDateSelected: (date) {
                        setState(() {
                          _endDate = date;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    const _SectionTitle(title: 'تفاصيل الطلب'),
                    LeaveReasonField(
                      controller: _reasonController,
                      attachmentPath: _attachmentPath,
                      leaveType: _selectedLeaveTypeName,
                      onPickAttachment: (path) {
                        setState(() {
                          _attachmentPath = path;
                        });
                      },
                      onRemoveAttachment: () {
                        setState(() {
                          _attachmentPath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (state.submissionStatus == SubmissionStatus.submitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: BlocBuilder<LeavesCubit, LeavesState>(
            bloc: _cubit,
            builder: (context, state) {
              return FilledButton(
                onPressed: state.submissionStatus == SubmissionStatus.submitting
                    ? null
                    : _submitLeaveRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('إرسال الطلب', style: AppTextStyles.buttonLarge),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('نجاح'),
        ],
      ),
      content: const Text('تم إرسال طلب الإجازة بنجاح'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('حسناً'),
        ),
      ],
    );
  }
}

class _QuickDurationChips extends StatelessWidget {
  final ValueChanged<int> onSelected;
  const _QuickDurationChips({required this.onSelected});

  static const _options = <(int, String)>[
    (1, 'يوم'),
    (3, '3 أيام'),
    (7, 'أسبوع'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'مدة سريعة:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in _options)
                InkWell(
                  onTap: () => onSelected(option.$1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      option.$2,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
