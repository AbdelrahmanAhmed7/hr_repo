import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/custom_toast.dart';
import '../models/organization_models.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../hr/cubit/employees_cubit.dart';
import '../../hr/models/employee.dart' as hr;
import 'employee_details_dialog.dart';

/// Modern context menu for employee actions
class EmployeeActionsMenu extends StatelessWidget {
  final Employee employee;
  final Department? department;
  final int? subordinatesCount;
  final Function()? onViewAttendance;
  final Function()? onClose;

  const EmployeeActionsMenu({
    super.key,
    required this.employee,
    this.department,
    this.subordinatesCount,
    this.onViewAttendance,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Try to get full employee data from HR cubit
    hr.Employee? hrEmployee;
    bool isHR = false;
    try {
      final authCubit = context.read<AuthCubit>();
      isHR = authCubit.state.isHR;

      if (isHR) {
        final employeesCubit = context.read<EmployeesCubit>();
        try {
          hrEmployee = employeesCubit.state.employees.firstWhere(
            (e) => e.id == employee.id,
          );
        } catch (e) {
          // Employee not found in HR list
        }
      }
    } catch (e) {
      // Cubits not available
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with employee info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: employee.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            employee.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Employee info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (department != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              department!.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (subordinatesCount != null &&
                          subordinatesCount! > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.group_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$subordinatesCount موظف تحت الإدارة',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions list
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Details - Primary action
                _ModernActionItem(
                  icon: Icons.info_outline_rounded,
                  label: 'عرض التفاصيل',
                  description: 'معلومات سريعة عن الموظف',
                  color: AppColors.primary,
                  isPrimary: true,
                  onTap: () {
                    onClose?.call();
                    showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: BlocProvider.value(
                          value: context.read<EmployeesCubit>(),
                          child: EmployeeDetailsDialog(
                            employee: employee,
                            department: department,
                            subordinatesCount: subordinatesCount,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Contact actions section
                _ModernActionItem(
                  icon: Icons.phone_outlined,
                  label: 'اتصال',
                  description: hrEmployee?.phone ?? 'غير متاح',
                  color: const Color(0xFF4CAF50),
                  enabled:
                      hrEmployee?.phone != null && hrEmployee!.phone.isNotEmpty,
                  onTap: () {
                    onClose?.call();
                    final phone = hrEmployee?.phone;
                    if (phone != null && phone.isNotEmpty) {
                      _launchPhoneCall(context, phone);
                    } else {
                      CustomToast.showError('رقم الهاتف غير متاح');
                    }
                  },
                ),

                _ModernActionItem(
                  icon: Icons.chat,
                  label: 'واتساب',
                  description: hrEmployee?.phone ?? 'غير متاح',
                  color: const Color(0xFF25D366),
                  enabled:
                      hrEmployee?.phone != null && hrEmployee!.phone.isNotEmpty,
                  onTap: () {
                    onClose?.call();
                    final phone = hrEmployee?.phone;
                    if (phone != null && phone.isNotEmpty) {
                      _launchWhatsApp(context, phone);
                    } else {
                      CustomToast.showError('رقم الهاتف غير متاح');
                    }
                  },
                ),

                // View Attendance Report (HR only)
                if (isHR && hrEmployee != null && onViewAttendance != null) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _ModernActionItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'تقرير الحضور',
                    description: 'عرض سجل الحضور والانصراف',
                    color: AppColors.primary,
                    onTap: () {
                      onClose?.call();
                      // Use rootNavigator to ensure navigation works from bottom sheet
                      onViewAttendance?.call();
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Launch phone call using url_launcher
  Future<void> _launchPhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');

    try {
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(phoneUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(
          'مش ممكن نفتح تطبيق الهاتف. تأكد إن التطبيق مثبت',
        );
      }
    }
  }

  /// Launch WhatsApp using url_launcher
  Future<void> _launchWhatsApp(BuildContext context, String phoneNumber) async {
    // Clean phone number for WhatsApp
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\+\-\(\)]'), '');

    if (cleanPhone.startsWith('00')) {
      cleanPhone = cleanPhone.substring(2);
    }

    if (cleanPhone.startsWith('0') && cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(1);
    }

    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone');

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(
          'مش ممكن نفتح واتساب. تأكد إن التطبيق مثبت أو استخدم المتصفح'
        );
      }
    }
  }
}

class _ModernActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ModernActionItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.enabled = true,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? color.withValues(alpha: 0.1)
              : enabled
              ? AppColors.backgroundSecondary
              : AppColors.backgroundSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isPrimary || enabled)
                    ? color.withValues(alpha: 0.15)
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: enabled
                    ? (isPrimary ? color : color)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow icon
            if (enabled)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
