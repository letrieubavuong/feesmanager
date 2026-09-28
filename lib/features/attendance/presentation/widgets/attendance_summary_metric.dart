import 'package:flutter/material.dart';

class AttendanceSummaryMetric extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String semanticLabel;

  const AttendanceSummaryMetric({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel: $count',
      child: Tooltip(
        message: '$semanticLabel: $count',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
