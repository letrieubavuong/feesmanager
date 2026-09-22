import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../memberships/presentation/membership_providers.dart';
import '../../payments/domain/invoice_payment_summary.dart';
import '../../payments/domain/payment.dart';
import '../../payments/domain/payment_method.dart';
import '../../payments/presentation/payment_controller.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/tuition_invoice.dart';
import '../domain/tuition_policy.dart';
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
    final effectivePolicyAsync = ref.watch(
      effectiveTuitionPolicyProvider((widget.classId, _selectedMonth)),
    );
    final rosterAsync = ref.watch(
      classMonthStudentsProvider((widget.classId, _selectedMonth)),
    );
    final paymentSummariesAsync = ref.watch(
      classMonthPaymentSummariesProvider((widget.classId, _selectedMonth)),
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(context),
            const SizedBox(height: 16),
            _buildPolicyHeader(context, effectivePolicyAsync, policiesAsync),
            const SizedBox(height: 16),
            _buildClassFinalizeHeader(context),
            const SizedBox(height: 16),
            _buildStudentTuitionList(
              context,
              rosterAsync,
              paymentSummariesAsync,
            ),
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
    AsyncValue<TuitionPolicy?> effectivePolicyAsync,
    AsyncValue<List<TuitionPolicy>> policiesAsync,
  ) {
    final policies = policiesAsync.value ?? [];

    return effectivePolicyAsync.when(
      data: (activePolicy) {
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
    AsyncValue<List<Student>> rosterAsync,
    AsyncValue<Map<int, InvoicePaymentSummary>> paymentSummariesAsync,
  ) {
    return rosterAsync.when(
      data: (students) {
        if (students.isEmpty) {
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
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return _StudentTuitionCard(
              studentId: student.id!,
              classId: widget.classId,
              month: _selectedMonth,
              paymentSummariesAsync: paymentSummariesAsync,
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

                await ref
                    .read(tuitionPolicyControllerProvider.notifier)
                    .createPolicy(
                      classId: widget.classId,
                      effectiveFrom: fromController.text.trim(),
                      feePerSession: fee,
                      standardSessionsPerMonth: standard,
                      monthlyMaxFee: cap,
                      note: noteController.text.trim(),
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
  final AsyncValue<Map<int, InvoicePaymentSummary>> paymentSummariesAsync;

  const _StudentTuitionCard({
    required this.studentId,
    required this.classId,
    required this.month,
    required this.paymentSummariesAsync,
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
        final isFinalized = invoice?.trangThai.isFinalizedSnapshot == true;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: isFinalized
                ? _buildFinalizedInvoiceSnapshot(
                    context,
                    ref,
                    student.hoTen,
                    invoice!,
                    paymentSummariesAsync,
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
    WidgetRef ref,
    String studentName,
    TuitionInvoice invoice,
    AsyncValue<Map<int, InvoicePaymentSummary>> summariesAsync,
  ) {
    return summariesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Đang tải dữ liệu thanh toán...',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      error: (e, _) => Text(
        'Lỗi dữ liệu thanh toán: $e',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
      data: (summaries) {
        final summary = summaries[studentId];
        if (summary == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lỗi dữ liệu thanh toán: Không tìm thấy tổng hợp thanh toán cho hóa đơn này.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          );
        }

        final totalPaid = summary.totalPaid;
        final remainingDebt = summary.remainingDebt;
        final settlementStatus = summary.settlementStatus;

        final statusLabel = switch (settlementStatus) {
          TuitionInvoiceStatus.DA_CHOT => 'ĐÃ CHỐT',
          TuitionInvoiceStatus.DA_THANH_TOAN => 'ĐÃ THANH TOÁN',
          TuitionInvoiceStatus.CON_NO => 'CÒN NỢ',
          TuitionInvoiceStatus.NHAP => 'NHÁP',
        };

        final statusColor = switch (settlementStatus) {
          TuitionInvoiceStatus.DA_CHOT => Colors.teal,
          TuitionInvoiceStatus.DA_THANH_TOAN => Colors.green.shade700,
          TuitionInvoiceStatus.CON_NO => Colors.red.shade700,
          TuitionInvoiceStatus.NHAP => Colors.grey,
        };

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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Phải thu: ${NumberFormat('#,###').format(invoice.soTienPhaiThu)}đ | Đã trả: ${NumberFormat('#,###').format(totalPaid)}đ',
                  ),
                ),
                Text(
                  'Còn lại: ${NumberFormat('#,###').format(remainingDebt)}đ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: remainingDebt > 0
                        ? Colors.red.shade800
                        : Colors.teal,
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (summary.payments.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showPaymentHistoryDialog(context, summary.payments),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Lịch sử TT'),
                  ),
                if (remainingDebt > 0 && invoice.soTienPhaiThu > 0)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showRecordPaymentDialog(context, ref, remainingDebt),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Thanh toán'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
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

  void _showRecordPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    int remainingDebt,
  ) {
    final amountController = TextEditingController(text: '$remainingDebt');
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    PaymentMethod selectedMethod = PaymentMethod.CHUYEN_KHOAN;
    final txController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ghi nhận thanh toán'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền thanh toán (đ)',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Ngày thanh toán (YYYY-MM-DD)',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final initialDt =
                            DateTime.tryParse(dateController.text.trim()) ??
                            DateTime.now();
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate: initialDt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Phương thức thanh toán',
                  ),
                  items: PaymentMethod.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedMethod = val);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: txController,
                  decoration: const InputDecoration(
                    labelText: 'Mã giao dịch (Không bắt buộc)',
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
                  final amountText = amountController.text.trim();
                  final amount = int.tryParse(amountText);
                  if (amount == null || amount <= 0) {
                    throw Exception('Số tiền thanh toán không hợp lệ');
                  }

                  await ref
                      .read(paymentControllerProvider.notifier)
                      .recordPayment(
                        studentId: studentId,
                        classId: classId,
                        month: month,
                        amount: amount,
                        paymentDate: dateController.text.trim(),
                        method: selectedMethod,
                        transactionId: txController.text.trim(),
                        note: noteController.text.trim(),
                      );

                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã ghi nhận thanh toán thành công!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              child: const Text('Thực hiện thanh toán'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistoryDialog(BuildContext context, List<Payment> payments) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Lịch sử thanh toán'),
        content: SizedBox(
          width: double.maxFinite,
          child: payments.isEmpty
              ? const Text('Chưa có thanh toán nào.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: payments.length,
                  itemBuilder: (ctx, i) {
                    final p = payments[i];
                    return ListTile(
                      title: Text(
                        '${NumberFormat('#,###').format(p.amount)}đ (${p.method.displayName})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Ngày: ${p.paymentDate}${p.transactionId != null ? " | Mã GD: ${p.transactionId}" : ""}${p.note != null ? " | Ghi chú: ${p.note}" : ""}',
                      ),
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
}
