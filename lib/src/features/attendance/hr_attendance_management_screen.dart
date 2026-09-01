import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_exception.dart';
import '../../shared/components/custom_toast.dart';
import '../../shared/widgets/searchable_dropdown_field.dart';
import 'models/attendance_list_response.dart';
import 'repository/attendance_repository.dart';

class HrAttendanceManagementScreen extends StatefulWidget {
  const HrAttendanceManagementScreen({super.key});

  @override
  State<HrAttendanceManagementScreen> createState() =>
      _HrAttendanceManagementScreenState();
}

class _HrAttendanceManagementScreenState
    extends State<HrAttendanceManagementScreen> {
  final AttendanceRepository _repository = getIt<AttendanceRepository>();
  final TextEditingController _machineCodeController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;
  AttendanceListResponse? _response;

  int _pageNumber = 1;
  int _pageSize = 50;
  bool? _isCheckIn;

  bool _isValidUuid(String value) {
    final pattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return pattern.hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void dispose() {
    _machineCodeController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    final employeeIdText = _employeeIdController.text.trim();
    if (employeeIdText.isNotEmpty && !_isValidUuid(employeeIdText)) {
      setState(() {
        _error = 'Employee ID must be a valid UUID';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _repository.getAllAttendance(
        startDate: _selectedDate,
        endDate: _selectedDate,
        machineCode: _machineCodeController.text.trim(),
        employeeId: employeeIdText,
        isCheckIn: _isCheckIn,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _response = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppException.from(e).message;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportMonthlyReport() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final report = await _repository.downloadMonthlyReport(
        month: _selectedDate.month,
        year: _selectedDate.year,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${report.fileName}');
      await file.writeAsBytes(report.bytes, flush: true);

      final result = await OpenFile.open(file.path);
      if (!mounted) return;

      if (result.type == ResultType.done) {
        CustomToast.showSuccess('Monthly report exported');
      } else {
        CustomToast.showInfo(
          result.message.isNotEmpty
              ? result.message
              : 'Report file was created',
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(AppException.from(e).message);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
      _pageNumber = 1;
    });
    _loadAttendance();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = picked;
      _pageNumber = 1;
    });
    _loadAttendance();
  }

  int get _totalPages {
    final totalCount = _response?.totalCount ?? 0;
    final effectivePageSize = _response?.pageSize ?? _pageSize;
    if (totalCount == 0) return 1;
    return (totalCount / effectivePageSize).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAttendance,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 250) return;
              if (velocity < 0) {
                _changeDay(1);
              } else {
                _changeDay(-1);
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        _TopHeader(
                          dateText: formattedDate,
                          isExporting: _isExporting,
                          onExport: _exportMonthlyReport,
                        ),
                        const SizedBox(height: 12),
                        _DayNavigator(
                          dateText: formattedDate,
                          onPrev: () => _changeDay(-1),
                          onNext: () => _changeDay(1),
                          onPickDate: _pickDate,
                          onToday: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                              _pageNumber = 1;
                            });
                            _loadAttendance();
                          },
                        ),
                        const SizedBox(height: 12),
                        _FilterPanel(
                          machineCodeController: _machineCodeController,
                          employeeIdController: _employeeIdController,
                          isCheckIn: _isCheckIn,
                          pageSize: _pageSize,
                          onIsCheckInChanged: (value) {
                            setState(() {
                              _isCheckIn = value;
                              _pageNumber = 1;
                            });
                          },
                          onPageSizeChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _pageSize = value;
                              _pageNumber = 1;
                            });
                          },
                          onApply: _loadAttendance,
                          onReset: () {
                            setState(() {
                              _machineCodeController.clear();
                              _employeeIdController.clear();
                              _isCheckIn = null;
                              _pageNumber = 1;
                              _pageSize = 50;
                            });
                            _loadAttendance();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 10),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadAttendance,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_response == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _SummaryStrip(
                        response: _response,
                        pageNumber: _pageNumber,
                        pageSize: _pageSize,
                        totalPages: _totalPages,
                      ),
                    ),
                  ),
                  if (_response!.attendances.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No attendance records found')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverList.separated(
                        itemCount: _response!.attendances.length,
                        itemBuilder: (context, index) {
                          final item = _response!.attendances[index];
                          return _AttendanceCard(item: item);
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: _PaginationBar(
                        pageNumber: _pageNumber,
                        totalPages: _totalPages,
                        onPrev: _pageNumber > 1
                            ? () {
                                setState(() => _pageNumber--);
                                _loadAttendance();
                              }
                            : null,
                        onNext: _pageNumber < _totalPages
                            ? () {
                                setState(() => _pageNumber++);
                                _loadAttendance();
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String dateText;
  final bool isExporting;
  final VoidCallback onExport;

  const _TopHeader({
    required this.dateText,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HR Attendance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selected day: $dateText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: isExporting ? null : onExport,
            icon: isExporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Monthly XLSX'),
          ),
        ],
      ),
    );
  }
}

