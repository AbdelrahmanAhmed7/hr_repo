import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../attendance/data/models/punch_pair_model.dart';

class PunchPairCard extends StatelessWidget {
  final PunchPairModel pair;

  const PunchPairCard({super.key, required this.pair});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: name + date + status badge ──────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: pair.isOpen
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pair.isOpen ? Icons.login_rounded : Icons.logout_rounded,
                  size: 20,
                  color: pair.isOpen ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pair.employeeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pair.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pair.isOpen
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pair.isOpen ? 'مفتوح' : pair.duration,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: pair.isOpen
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Check-in / Check-out chips ──────────────────────────────
          Row(
            children: [
              _TimeChip(
                label: 'دخول',
                time: pair.checkIn,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              if (pair.checkOut != null)
                _TimeChip(
                  label: 'خروج',
                  time: pair.checkOut!,
                  color: AppColors.error,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'لم يخرج بعد',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),

          // ── Permissions ─────────────────────────────────────────────
          if (pair.hasPermissions) ...[
            const SizedBox(height: 10),
            ...pair.permissions.map((p) => _RequestChip(
                  icon: Icons.logout_rounded,
                  color: AppColors.warning,
                  label: 'أذن',
                  reason: p.reason,
                  time: p.displayTime,
                )),
          ],

          // ── Assignments ─────────────────────────────────────────────
          if (pair.hasAssignments) ...[
            const SizedBox(height: 10),
            ...pair.assignments.map((a) => _RequestChip(
                  icon: Icons.flight_takeoff_rounded,
                  color: AppColors.info,
                  label: 'مأمورية',
                  reason: a.reason,
                  time: a.displayTime,
                )),
          ],
        ],
      ),
    );
  }
}

// ── Time chip ──────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final Color color;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayTime = _formatTime(time);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $displayTime',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final parts = raw.split('.')[0].split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    } catch (_) {}
    return raw;
  }
}

// ── Permission / Assignment chip ───────────────────────────────────────────

class _RequestChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String reason;
  final String time;

  const _RequestChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.reason,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
