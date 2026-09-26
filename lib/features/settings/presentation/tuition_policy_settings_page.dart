import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../classes/presentation/class_controller.dart';
import '../../tuition/presentation/create_tuition_policy_bottom_sheet.dart';
import '../../tuition/presentation/tuition_controller.dart';

class TuitionPolicySettingsPage extends ConsumerStatefulWidget {
  final int? initialClassId;

  const TuitionPolicySettingsPage({super.key, this.initialClassId});

  @override
  ConsumerState<TuitionPolicySettingsPage> createState() =>
      _TuitionPolicySettingsPageState();
}

class _TuitionPolicySettingsPageState
    extends ConsumerState<TuitionPolicySettingsPage> {
  int? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classesAsync = ref.watch(classListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý chính sách học phí')),
      body: classesAsync.when(
        data: (classList) {
          final activeClasses = classList.where((c) => !c.daLuuTru).toList();

          if (activeClasses.isEmpty) {
            return const Center(
              child: Text('Không có lớp học nào đang hoạt động.'),
            );
          }

          if (_selectedClassId == null ||
              !activeClasses.any((c) => c.id == _selectedClassId)) {
            _selectedClassId = activeClasses.first.id;
          }

          final selectedClass = activeClasses.firstWhere(
            (c) => c.id == _selectedClassId,
          );
          final policiesAsync = ref.watch(
            classTuitionPoliciesProvider(_selectedClassId!),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn lớp học',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: activeClasses
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.tenLop),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedClassId = val);
                    }
                  },
                ),
                const SizedBox(height: 20),

                policiesAsync.when(
                  data: (policies) {
                    final currentPolicy = policies.isNotEmpty
                        ? policies.first
                        : null;

                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: currentPolicy == null
                                ? Colors.amber.shade50
                                : Colors.teal.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Chính sách hiện tại: ${selectedClass.tenLop}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: currentPolicy == null
                                                ? Colors.amber.shade900
                                                : Colors.teal.shade900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await showCreateTuitionPolicyBottomSheet(
                                            context,
                                            classId: _selectedClassId!,
                                          );
                                          ref.invalidate(
                                            classTuitionPoliciesProvider(
                                              _selectedClassId!,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Thêm CS'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (currentPolicy == null)
                                    const Text(
                                      'Lớp chưa thiết lập chính sách học phí.',
                                      style: TextStyle(color: Colors.red),
                                    )
                                  else ...[
                                    Text(
                                      'Học phí: ${NumberFormat('#,###').format(currentPolicy.hocPhiMoiBuoi)}đ / buổi',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Số buổi chuẩn tháng: ${currentPolicy.soBuoiChuanThang} buổi',
                                    ),
                                    if (currentPolicy.hocPhiThangToiDa != null)
                                      Text(
                                        'Trần học phí tháng: ${NumberFormat('#,###').format(currentPolicy.hocPhiThangToiDa)}đ',
                                      ),
                                    Text(
                                      'Hiệu lực từ: ${currentPolicy.hieuLucTu}${currentPolicy.hieuLucDen != null ? ' đến ${currentPolicy.hieuLucDen}' : ''}',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Lịch sử chính sách (${policies.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: policies.isEmpty
                                ? const Center(
                                    child: Text('Chưa có lịch sử chính sách.'),
                                  )
                                : ListView.builder(
                                    itemCount: policies.length,
                                    itemBuilder: (context, index) {
                                      final p = policies[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            '${NumberFormat('#,###').format(p.hocPhiMoiBuoi)}đ / buổi (Chuẩn: ${p.soBuoiChuanThang} buổi)',
                                          ),
                                          subtitle: Text(
                                            'Hiệu lực: ${p.hieuLucTu}${p.hieuLucDen != null ? ' đến ${p.hieuLucDen}' : ' (Hiện tại)'}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Lỗi tải chính sách: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải danh sách lớp: $e')),
      ),
    );
  }
}