class _DayNavigator extends StatelessWidget {
  final String dateText;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onPickDate;

  const _DayNavigator({
    required this.dateText,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Prev Day'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onToday,
                child: Text('Today ($dateText)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next Day'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Pick Specific Date'),
          ),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final TextEditingController machineCodeController;
  final TextEditingController employeeIdController;
  final bool? isCheckIn;
  final int pageSize;
  final ValueChanged<bool?> onIsCheckInChanged;
  final ValueChanged<int?> onPageSizeChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _FilterPanel({
    required this.machineCodeController,
    required this.employeeIdController,
    required this.isCheckIn,
    required this.pageSize,
    required this.onIsCheckInChanged,
    required this.onPageSizeChanged,
    required this.onApply,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: machineCodeController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Machine Code',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: employeeIdController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Employee ID (UUID)',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final checkInFilter = SearchableDropdownField<bool>(
                value: isCheckIn,
                labelText: 'Check-in Filter',
                searchHintText: 'Search check-in status',
                items: const [
                  SearchableDropdownItem<bool?>(value: null, label: 'All'),
                  SearchableDropdownItem<bool?>(value: true, label: 'In Only'),
                  SearchableDropdownItem<bool?>(
                    value: false,
                    label: 'No Check-in',
                  ),
                ],
                onChanged: onIsCheckInChanged,
              );

              final pageSizeFilter = SearchableDropdownField<int>(
                value: pageSize,
                labelText: 'Page Size',
                searchHintText: 'Search page size',
                items: const [
                  SearchableDropdownItem<int?>(value: 25, label: '25'),
                  SearchableDropdownItem<int?>(value: 50, label: '50'),
                  SearchableDropdownItem<int?>(value: 100, label: '100'),
                ],
                onChanged: onPageSizeChanged,
              );

              if (isCompact) {
                return Column(
                  children: [
                    checkInFilter,
                    const SizedBox(height: 10),
                    pageSizeFilter,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: checkInFilter),
                  const SizedBox(width: 10),
                  Expanded(child: pageSizeFilter),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final AttendanceListResponse? response;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  const _SummaryStrip({
    required this.response,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final data = response;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryChip(
                label: 'Employees',
                value: '${data?.totalEmployees ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                label: 'With Check-in',
                value: '${data?.employeesWithAttendance ?? 0}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryChip(
                label: 'With Check-out',
                value: '${data?.employeesWithDeparture ?? 0}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceItem item;

  const _AttendanceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasIn =
        item.attendanceTime != null && item.attendanceTime!.isNotEmpty;
    final hasOut = item.departureTime != null && item.departureTime!.isNotEmpty;
    final statusText = hasIn && hasOut
        ? 'Complete'
        : hasIn
        ? 'Checked-in'
        : 'Absent';
    final statusColor = hasIn && hasOut
        ? AppColors.success
        : hasIn
        ? AppColors.warning
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.employeeName?.trim().isNotEmpty == true
                ? item.employeeName!
                : 'Unknown Employee',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Machine: ${item.machineCode ?? '--'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Check-in',
                    value: item.attendanceTime ?? '--',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeTile(
                    label: 'Check-out',
                    value: item.departureTime ?? '--',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Date: ${item.date}'),
          Text('Day: ${item.dayOfWeek ?? '--'}'),
          if (item.location?.isNotEmpty == true)
            Text('Location: ${item.location}'),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TimeTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pageNumber,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onPrev,
            child: const Text('Previous'),
          ),
        ),
        const SizedBox(width: 8),
        Text('Page $pageNumber / $totalPages'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(onPressed: onNext, child: const Text('Next')),
        ),
      ],
    );
  }
}
