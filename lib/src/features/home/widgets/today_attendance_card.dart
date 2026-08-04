import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TodayAttendanceCard extends StatelessWidget {
  final String? attendanceTime;
  final String? departureTime;

  const TodayAttendanceCard({
    super.key,
    this.attendanceTime,
    this.departureTime,
  });

  /// Returns a slightly lighter/shifted variant of the primary color for the gradient end.
  Color _getGradientEndColor() {
    final r = ((AppColors.primary.r * 255.0).round() + 15).clamp(0, 255);
    final g = (AppColors.primary.g * 255.0).round().clamp(0, 255);
    final b = ((AppColors.primary.b * 255.0).round() + 25).clamp(0, 255);
    final a = (AppColors.primary.a * 255.0).round().clamp(0, 255);
    return Color.fromARGB(a, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    final hasAttendance = attendanceTime != null;
    final hasDeparture = departureTime != null;

    // حساب ساعات العمل
    double workHours = 0;
    if (hasAttendance && !hasDeparture) {
      final now = DateTime.now();
      final attendance = _parseTime(attendanceTime!);
      workHours = now.difference(attendance).inMinutes / 60;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            _getGradientEndColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'حضورك اليوم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  icon: Icons.login,
                  label: 'الحضور',
                  time: hasAttendance ? _formatTime(attendanceTime!) : '--:--',
                  isActive: hasAttendance,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildTimeInfo(
                  icon: Icons.logout,
                  label: 'الانصراف',
                  time: hasDeparture ? _formatTime(departureTime!) : '--:--',
                  isActive: hasDeparture,
                ),
              ),
            ],
          ),
          if (hasAttendance && !hasDeparture) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ساعات العمل',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${workHours.toStringAsFixed(1)} / 8 ساعات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (workHours / 8).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInfo({
    required IconData icon,
    required String label,
    required String time,
    required bool isActive,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    String secondPart = parts.length > 2 ? parts[2] : '0';
    final dotIndex = secondPart.indexOf('.');
    if (dotIndex != -1) {
      secondPart = secondPart.substring(0, dotIndex);
    }
    final second = int.tryParse(secondPart) ?? 0;

    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      second,
    );
  }

  String _formatTime(String time) {
    // Convert "11:02:55" to "11:02 ص"
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'م' : 'ص';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }
}