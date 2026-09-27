import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/common_widgets/navy_components.dart';
import '../../../app/design_system/app_theme.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../classes/presentation/class_controller.dart';
import '../../students/presentation/student_detail_page.dart';
import '../domain/credit_ledger_entry.dart';
import '../domain/monthly_credit_summary.dart';
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
    final l10n = AppLocalizations.of(context);
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
      backgroundColor: AppColors.background,
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: Text(l10n?.creditsTitle ?? 'Buổi dư & Credit'),
        actions: const [GlobalMenuButton()],
      ),
      body: summaryAsync.when(
        data: (summary) {
          final studentName =
              studentAsync.value?.hoTen ??
              l10n?.creditsHeaderStudent ??
              'Học sinh';
          final className =
              classAsync.value?.tenLop ?? l10n?.creditsHeaderClass ?? 'Lớp học';

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
                  l10n,
                ),
                const SizedBox(height: 16),
                _buildMonthSelector(context, l10n),
                const SizedBox(height: 16),
                _buildSummaryStatsCard(context, summary, l10n),
                const SizedBox(height: 16),
                _buildActionButtons(context, ref, summary, l10n),
                const SizedBox(height: 24),
                _buildCandidatesSection(context, summary, l10n),
                const SizedBox(height: 24),
                _buildLedgerHistorySection(context, ref, l10n),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
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
    AppLocalizations? l10n,
  ) {
    final balanceColor = closingBalance < 0
        ? AppColors.error
        : AppColors.cyanAccent;

    return AppSectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Lớp: $className',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: balanceColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: balanceColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  l10n?.creditsClosingBalance ?? 'Số dư cuối tháng',
                  style: TextStyle(
                    fontSize: 11,
                    color: balanceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${closingBalance >= 0 ? '+' : ''}$closingBalance buổi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, AppLocalizations? l10n) {
    final parts = _selectedMonth.split('-');
    final displayMonth = '${parts[1]}/${parts[0]}';

    return AppSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.cyanAccent),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            'Tháng $displayMonth',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.cyanAccent),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatsCard(
    BuildContext context,
    MonthlyCreditSummary summary,
    AppLocalizations? l10n,
  ) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.creditsSummaryTitle ?? 'Thống kê buổi học theo chuẩn',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Row 1: Standard breakdown (4 items flexed without overflow)
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  l10n?.creditsMaxStandard ?? 'Tối đa chuẩn',
                  '${summary.standardSessionLimit}',
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  l10n?.creditsEligible ?? 'Buổi học đủ điều kiện',
                  '${summary.eligibleCount}',
                  color: AppColors.cyanAccent,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  l10n?.creditsStandard ?? 'Buổi chuẩn',
                  '${summary.standardCount}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  l10n?.creditsExtra ?? 'Buổi dư (vượt chuẩn)',
                  '${summary.extraCount}',
                  color: summary.extraCount > 0
                      ? AppColors.cyanAccent
                      : AppColors.textMuted,
                  isHighlight: summary.extraCount > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Credit ledger summary (3 items flexed)
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  l10n?.creditsPotential ?? 'Đủ ĐK ghi credit',
                  '+${summary.potentialEarned}',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  l10n?.creditsRecorded ?? 'Đã ghi sổ',
                  '+${summary.recordedEarned}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  l10n?.creditsMonthDelta ?? 'Thay đổi trong tháng',
                  '${summary.monthDelta >= 0 ? '+' : ''}${summary.monthDelta}',
                  color: summary.monthDelta >= 0
                      ? AppColors.success
                      : AppColors.error,
                  isHighlight: summary.monthDelta != 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color? color,
    bool isHighlight = false,
  }) {
    final displayColor = color ?? AppColors.textPrimary;

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: displayColor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    MonthlyCreditSummary summary,
    AppLocalizations? l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('reconcile_credits_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showReconcileSheet(context, ref, summary, l10n),
            icon: const Icon(Icons.sync, size: 18),
            label: Text(
              l10n?.creditsReconcile ?? 'Đối soát buổi dư tháng này',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('manual_credit_btn'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showManualAdjustmentSheet(context, ref, l10n),
            icon: const Icon(
              Icons.edit_note,
              size: 18,
              color: AppColors.cyanAccent,
            ),
            label: Text(
              l10n?.creditsManualAdjustment ?? 'Điều chỉnh thủ công',
              style: const TextStyle(
                color: AppColors.cyanAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _showReconcileSheet(
    BuildContext context,
    WidgetRef ref,
    MonthlyCreditSummary summary,
    AppLocalizations? l10n,
  ) {
    final unrecorded = summary.potentialEarned - summary.recordedEarned;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đối soát buổi dư',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              Text(
                'Tháng: $_selectedMonth',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                'Số buổi đủ điều kiện: ${summary.eligibleCount}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                'Số buổi chuẩn: ${summary.standardCount}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                'Số buổi vượt chuẩn: ${summary.extraCount}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Số buổi vượt chuẩn có tham gia: ${summary.potentialEarned}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                'Số buổi đã ghi sổ credit: ${summary.recordedEarned}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (unrecorded > 0
                              ? AppColors.success
                              : AppColors.surfaceHigh)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unrecorded > 0
                      ? 'Sẽ ghi thêm +$unrecorded credit vào sổ dư.'
                      : 'Dữ liệu đã đồng bộ. Không có credit mới cần ghi.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unrecorded > 0
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: Text(l10n?.commonCancel ?? 'Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
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
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  AppFeedback.showSuccessSnackBar(
                                    context,
                                    'Đã đối soát credit thành công',
                                  );
                                }
                              } catch (e) {
                                if (sheetCtx.mounted) {
                                  AppFeedback.showErrorSnackBar(
                                    sheetCtx,
                                    e.toString().replaceAll('Exception: ', ''),
                                  );
                                }
                              }
                            }
                          : null,
                      child: const Text('Xác nhận đối soát'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualAdjustmentSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    final deltaController = TextEditingController(text: '1');
    DateTime effectiveDate = DateTime.now();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Điều chỉnh credit thủ công',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deltaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Số lượng (+1, -1, +2...)',
                      hintText: 'Nhập số buổi cộng/trừ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Ngày hiệu lực',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      DateFormatter.formatDisplayDate(effectiveDate),
                      style: const TextStyle(color: AppColors.cyanAccent),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: AppColors.cyanAccent,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: effectiveDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setSheetState(() => effectiveDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú bắt buộc',
                      hintText: 'Nhập lý do điều chỉnh thủ công',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: Text(l10n?.commonCancel ?? 'Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            try {
                              final delta = int.tryParse(
                                deltaController.text.trim(),
                              );
                              if (delta == null || delta == 0) {
                                throw Exception(
                                  'Số lượng điều chỉnh phải khác 0',
                                );
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
                                    effectiveDate:
                                        DateFormatter.formatCanonicalDate(
                                          effectiveDate,
                                        ),
                                    note: noteController.text.trim(),
                                  );
                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                                AppFeedback.showSuccessSnackBar(
                                  context,
                                  'Đã điều chỉnh credit thủ công',
                                );
                              }
                            } catch (e) {
                              if (sheetCtx.mounted) {
                                AppFeedback.showErrorSnackBar(
                                  sheetCtx,
                                  e.toString().replaceAll('Exception: ', ''),
                                );
                              }
                            }
                          },
                          child: Text(l10n?.commonSave ?? 'Lưu'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCandidatesSection(
    BuildContext context,
    MonthlyCreditSummary summary,
    AppLocalizations? l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title:
              l10n?.creditsCandidatesTitle ??
              'Danh sách buổi học đủ điều kiện trong tháng',
        ),
        const SizedBox(height: 8),
        if (summary.candidates.isEmpty)
          AppSectionCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  l10n?.creditsCandidatesEmpty ??
                      'Không có buổi học chính thức đã hoàn tất nào của học sinh trong tháng này.',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.candidates.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final c = summary.candidates[idx];
              final dateDisplay = DateFormatter.formatDisplayDate(
                c.session.ngay,
              );

              return AppSectionCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            (c.isExtra
                                    ? AppColors.cyanAccent
                                    : AppColors.primary)
                                .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${c.index}',
                        style: TextStyle(
                          color: c.isExtra
                              ? AppColors.cyanAccent
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dateDisplay (${c.session.gioBatDau} - ${c.session.gioKetThuc})',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Điểm danh: ${c.attendanceState.label}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppStatusChip(
                          label: c.isStandard
                              ? (l10n?.creditsStandardTag ?? 'Chuẩn')
                              : (l10n?.creditsExtraTag ?? 'Vượt chuẩn'),
                          color: c.isExtra
                              ? AppColors.cyanAccent
                              : AppColors.primary,
                          compact: true,
                        ),
                        if (c.earnsCredit) ...[
                          const SizedBox(height: 4),
                          Text(
                            c.existingEarnedLedgerEntry != null
                                ? (l10n?.creditsEarnedTag ?? 'Đã ghi +1')
                                : (l10n?.creditsCanEarnTag ?? 'Có thể ghi +1'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: c.existingEarnedLedgerEntry != null
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLedgerHistorySection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    final serviceAsync = ref.watch(sessionCreditServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n?.creditsLedgerTitle ?? 'Lịch sử sổ dư credit (Ledger)',
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
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return AppSectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      l10n?.creditsLedgerEmpty ??
                          'Chưa có lịch sử biến động credit nào.',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final entry = entries[i];
                final deltaStr = entry.delta >= 0
                    ? '+${entry.delta}'
                    : '${entry.delta}';
                final isPositive = entry.delta >= 0;
                final badgeColor = isPositive
                    ? AppColors.success
                    : AppColors.error;
                final dateDisplay = DateFormatter.formatDisplayDate(
                  entry.ngayHieuLuc,
                );

                return AppSectionCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          deltaStr,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.lyDo.label,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dateDisplay${entry.ghiChu != null ? " - ${entry.ghiChu}" : ""}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
