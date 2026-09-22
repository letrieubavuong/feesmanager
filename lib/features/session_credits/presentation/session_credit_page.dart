import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../classes/presentation/class_controller.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/credit_ledger_entry.dart';
import '../domain/session_credit_service.dart';
import 'session_credit_controller.dart';

class SessionCreditPage extends ConsumerStatefulWidget {
  final int studentId;
  final int classId;
  final String? initialMonth;

  const SessionCreditPage({
    super.key,
    required this.studentId,
    required this.classId,
    this.initialMonth,
  });

  @override
  ConsumerState<SessionCreditPage> createState() => _SessionCreditPageState();
}

class _SessionCreditPageState extends ConsumerState<SessionCreditPage> {
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth =
        widget.initialMonth ?? DateFormat('yyyy-MM').format(DateTime.now());
  }

  void _changeMonth(int offsetMonths) {
    final parts = _selectedMonth.split('-');
    final current = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final next = DateTime(current.year, current.month + offsetMonths);
    setState(() {
      _selectedMonth = DateFormat('yyyy-MM').format(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(
      sessionCreditControllerProvider(
        widget.studentId,
        widget.classId,
        _selectedMonth,
      ),
    );
    final studentAsync = ref.watch(studentDetailProvider(widget.studentId));
    final classAsync = ref.watch(classDetailProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(title: const Text('Buổi dư & Credit')),
      body: summaryAsync.when(
        data: (summary) {
          final studentName = studentAsync.value?.hoTen ?? 'Học sinh';
          final className = classAsync.value?.tenLop ?? 'Lớp học';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(
                  context,
                  studentName,
                  className,
                  summary.closingBalance,
                ),
                const SizedBox(height: 16),
                _buildMonthSelector(context),
                const SizedBox(height: 16),
                _buildSummaryStatsCard(context, summary),
                const SizedBox(height: 16),
                _buildActionButtons(context, ref, summary),
                const SizedBox(height: 24),
                _buildCandidatesSection(context, summary),
                const SizedBox(height: 24),
                _buildLedgerHistorySection(context, ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(err.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    String studentName,
    String className,
    int closingBalance,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lớp: $className',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: closingBalance < 0
                    ? Colors.red.shade50
                    : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: closingBalance < 0 ? Colors.red : Colors.teal,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Số dư cuối tháng',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${closingBalance >= 0 ? '+' : ''}$closingBalance buổi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: closingBalance < 0 ? Colors.red : Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final parts = _selectedMonth.split('-');
    final displayMonth = '${parts[1]}/${parts[0]}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          'Tháng $displayMonth',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildSummaryStatsCard(BuildContext context, summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê buổi học theo chuẩn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Tối đa chuẩn',
                  '${summary.standardSessionLimit}',
                ),
                _buildStatItem(
                  'Buổi học đủ điều kiện',
                  '${summary.eligibleCount}',
                ),
                _buildStatItem('Buổi chuẩn', '${summary.standardCount}'),
                _buildStatItem(
                  'Buổi dư (vượt chuẩn)',
                  '${summary.extraCount}',
                  isHighlight: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Đủ ĐK ghi credit',
                  '+${summary.potentialEarned}',
                ),
                _buildStatItem('Đã ghi sổ', '+${summary.recordedEarned}'),
                _buildStatItem(
                  'Thay đổi trong tháng',
                  '${summary.monthDelta >= 0 ? '+' : ''}${summary.monthDelta}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.teal : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, summary) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showReconcileDialog(context, ref, summary),
            icon: const Icon(Icons.sync),
            label: const Text('Đối soát buổi dư tháng này'),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _showManualAdjustmentDialog(context, ref),
          icon: const Icon(Icons.edit_note),
          label: const Text('Điều chỉnh thủ công'),
        ),
      ],
    );
  }

  void _showReconcileDialog(BuildContext context, WidgetRef ref, summary) {
    final unrecorded = summary.potentialEarned - summary.recordedEarned;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Đối soát buổi dư'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tháng: $_selectedMonth'),
            const SizedBox(height: 8),
            Text('Số buổi đủ điều kiện: ${summary.eligibleCount}'),
            Text('Số buổi chuẩn: ${summary.standardCount}'),
            Text('Số buổi vượt chuẩn: ${summary.extraCount}'),
            const SizedBox(height: 8),
            Text('Số buổi vượt chuẩn có tham gia: ${summary.potentialEarned}'),
            Text('Số buổi đã ghi sổ credit: ${summary.recordedEarned}'),
            const Divider(),
            Text(
              unrecorded > 0
                  ? 'Sẽ ghi thêm +$unrecorded credit vào sổ dư.'
                  : 'Dữ liệu đã đồng bộ. Không có credit mới cần ghi.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: unrecorded > 0 ? Colors.teal : Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: unrecorded > 0
                ? () async {
                    try {
                      await ref
                          .read(
                            sessionCreditControllerProvider(
                              widget.studentId,
                              widget.classId,
                              _selectedMonth,
                            ).notifier,
                          )
                          .reconcile();
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    } catch (e) {
                      if (dialogCtx.mounted) {
                        _showErrorDialog(dialogCtx, e.toString());
                      }
                    }
                  }
                : null,
            child: const Text('Xác nhận đối soát'),
          ),
        ],
      ),
    );
  }

  void _showManualAdjustmentDialog(BuildContext context, WidgetRef ref) {
    final deltaController = TextEditingController(text: '1');
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Điều chỉnh credit thủ công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deltaController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Số lượng (+1, -1, +2...)',
                hintText: 'Nhập số buổi cộng/trừ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Ngày hiệu lực (YYYY-MM-DD)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú bắt buộc',
                hintText: 'Nhập lý do điều chỉnh thủ công',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final delta = int.tryParse(deltaController.text.trim());
                if (delta == null || delta == 0) {
                  throw Exception('Số lượng điều chỉnh phải khác 0');
                }
                await ref
                    .read(
                      sessionCreditControllerProvider(
                        widget.studentId,
                        widget.classId,
                        _selectedMonth,
                      ).notifier,
                    )
                    .addManualAdjustment(
                      delta: delta,
                      effectiveDate: dateController.text.trim(),
                      note: noteController.text.trim(),
                    );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              } catch (e) {
                if (dialogCtx.mounted) {
                  _showErrorDialog(dialogCtx, e.toString());
                }
              }
            },
            child: const Text('Lưu điều chỉnh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesSection(BuildContext context, summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách buổi học đủ điều kiện trong tháng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (summary.candidates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Không có buổi học chính thức đã hoàn tất nào của học sinh trong tháng này.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.candidates.length,
            separatorBuilder: (ctx, idx) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final c = summary.candidates[idx];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.isExtra ? Colors.teal : Colors.blue,
                  child: Text(
                    '#${c.index}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(
                  '${c.session.ngay} (${c.session.gioBatDau} - ${c.session.gioKetThuc})',
                ),
                subtitle: Text('Điểm danh: ${c.attendanceState.label}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Card(
                      color: c.isExtra
                          ? Colors.teal.shade100
                          : Colors.blue.shade100,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          c.isStandard ? 'Chuẩn' : 'Vượt chuẩn',
                          style: TextStyle(
                            fontSize: 11,
                            color: c.isExtra
                                ? Colors.teal.shade900
                                : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ),
                    if (c.earnsCredit)
                      Text(
                        c.existingEarnedLedgerEntry != null
                            ? 'Đã ghi +1'
                            : 'Có thể ghi +1',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: c.existingEarnedLedgerEntry != null
                              ? Colors.teal
                              : Colors.orange,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLedgerHistorySection(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(sessionCreditServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử sổ dư credit (Ledger)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<CreditLedgerEntry>>(
          future: serviceAsync.when(
            data: (service) =>
                service.getLedger(widget.studentId, widget.classId),
            loading: () => Future.value([]),
            error: (_, __) => Future.value([]),
          ),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Chưa có lịch sử biến động credit nào.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (c, i) {
                final entry = entries[i];
                final deltaStr = entry.delta >= 0
                    ? '+${entry.delta}'
                    : '${entry.delta}';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: entry.delta >= 0
                        ? Colors.teal.shade100
                        : Colors.red.shade100,
                    child: Text(
                      deltaStr,
                      style: TextStyle(
                        color: entry.delta >= 0
                            ? Colors.teal.shade900
                            : Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(entry.lyDo.label),
                  subtitle: Text(
                    'Ngày: ${entry.ngayHieuLuc}${entry.ghiChu != null ? ' - ${entry.ghiChu}' : ''}',
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
