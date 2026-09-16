import 'package:flutter/material.dart';

import '../utils/task_labels.dart';

/// Status pill + small meta chips used across task screens.
class TaskStatusChip extends StatelessWidget {
  final int status;
  final double fontSize;

  const TaskStatusChip({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final color = TaskLabels.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TaskLabels.statusIcon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            TaskLabels.statusText(status),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const TaskMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color ?? Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linear progress bar with percentage label.
class TaskProgressBar extends StatelessWidget {
  final int progress;
  final double height;

  const TaskProgressBar({super.key, required this.progress, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final share = (progress.clamp(0, 100)) / 100.0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  Container(color: Colors.blue.withValues(alpha: 0.12)),
                  FractionallySizedBox(
                    widthFactor: share,
                    child: Container(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$progress%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
