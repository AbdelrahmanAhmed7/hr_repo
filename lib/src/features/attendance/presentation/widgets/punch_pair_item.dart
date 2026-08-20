import 'package:flutter/material.dart';

import '../../data/models/punch_pair_model.dart';

class PunchPairItem extends StatelessWidget {
  final PunchPairModel item;

  const PunchPairItem({super.key, required this.item});

  String formatTime(String time) {
    if (time.isEmpty) return '—';
    try {
      final clean = time.split('.')[0];
      final parts = clean.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'م' : 'ص';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${hour12.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final surface2Color = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.dividerColor;
    final textMuted = theme.hintColor;
    final textSecondary =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        Colors.grey;
    final amberColor = Colors.amber.shade700;
    final greenColor = Colors.green.shade600;
    final redColor = theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: item.isOpen ? amberColor : greenColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: surfaceColor,
        child: Row(
          children: [
            // Check-in
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('دخول', style: TextStyle(fontSize: 10, color: textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.login_rounded, size: 14, color: greenColor),
                    const SizedBox(width: 4),
                    Text(
                      formatTime(item.checkIn),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: greenColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Arrow separator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_back_rounded, size: 16, color: textMuted),
            ),
            // Check-out
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('خروج', style: TextStyle(fontSize: 10, color: textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 14,
                      color: item.isOpen ? amberColor : redColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.checkOut != null ? formatTime(item.checkOut!) : '—',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: item.isOpen ? amberColor : redColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Duration chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: item.isOpen
                    ? amberColor.withValues(alpha: 0.12)
                    : surface2Color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.isOpen
                      ? amberColor.withValues(alpha: 0.4)
                      : borderColor,
                ),
              ),
              child: Text(
                item.duration,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: item.isOpen ? amberColor : textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
