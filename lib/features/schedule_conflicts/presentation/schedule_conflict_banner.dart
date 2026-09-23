import 'package:flutter/material.dart';
import '../domain/schedule_conflict_result.dart';

class ScheduleConflictBanner extends StatelessWidget {
  final ScheduleConflictResult result;

  const ScheduleConflictBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasConflicts && !result.hasWarnings) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.hasConflicts)
          Card(
            color: Colors.red.shade50,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'XUNG ĐỘT BẮT BUỘC (Không thể xếp lịch):',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...result.hardConflicts.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• ${c.message}',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (result.hasWarnings)
          Card(
            color: Colors.amber.shade50,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade900,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CẢNH BÁO KHÔNG ƯU TIÊN (Vẫn được phép xếp):',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...result.softWarnings.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• ${c.message}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
