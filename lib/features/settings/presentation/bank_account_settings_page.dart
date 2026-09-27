import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';
import '../domain/bank_account_settings.dart';
import '../domain/vietqr_generator.dart';
import 'bank_account_settings_controller.dart';

class BankAccountSettingsPage extends ConsumerStatefulWidget {
  const BankAccountSettingsPage({super.key});

  @override
  ConsumerState<BankAccountSettingsPage> createState() =>
      _BankAccountSettingsPageState();
}

class _BankAccountSettingsPageState
    extends ConsumerState<BankAccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late BankInfo _selectedBank;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountHolderController;
  late TextEditingController _templateController;

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _accountNumberController = TextEditingController();
    _accountHolderController = TextEditingController();
    _templateController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final settings = ref.read(bankAccountSettingsProvider);
      _selectedBank = SupportedBanks.findByCodeOrBin(settings.bankBin);
      _accountNumberController.text = settings.accountNumber;
      _accountHolderController.text = settings.accountHolder;
      _templateController.text = settings.transferTemplate;
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _templateController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (!_formKey.currentState!.validate()) return;

    final newSettings = BankAccountSettings(
      bankName: _selectedBank.name,
      bankCode: _selectedBank.code,
      bankBin: _selectedBank.bin,
      accountNumber: _accountNumberController.text.trim(),
      accountHolder: _accountHolderController.text.trim().toUpperCase(),
      transferTemplate: _templateController.text.trim(),
    );

    ref.read(bankAccountSettingsProvider.notifier).updateSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu thông tin tài khoản nhận học phí'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentPreviewSettings = BankAccountSettings(
      bankName: _selectedBank.name,
      bankCode: _selectedBank.code,
      bankBin: _selectedBank.bin,
      accountNumber: _accountNumberController.text.trim(),
      accountHolder: _accountHolderController.text.trim().toUpperCase(),
      transferTemplate: _templateController.text.trim(),
    );

    final qrPayload = VietQrGenerator.generateEmvCoPayload(
      settings: currentPreviewSettings,
      amount: 500000,
      transferContent: VietQrGenerator.formatTransferContent(
        template: currentPreviewSettings.transferTemplate,
        studentCode: 'HS001',
        month: '09/2026',
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản nhận học phí')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THÔNG TIN TÀI KHOẢN NGÂN HÀNG',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Bank Selector Dropdown
                      DropdownButtonFormField<BankInfo>(
                        initialValue: _selectedBank,
                        decoration: const InputDecoration(
                          labelText: 'Ngân hàng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        items: SupportedBanks.list.map((bank) {
                          return DropdownMenuItem<BankInfo>(
                            value: bank,
                            child: Text('${bank.name} (${bank.code})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedBank = val;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // 2. Account Number Field
                      TextFormField(
                        key: const Key('account_number_input'),
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số tài khoản',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: 'Ví dụ: 0123456789',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập số tài khoản';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 3. Account Holder Field
                      TextFormField(
                        key: const Key('account_holder_input'),
                        controller: _accountHolderController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Tên chủ tài khoản',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'Ví dụ: NGUYEN VAN A',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập tên chủ tài khoản';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 4. Transfer Template Field
                      TextFormField(
                        controller: _templateController,
                        decoration: const InputDecoration(
                          labelText: 'Mẫu nội dung chuyển khoản',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                          hintText: 'Mẫu: HP {maHocSinh} {thang}',
                          helperText:
                              'Dùng {maHocSinh} cho mã/ID học sinh, {thang} cho tháng',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập mẫu nội dung chuyển khoản';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          key: const Key('save_bank_account_btn'),
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'Lưu thông tin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _saveSettings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- PREVIEW SECTION ---
              Text(
                'XEM TRƯỚC VIETQR',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: currentPreviewSettings.isConfigured
                      ? Column(
                          children: [
                            Text(
                              currentPreviewSettings.bankName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'STK: ${currentPreviewSettings.accountNumber}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Chủ TK: ${currentPreviewSettings.accountHolder}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // QR Display
                            if (qrPayload.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: CustomPaint(
                                    painter: QrWidgetPainter(
                                      data: qrPayload,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),
                            Text(
                              'Nội dung mẫu (Ví dụ 500.000đ, HS001, 09/2026):',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Chip(
                              label: Text(
                                VietQrGenerator.formatTransferContent(
                                  template:
                                      currentPreviewSettings.transferTemplate,
                                  studentCode: 'HS001',
                                  month: '09/2026',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                            ),
                          ],
                        )
                      : const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'Nhập số tài khoản và tên chủ tài khoản để tạo mã VietQR xem trước.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QrWidgetPainter extends CustomPainter {
  final String data;
  final Color color;

  QrWidgetPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);
      final moduleSize = size.width / qrImage.moduleCount;
      final paint = Paint()..color = color;

      for (int x = 0; x < qrImage.moduleCount; x++) {
        for (int y = 0; y < qrImage.moduleCount; y++) {
          if (qrImage.isDark(y, x)) {
            canvas.drawRect(
              Rect.fromLTWH(
                x * moduleSize,
                y * moduleSize,
                moduleSize,
                moduleSize,
              ),
              paint,
            );
          }
        }
      }
    } catch (_) {
      // Fallback if data exceeds capacity
    }
  }

  @override
  bool shouldRepaint(covariant QrWidgetPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
