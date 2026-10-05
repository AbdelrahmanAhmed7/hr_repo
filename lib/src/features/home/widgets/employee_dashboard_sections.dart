import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/auth_storage_service.dart';
import '../models/attendance_status.dart';
import '../models/employee_info.dart';

/// Helper function to calculate work hours between check-in and check-out
String _calculateWorkHours(DateTime checkIn, DateTime checkOut) {
  final duration = checkOut.difference(checkIn);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return '$hours ساعة و $minutes دقيقة';
  } else if (hours > 0) {
    return '$hours ساعة';
  } else if (minutes > 0) {
    return '$minutes دقيقة';
  }
  return '--';
}

String? _formatTime(DateTime? time) {
  if (time == null) return null;
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class EmployeeImmersiveTopSection extends StatelessWidget {
  final EmployeeInfo employeeInfo;
  final AttendanceInfo attendanceInfo;
  final String greeting;
  final bool isLoading;
  final VoidCallback? onCheckInOut;
  final VoidCallback? onRetry;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  const EmployeeImmersiveTopSection({
    super.key,
    required this.employeeInfo,
    required this.attendanceInfo,
    required this.greeting,
    required this.isLoading,
    required this.onCheckInOut,
    this.onRetry,
    required this.onNotificationTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = attendanceInfo.status == AttendanceStatus.checkedIn;
    final isCheckedOut = attendanceInfo.status == AttendanceStatus.checkedOut;
    final actionColor = isCheckedOut
        ? Colors.grey.shade600
        : (isCheckedIn ? AppColors.error : AppColors.success);
    final actionLabel = isCheckedOut
        ? 'اليوم مكتمل'
        : (isCheckedIn
              ? 'تسجيل الانصراف'
              : 'تسجيل الحضور');
    final jobTitle = employeeInfo.position.trim();
    final department = employeeInfo.department.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1734), Color(0xFF12306A), Color(0xFF2152A3)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1E4A).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopActionsRow(
                notificationCount: employeeInfo.notificationCount,
                onNotificationTap: onNotificationTap,
                onMenuTap: onMenuTap,
              ),
              const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                greeting.trim().isEmpty ? '--' : greeting,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              employeeInfo.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              jobTitle.isNotEmpty
                                  ? jobTitle
                                  : (department.isNotEmpty ? department : '--'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            if (jobTitle.isNotEmpty &&
                                department.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                department,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _AvatarBadge(
                        name: employeeInfo.name,
                        imageUrl: employeeInfo.profileImageUrl,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _HeroStatCard(
                                label: 'الحضور',
                                value:
                                    _formatTime(
                                      attendanceInfo.checkInTime,
                                    ) ??
                                    '--:--',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeroStatCard(
                                label:
                                    'الانصراف',
                                value:
                                    _formatTime(
                                      attendanceInfo.checkOutTime,
                                    ) ??
                                    '--:--',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Work hours row - shows total hours worked
                        if (attendanceInfo.checkInTime != null &&
                            attendanceInfo.checkOutTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ساعات العمل:',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _calculateWorkHours(
                                    attendanceInfo.checkInTime!,
                                    attendanceInfo.checkOutTime!,
                                  ),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (attendanceInfo.isUnknown)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onRetry,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تعذر تحديد حالة اليوم',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'تحقق من الاتصال ثم أعد المحاولة',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (isLoading || isCheckedOut)
                            ? null
                            : onCheckInOut,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: actionColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(11),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      isCheckedIn
                                          ? Icons.logout_rounded
                                          : Icons.fingerprint_rounded,
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
                                    actionLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCheckedIn
                                        ? 'أنهِ اليوم بتأكيد الانصراف'
                                        : 'ابدأ يومك بتأكيد الحضور',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: actionColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}

class _TopActionsRow extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const _TopActionsRow({
    required this.notificationCount,
    required this.onNotificationTap,
    VoidCallback? onMenuTap, // kept for API compatibility, unused
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _GlassButton(
              icon: Icons.notifications_none_rounded,
              onTap: onNotificationTap,
            ),
            if (notificationCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6D),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF0E2760),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _AvatarBadge({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // Clean the image URL first
    String? cleanUrl = imageUrl?.replaceAll('`', '').trim();
    if (cleanUrl != null && cleanUrl.isEmpty) cleanUrl = null;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFDBFE), Color(0xFF93C5FD)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: cleanUrl != null
            ? FutureBuilder<String?>(
                future: AuthStorageService.getToken(),
                builder: (context, snapshot) {
                  final headers = <String, String>{};
                  if (snapshot.hasData && snapshot.data != null) {
                    headers['Authorization'] = 'Bearer ${snapshot.data}';
                  }
                  return CachedNetworkImage(
                    imageUrl: cleanUrl!,
                    httpHeaders: headers,
                    fit: BoxFit.cover,
                    placeholder: (context, imageUrl) =>
                        _InitialsFallback(name: name),
                    errorWidget: (context, imageUrl, error) {
                      if (kDebugMode) {
                        debugPrint('Image load error for $cleanUrl: $error');
                      }
                      return _InitialsFallback(name: name);
                    },
                  );
                },
              )
            : _InitialsFallback(name: name),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'E';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _InitialsFallback extends StatelessWidget {
  final String name;

  const _InitialsFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _AvatarBadge._initials(name),
        style: const TextStyle(
          color: Color(0xFF0B1E49),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
