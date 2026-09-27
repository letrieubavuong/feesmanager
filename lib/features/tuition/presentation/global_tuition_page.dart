import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
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
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: const Text('Quản lý Học phí'),
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có lớp học nào trong hệ thống.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          _selectedClassId ??= classes.first.id;

          return Column(
            children: [
              AppSectionCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: AppColors.cyanAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Lớp học: ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedClassId,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceHigh,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
                    ),
                  ],
                ),
              ),
              if (_selectedClassId != null)
                Expanded(child: ClassTuitionTab(classId: _selectedClassId!)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Lỗi tải danh sách lớp: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
