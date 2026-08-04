import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/mixins/keyboard_dismiss_mixin.dart';
import '../auth/services/auth_storage_service.dart';
import '../requests/services/requests_refresh_service.dart';
import 'cubit/leaves_cubit.dart';
import 'cubit/leaves_state.dart';
import 'models/leave_submission_model.dart';
import 'widgets/leave_type_selector.dart';
import 'widgets/leave_date_range_picker.dart';
import 'widgets/leave_reason_field.dart';
import 'widgets/leave_request_progress_indicator.dart';
import 'widgets/leave_request_navigation_buttons.dart';

class CreateLeaveRequestScreen extends StatefulWidget {
  const CreateLeaveRequestScreen({super.key});

  @override
  State<CreateLeaveRequestScreen> createState() => _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState extends State<CreateLeaveRequestScreen> with KeyboardDismissMixin {
  final PageController _pageController = PageController();
  late LeavesCubit _cubit;
  int _currentStep = 0;
  
  int? _selectedLeaveTypeId;
  String? _selectedLeaveTypeName;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  String? _attachmentPath;

  @override
  void initState() {
    super.initState();
    // Use the singleton instance from service locator
    _cubit = getIt<LeavesCubit>();
    // Create flow needs types; balance comes from overview API.
    if (_cubit.state.leaveBalance == null || _cubit.state.leaveRequests.isEmpty) {
      _cubit.loadLeavesOverview();
    }
    // Always force-refresh leave types so the user sees the latest list from the server.
    _cubit.loadLeaveTypes(forceRefresh: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reasonController.dispose();
    // Don't close the cubit - it's a singleton shared across screens
    super.dispose();
  }

  void _goToNextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
        FocusScope.of(context).unfocus();
        
        // Auto-set dates based on leave type when moving from step 0 to 1
        if (_currentStep == 0 && _selectedLeaveTypeName != null) {
          _setDefaultDatesForLeaveType(_selectedLeaveTypeName!);
        }
        
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentStep++;
        });
      } else {
        _submitLeaveRequest();
      }
    }
  }

  void _setDefaultDatesForLeaveType(String leaveType) {
    final today = DateTime.now();
    
    switch (leaveType.toLowerCase()) {
      case 'casual': // إجازة عرضية - يوم واحد
        setState(() {
          _startDate = today;
          _endDate = today;
        });
        break;
      case 'sick':
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
      case 'paternity': // إجازة أبوة - يوم واحد (كما طلب المستخدم)
        setState(() {
          _startDate = today;
          _endDate = today;
        });
        break;
      case 'hajj': // إجازة حج - 15 يوم
        setState(() {
          _startDate = today;
          _endDate = today.add(const Duration(days: 14));
        });
        break;
      case 'exam': // إجازة امتحانات - يحددها المستخدم يومًا أو فترة
        setState(() {
          _startDate = null;
          _endDate = null;
        });
        break;
      default: // Annual وغيرها - لا يوجد افتراضي
        break;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedLeaveTypeId == null || _selectedLeaveTypeName == null) {
          CustomToast.showError('يرجى اختيار نوع الإجازة');
          return false;
        }
        return true;
      case 1:
        if (_startDate == null) {
          CustomToast.showError('يرجى اختيار تاريخ البداية');
          return false;
        }
        if (_endDate == null) {
          CustomToast.showError('يرجى اختيار تاريخ النهاية');
          return false;
        }
        if (_endDate!.isBefore(_startDate!)) {
          CustomToast.showError('تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
          return false;
        }

        // Block early: don't allow moving to the "send" step if balance is insufficient.
        final balance = _cubit.state.leaveBalance;
        final requestedDays = (_endDate!.difference(_startDate!).inDays + 1);
        final leaveType = _selectedLeaveTypeName?.toLowerCase().trim();
        if (balance != null &&
            (leaveType == 'annual' || leaveType == 'سنوية') &&
            requestedDays > balance.annualLeaveRemaining) {
          CustomToast.showError(
            'رصيد الإجازات غير كافٍ (${balance.annualLeaveRemaining} يوم متاح).',
          );
          return false;
        }

        return true;
      case 2:
        if (_reasonController.text.trim().isEmpty) {
          CustomToast.showError('يرجى إدخال سبب الإجازة');
          return false;
        }
        if (_reasonController.text.trim().length < 5) {
          CustomToast.showError('السبب يجب أن يكون 5 أحرف على الأقل');
          return false;
        }
        // التحقق من المرفق في حالة الإجازة المرضية
        if (_selectedLeaveTypeName?.toLowerCase() == 'sick' && _attachmentPath == null) {
          CustomToast.showError('يرجى إرفاق تقرير طبي للإجازة المرضية');
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _submitLeaveRequest() async {
    try {
      FocusScope.of(context).unfocus();

      if (_cubit.state.submissionStatus == SubmissionStatus.submitting) {
        return;
      }

      final authState = await AuthStorageService.loadAuthState();

      if (authState.userId == null) {
        if (!mounted) return;
        CustomToast.showError('خطأ في معرف المستخدم');
        return;
      }

      // Format dates as YYYY-MM-DD (date only, no time)
      final startDateStr =
          '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      final createdAtStr = DateTime.now().toIso8601String();

      if (_selectedLeaveTypeId == null || _selectedLeaveTypeName == null) {
        if (!mounted) return;
        CustomToast.showError('يرجى اختيار نوع الإجازة');
        return;
      }

      final submission = LeaveSubmissionModel(
        userId: authState.userId!,
        startDate: startDateStr,
        endDate: endDateStr,
        reason: _reasonController.text.trim(),
        createdAt: createdAtStr,
        leaveType: _selectedLeaveTypeName!,
        medicalReportUrl: _attachmentPath,
      );

      // Client-side balance guard: prevent sending a request when remaining balance is insufficient.
      // Applies primarily to annual leave requests.
      final balance = _cubit.state.leaveBalance;
      final requestedDays = (_endDate!.difference(_startDate!).inDays + 1);
      final leaveType = _selectedLeaveTypeName?.toLowerCase().trim();
      if (balance != null &&
          (leaveType == 'annual' || leaveType == 'سنوية') &&
          requestedDays > balance.annualLeaveRemaining) {
        if (!mounted) return;
        CustomToast.showError(
          'رصيد الإجازات غير كافٍ (${balance.annualLeaveRemaining} يوم متاح).',
        );
        return;
      }

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
            CustomToast.showSuccess('تم إرسال طلب الإجازة بنجاح');
            // Notify other screens (permissions/leaves/all-requests/home) to refresh their lists.
            getIt<RequestsRefreshService>().notify();
            
            // Safety check before popping
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          } else if (state.submissionStatus == SubmissionStatus.failure) {
            CustomToast.showError(
              state.submissionErrorMessage ?? 'حدث خطأ أثناء إرسال الطلب',
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
        children: [
          // Progress Indicator
          LeaveRequestProgressIndicator(currentStep: _currentStep),
          
          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                // Step 1: Leave Type
                LeaveTypeSelector(
                  selectedTypeId: _selectedLeaveTypeId,
                  leaveTypes: state.leaveTypes,
                  isLoading: state.leaveTypesStatus == LeavesStatus.loading,
                  errorMessage: state.leaveTypesStatus == LeavesStatus.failure
                      ? (state.leaveTypesErrorMessage ?? 'فشل تحميل أنواع الإجازات')
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
                
                // Step 2: Date Range
                LeaveDateRangePicker(
                  startDate: _startDate,
                  endDate: _endDate,
                  currentLeaveBalance: state.leaveBalance?.annualLeaveRemaining,
                  isSingleDay: _selectedLeaveTypeName?.toLowerCase() == 'paternity' || 
                               _selectedLeaveTypeName?.toLowerCase() == 'casual',
                  onStartDateSelected: (date) {
                    setState(() {
                      _startDate = date;
                      // في حالة الأنواع ذات اليوم الواحد، تاريخ النهاية هو نفس تاريخ البداية
                      if (_selectedLeaveTypeName?.toLowerCase() == 'paternity' || 
                          _selectedLeaveTypeName?.toLowerCase() == 'casual') {
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
                
                // Step 3: Reason + Attachment
                LeaveReasonField(
                  controller: _reasonController,
                  attachmentPath: _attachmentPath,
                  leaveType: _selectedLeaveTypeName,
                  onPickAttachment: (path) {
                    setState(() {
                      _attachmentPath = path;
                    });
                  },
                  onRemoveAttachment: () => setState(() => _attachmentPath = null),
                ),
              ],
            ),
          ),
          
          // Navigation Buttons
          LeaveRequestNavigationButtons(
            currentStep: _currentStep,
            onPrevious: _currentStep > 0 && state.submissionStatus != SubmissionStatus.submitting 
                ? _goToPreviousStep 
                : null,
            onNext: state.submissionStatus == SubmissionStatus.submitting ? null : _goToNextStep,
          ),
        ],
      ),
      if (state.submissionStatus == SubmissionStatus.submitting)
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  },
),
    );
  }
}
