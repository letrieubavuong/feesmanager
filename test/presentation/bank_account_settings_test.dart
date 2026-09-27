import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuition2027/features/settings/domain/bank_account_settings.dart';
import 'package:tuition2027/features/settings/domain/vietqr_generator.dart';
import 'package:tuition2027/features/settings/presentation/bank_account_settings_page.dart';

void main() {
  group('Bank Account & VietQR Settings Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('BankAccountSettings default values and copyWith', () {
      const settings = BankAccountSettings.defaultSettings;
      expect(settings.bankName, equals('MBBank'));
      expect(settings.bankBin, equals('970422'));
      expect(settings.isConfigured, isFalse);

      final updated = settings.copyWith(
        accountNumber: '0987654321',
        accountHolder: 'NGUYEN VAN A',
      );

      expect(updated.isConfigured, isTrue);
      expect(updated.accountNumber, equals('0987654321'));
      expect(updated.accountHolder, equals('NGUYEN VAN A'));
    });

    test('VietQrGenerator generates valid EMVCo payload string', () {
      const settings = BankAccountSettings(
        bankName: 'MBBank',
        bankCode: 'MB',
        bankBin: '970422',
        accountNumber: '123456789',
        accountHolder: 'LE TRIEU BA VUONG',
        transferTemplate: 'HP {maHocSinh} {thang}',
      );

      final payload = VietQrGenerator.generateEmvCoPayload(
        settings: settings,
        amount: 500000,
        transferContent: VietQrGenerator.formatTransferContent(
          template: settings.transferTemplate,
          studentCode: 'HS001',
          month: '09/2026',
        ),
      );

      expect(payload, startsWith('000201'));
      expect(payload, contains('970422'));
      expect(payload, contains('123456789'));
      expect(payload, contains('5406500000')); // amount
      expect(payload, contains('6304')); // CRC tag
    });

    testWidgets('BankAccountSettingsPage renders form and saves settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: BankAccountSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tài khoản nhận học phí'), findsOneWidget);
      expect(find.text('THÔNG TIN TÀI KHOẢN NGÂN HÀNG'), findsOneWidget);

      // Enter Account Number & Account Holder
      final accountNoFinder = find.byKey(const Key('account_number_input'));
      final accountHolderFinder = find.byKey(const Key('account_holder_input'));

      await tester.enterText(accountNoFinder, '0123456789');
      await tester.enterText(accountHolderFinder, 'LE TRIEU BA VUONG');
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.byKey(const Key('save_bank_account_btn'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Đã lưu thông tin tài khoản nhận học phí'),
        findsOneWidget,
      );
      expect(find.text('STK: 0123456789'), findsOneWidget);
      expect(find.text('Chủ TK: LE TRIEU BA VUONG'), findsOneWidget);
    });
  });
}
