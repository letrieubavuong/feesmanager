import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../classes/domain/class.dart';
import '../../classes/presentation/class_controller.dart';
import 'class_tuition_tab.dart';

class GlobalTuitionPage extends ConsumerStatefulWidget {
  const GlobalTuitionPage({super.key});

  @override
  ConsumerState<GlobalTuitionPage> createState() => _GlobalTuitionPageState();
}

class _GlobalTuitionPageState extends ConsumerState<GlobalTuitionPage> {
  int? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Học phí')),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child: Text('Chưa có lớp học nào trong hệ thống.'),
            );
          }

          _selectedClassId ??= classes.first.id;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Text(
                      'Chọn lớp học: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedClassId,
                        isExpanded: true,
                        items: classes.map((ClassEntity c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.tenLop),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedClassId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedClassId != null)
                Expanded(child: ClassTuitionTab(classId: _selectedClassId!)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải danh sách lớp: $e')),
      ),
    );
  }
}
