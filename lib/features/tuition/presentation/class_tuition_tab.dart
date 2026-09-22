import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../memberships/domain/membership.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/tuition_invoice.dart';
import '../domain/tuition_policy.dart';
import '../domain/tuition_policy_service.dart';
import '../domain/tuition_preview.dart';
import 'tuition_controller.dart';

class ClassTuitionTab extends ConsumerStatefulWidget {
  final int classId;

  const ClassTuitionTab({super.key, required this.classId});

  @override
  ConsumerState<ClassTuitionTab> createState() => _ClassTuitionTabState();
}

class _ClassTuitionTabState extends ConsumerState<ClassTuitionTab> {
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  }

  void _changeMonth(int deltaMonths) {
    final parsed = DateTime.parse('$_selectedMonth-01');
    final newDate = DateTime(parsed.year, parsed.month + deltaMonths, 1);
    setState(() {
      _selectedMonth = DateFormat('yyyy-MM').format(newDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(
      classTuitionPoliciesProvider(widget.classId),
    );
    final rosterAsync = ref.watch(
      classMonthMembershipsProvider((widget.classId, _selectedMonth)),
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(context),
            const SizedBox(height: 16),
            _buildPolicyHeader(context, policiesAsync),
            const SizedBox(height: 16),
            _buildClassFinalizeHeader(context),
            const SizedBox(height: 16),
            _buildStudentTuitionList(context, rosterAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final formattedMonth = DateFormat(
      'MM/yyyy',
    ).format(DateTime.parse('$_selectedMonth-01'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              'Tháng $formattedMonth',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyHeader(
    BuildContext context,
    AsyncValue<List<TuitionPolicy>> policiesAsync,
  ) {
    return policiesAsync.when(
      data: (policies) {
        final dateStr = '$_selectedMonth-01';
        final activePolicy = policies.cast<TuitionPolicy?>().firstWhere(
          (p) =>
              p != null &&
              p.hieuLucTu.compareTo(dateStr) <= 0 &&
              (p.hieuLucDen == null || p.hieuLucDen!.compareTo(dateStr) >= 0),
          orElse: () => null,
        );

        return Card(
          elevation: 2,
          color: activePolicy == null
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
                    Text(
                      'Chính sách học phí',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: activePolicy == null
                            ? Colors.amber.shade900
                            : Colors.teal.shade900,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showPolicyHistoryDialog(context, policies),
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Lịch sử CS'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreatePolicyDialog(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Thêm CS'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (activePolicy == null)
                  const Text(
                    'Lớp chưa có chính sách học phí có hiệu lực cho tháng này. Vui lòng tạo chính sách học phí.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else ...[
                  Text(
                    'Học phí: ${NumberFormat('#,###').format(activePolicy.hocPhiMoiBuoi)}đ / buổi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số buổi chuẩn tháng: ${activePolicy.soBuoiChuanThang} buổi',
                  ),
                  if (activePolicy.hocPhiThangToiDa != null)
                    Text(
                      'Trần học phí tháng: ${NumberFormat('#,###').format(activePolicy.hocPhiThangToiDa)}đ',
                    ),
                  Text(
                    'Hiệu lực: Từ ${activePolicy.hieuLucTu}${activePolicy.hieuLucDen != null ? ' đến ${activePolicy.hieuLucDen}' : ' (Hiện tại)'}',
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Lỗi tải chính sách học phí: $e'),
    );
  }

  Widget _buildClassFinalizeHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Danh sách học phí học sinh',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: () => _showFinalizeClassDialog(context),
          icon: const Icon(Icons.verified),
          label: const Text('Chốt học phí cả lớp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTuitionList(
    BuildContext context,
    AsyncValue<List<ClassMembership>> rosterAsync,
  ) {
    return rosterAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Lớp không có học sinh nào trong tháng này.'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final m = memberships[index];
            return _StudentTuitionCard(
              studentId: m.idHocSinh,
              classId: widget.classId,
              month: _selectedMonth,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Lỗi tải danh sách học sinh: $e'),
    );
  }

  void _showPolicyHistoryDialog(
    BuildContext context,
    List<TuitionPolicy> policies,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Lịch sử chính sách học phí'),
        content: SizedBox(
          width: double.maxFinite,
          child: policies.isEmpty
              ? const Text('Chưa có chính sách nào.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: policies.length,
                  itemBuilder: (ctx, i) {
                    final p = policies[i];
                    return ListTile(
                      title: Text(
                        '${NumberFormat('#,###').format(p.hocPhiMoiBuoi)}đ/buổi (N=${p.soBuoiChuanThang})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Từ ${p.hieuLucTu}${p.hieuLucDen != null ? ' đến ${p.hieuLucDen}' : ' (Hiện tại)'}',
                      ),
                      trailing: p.hocPhiThangToiDa != null
                          ? Text(
                              'Cap: ${NumberFormat('#,###').format(p.hocPhiThangToiDa)}đ',
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showCreatePolicyDialog(BuildContext context) {
    final fromController = TextEditingController(text: '$_selectedMonth-01');
    final feeController = TextEditingController(text: '50000');
    final standardController = TextEditingController(text: '12');
    final capController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Thêm chính sách học phí'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fromController,
                decoration: const InputDecoration(
                  labelText: 'Hiệu lực từ ngày (YYYY-MM-DD)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: feeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Học phí mỗi buổi (đ)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: standardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số buổi chuẩn trong tháng',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Trần học phí tháng (để trống nếu không có)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final feeText = feeController.text.trim();
                final fee = int.tryParse(feeText);
                if (fee == null || fee < 0) {
                  throw Exception('Học phí mỗi buổi không hợp lệ');
                }

                final standardText = standardController.text.trim();
                final standard = int.tryParse(standardText);
                if (standard == null || standard <= 0) {
                  throw Exception('Số buổi chuẩn tháng phải lớn hơn 0');
                }

                final capStr = capController.text.trim();
                int? cap;
                if (capStr.isNotEmpty) {
                  cap = int.tryParse(capStr);
                  if (cap == null || cap < 0) {
                    throw Exception('Trần học phí tháng không hợp lệ');
                  }
                }

                final service = await ref.read(
                  tuitionPolicyServiceProvider.future,
                );
                await service.createPolicy(
                  classId: widget.classId,
                  effectiveFrom: fromController.text.trim(),
                  feePerSession: fee,
                  standardSessionsPerMonth: standard,
                  monthlyMaxFee: cap,
                  note: noteController.text.trim(),
                );

                ref.invalidate(classTuitionPoliciesProvider(widget.classId));
                ref.invalidate(
                  classMonthMembershipsProvider((
                    widget.classId,
                    _selectedMonth,
                  )),
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              } catch (e) {
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(
                    dialogCtx,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Lưu chính sách'),
          ),
        ],
      ),
    );
  }

  void _showFinalizeClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Chốt học phí cả lớp'),
        content: Text(
          'Bạn có chắc chắn muốn chốt học phí cả lớp cho tháng $_selectedMonth?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(invoiceControllerProvider.notifier)
                    .finalizeClassInvoices(
                      classId: widget.classId,
                      month: _selectedMonth,
                    );
                ref.invalidate(classTuitionPoliciesProvider(widget.classId));
                ref.invalidate(
                  classMonthMembershipsProvider((
                    widget.classId,
                    _selectedMonth,
                  )),
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã chốt học phí cả lớp thành công!'),
                    ),
                  );
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi chốt học phí cả lớp: $e')),
                  );
                }
              }
            },
            child: const Text('Xác nhận chốt'),
          ),
        ],
      ),
    );
  }
}

class _StudentTuitionCard extends ConsumerWidget {
  final int studentId;
  final int classId;
  final String month;

  const _StudentTuitionCard({
    required this.studentId,
    required this.classId,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));
    final previewAsync = ref.watch(
      tuitionPreviewControllerProvider(studentId, classId, month),
    );
    final invoiceAsync = ref.watch(
      studentInvoiceProvider(studentId, classId, month),
    );

    return studentAsync.when(
      data: (student) {
        if (student == null) return const SizedBox.shrink();

        final invoice = invoiceAsync.value;
        final isFinalized = invoice?.trangThai == TuitionInvoiceStatus.DA_CHOT;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: isFinalized
                ? _buildFinalizedInvoiceSnapshot(
                    context,
                    student.hoTen,
                    invoice!,
                  )
                : previewAsync.when(
                    data: (preview) => _buildDraftPreviewCard(
                      context,
                      ref,
                      student.hoTen,
                      preview,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Chưa thể xem trước học phí: $e'),
                  ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Lỗi học sinh: $e'),
    );
  }

  Widget _buildFinalizedInvoiceSnapshot(
    BuildContext context,
    String studentName,
    TuitionInvoice invoice,
  ) {
    final formattedDate = invoice.chotLuc != null
        ? DateFormat('HH:mm dd/MM/yyyy').format(invoice.chotLuc!)
        : 'Đã chốt';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              studentName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Chip(
              label: Text(
                'ĐÃ CHỐT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.teal,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Số buổi eligible: ${invoice.soBuoiEligible} (Tính phí: ${invoice.soBuoiTinhPhi})',
              ),
            ),
            Text(
              'Phải thu: ${NumberFormat('#,###').format(invoice.soTienPhaiThu)}đ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        if (invoice.giamPhanTram > 0)
          Text(
            'Miễn giảm: ${invoice.giamPhanTram}% (-${NumberFormat('#,###').format(invoice.giamSoTien)}đ)',
            style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
          ),
        const SizedBox(height: 4),
        Text(
          'Credit sổ cái snapshot: Đầu ${invoice.creditOpening} | Đã cộng +${invoice.creditEarned} | Đã dùng -${invoice.creditUsed} | Cuối ${invoice.creditClosing}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          'Thời điểm chốt: $formattedDate',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDraftPreviewCard(
    BuildContext context,
    WidgetRef ref,
    String studentName,
    TuitionPreview preview,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              studentName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Chip(
              label: const Text(
                'NHÁP',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Số buổi eligible: ${preview.soBuoiEligible} (Tính phí: ${preview.soBuoiTinhPhi})',
              ),
            ),
            Text(
              'Phải thu: ${NumberFormat('#,###').format(preview.soTienPhaiThu)}đ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        if (preview.giamPhanTram > 0)
          Text(
            'Miễn giảm: ${preview.giamPhanTram}% (-${NumberFormat('#,###').format(preview.giamSoTien)}đ)',
            style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
          ),
        const SizedBox(height: 4),
        Text(
          'Credit sổ cái: Đầu ${preview.creditOpening} | Đã cộng +${preview.creditEarned} | Đã dùng -${preview.creditUsed} | Cuối ${preview.creditClosing}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await ref
                    .read(invoiceControllerProvider.notifier)
                    .finalizeStudentInvoice(
                      studentId: studentId,
                      classId: classId,
                      month: month,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chốt học phí cho $studentName!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Chốt học phí'),
          ),
        ),
      ],
    );
  }
}
