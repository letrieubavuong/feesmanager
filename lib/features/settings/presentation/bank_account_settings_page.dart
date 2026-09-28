import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../payments/presentation/widgets/vietqr_code_widget.dart';
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

  void _saveSettings(AppLocalizations l10n) {
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
      SnackBar(
        content: Text(l10n.bankAccountSaveSuccess),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
      appBar: AppBar(title: Text(l10n.settingsBankAccount)),
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
                        l10n.bankAccountTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Bank Selector Dropdown
                      DropdownButtonFormField<BankInfo>(
                        initialValue: _selectedBank,
                        decoration: InputDecoration(
                          labelText: l10n.bankName,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.account_balance),
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
                        decoration: InputDecoration(
                          labelText: l10n.bankAccountNumber,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.credit_card),
                          hintText: '0123456789',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.bankAccountValidationNumber;
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
                        decoration: InputDecoration(
                          labelText: l10n.bankAccountHolder,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person),
                          hintText: 'NGUYEN VAN A',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.bankAccountValidationHolder;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 4. Transfer Template Field
                      TextFormField(
                        controller: _templateController,
                        decoration: InputDecoration(
                          labelText: l10n.bankTransferTemplate,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.notes),
                          hintText: 'HP {maHocSinh} {thang}',
                          helperText: l10n.bankTransferTemplateHelper(
                            '{maHocSinh}',
                            '{thang}',
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.bankAccountValidationTemplate;
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
                          label: Text(
                            l10n.commonSave,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _saveSettings(l10n),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- PREVIEW SECTION ---
              Text(
                l10n.vietQrPreviewTitle,
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
                              '${l10n.bankAccountNumber}: ${currentPreviewSettings.accountNumber}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${l10n.bankAccountHolder}: ${currentPreviewSettings.accountHolder}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // QR Display
                            if (qrPayload.isNotEmpty)
                              VietQrCodeWidget(payload: qrPayload, size: 180),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              l10n.vietQrNotConfigured,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
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
