import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../tuition/domain/tuition_policy.dart';
import '../../tuition/presentation/create_center_tuition_policy_bottom_sheet.dart';
import '../../tuition/presentation/tuition_controller.dart';

class TuitionPolicySettingsPage extends ConsumerWidget {
  const TuitionPolicySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final policiesAsync = ref.watch(centerTuitionPoliciesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý chính sách học phí trung tâm')),
      body: policiesAsync.when(
        data: (policies) {
          final currentPolicy = policies.isNotEmpty ? policies.first : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: currentPolicy == null
                      ? Colors.amber.shade50
                      : Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Chính sách trung tâm chung',
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
                                await showCreateCenterTuitionPolicyBottomSheet(
                                  context,
                                  previousPolicy: currentPolicy,
                                );
                                ref.invalidate(centerTuitionPoliciesProvider);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Thêm / Đổi giá'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (currentPolicy == null)
                          const Text(
                            'Trung tâm chưa thiết lập chính sách học phí chung.',
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
                            'Hiệu lực từ: ${currentPolicy.hieuLucTu}${currentPolicy.hieuLucDen != null ? ' đến ${currentPolicy.hieuLucDen}' : ' (hiện tại)'}',
                          ),
                          Text(
                            'Nghỉ có phép: ${switch (currentPolicy.quyTacNghiCoPhep) {
                              ExcusedAbsenceFeeRule.buTruBuoiDu => 'Bù buổi / buổi dư',
                              ExcusedAbsenceFeeRule.tinhPhi => 'Có tính học phí',
                              ExcusedAbsenceFeeRule.khongTinhPhi => 'Không tính học phí',
                            }}',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải chính sách trung tâm: $e')),
      ),
    );
  }
}
