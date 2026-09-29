import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition2027/app/navigation/ui_keys.dart';
import 'package:tuition2027/features/tuition/domain/tuition_policy.dart';
import 'package:tuition2027/features/tuition/presentation/create_tuition_policy_bottom_sheet.dart';
import 'package:tuition2027/features/tuition/presentation/tuition_controller.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

class _MockTuitionPolicyController extends TuitionPolicyController {
  final Future<TuitionPolicy> Function({
    required int classId,
    required String effectiveFrom,
    String? effectiveTo,
    int standardSessionsPerMonth,
    required int feePerSession,
    int? monthlyMaxFee,
    String? note,
  })
  onCreate;

  _MockTuitionPolicyController({required this.onCreate});

  @override
  Future<TuitionPolicy> createPolicy({
    required int classId,
    required String effectiveFrom,
    String? effectiveTo,
    int standardSessionsPerMonth = 12,
    required int feePerSession,
    int? monthlyMaxFee,
    String? note,
    ExcusedAbsenceFeeRule excusedAbsenceFeeRule =
        ExcusedAbsenceFeeRule.buTruBuoiDu,
  }) async {
    return await onCreate(
      classId: classId,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      feePerSession: feePerSession,
      standardSessionsPerMonth: standardSessionsPerMonth,
      monthlyMaxFee: monthlyMaxFee,
      note: note,
    );
  }
}

Widget buildTestApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Tuition Policy Bottom Sheet Contract Tests', () {
    testWidgets('Contract A: clean sheet + X closes immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCreateTuitionPolicyBottomSheet(context, classId: 1),
              child: const Text('Open Policy Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Policy Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTuitionPolicyBottomSheet), findsOneWidget);

      // Tap X on clean sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Must close immediately without confirmation dialog
      expect(find.text('Tiếp tục chỉnh sửa'), findsNothing);
      expect(find.byType(CreateTuitionPolicyBottomSheet), findsNothing);
    });

    testWidgets(
      'Contract B: dirty sheet + X prompts Keep Editing / Discard, Discard MUST close',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showCreateTuitionPolicyBottomSheet(context, classId: 1),
                child: const Text('Open Policy Sheet'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Policy Sheet'));
        await tester.pumpAndSettle();

        // Change fee input to make dirty
        final feeField = find.byType(TextFormField).at(1);
        await tester.enterText(feeField, '75000');
        await tester.pumpAndSettle();

        // Tap X
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Prompt appears
        expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);
        expect(find.text('Bỏ thay đổi'), findsOneWidget);

        // Tap Discard
        await tester.tap(find.text('Bỏ thay đổi'));
        await tester.pumpAndSettle();

        // Sheet MUST close
        expect(find.byType(CreateTuitionPolicyBottomSheet), findsNothing);
      },
    );

    testWidgets('Contract C: successful save closes sheet exactly once', (
      tester,
    ) async {
      int createCount = 0;
      final dummyPolicy = TuitionPolicy(
        id: 1,
        idLop: 1,
        hocPhiMoiBuoi: 50000,
        soBuoiChuanThang: 12,
        hieuLucTu: '2026-01-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockController = _MockTuitionPolicyController(
        onCreate:
            ({
              required classId,
              required effectiveFrom,
              effectiveTo,
              required feePerSession,
              int standardSessionsPerMonth = 12,
              monthlyMaxFee,
              note,
            }) async {
              createCount++;
              return dummyPolicy;
            },
      );

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCreateTuitionPolicyBottomSheet(context, classId: 1),
              child: const Text('Open Policy Sheet'),
            ),
          ),
          overrides: [
            tuitionPolicyControllerProvider.overrideWith(() => mockController),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Policy Sheet'));
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.byKey(UiKeys.tuitionPolicySave));
      await tester.pumpAndSettle();

      expect(createCount, equals(1));
      expect(find.byType(CreateTuitionPolicyBottomSheet), findsNothing);
    });

    testWidgets(
      'Contract D: failed save keeps sheet open, preserves input, displays inline error',
      (tester) async {
        final mockController = _MockTuitionPolicyController(
          onCreate:
              ({
                required classId,
                required effectiveFrom,
                effectiveTo,
                required feePerSession,
                int standardSessionsPerMonth = 12,
                monthlyMaxFee,
                note,
              }) async {
                throw Exception('Trùng lặp khoảng thời gian hiệu lực');
              },
        );

        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showCreateTuitionPolicyBottomSheet(context, classId: 1),
                child: const Text('Open Policy Sheet'),
              ),
            ),
            overrides: [
              tuitionPolicyControllerProvider.overrideWith(
                () => mockController,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Policy Sheet'));
        await tester.pumpAndSettle();

        final feeField = find.byType(TextFormField).at(1);
        await tester.enterText(feeField, '99000');
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.byKey(UiKeys.tuitionPolicySave));
        await tester.pumpAndSettle();

        // Sheet stays open, inputs preserved, inline error displayed
        expect(find.byType(CreateTuitionPolicyBottomSheet), findsOneWidget);
        expect(find.text('99000'), findsOneWidget);
        expect(
          find.text('Trùng lặp khoảng thời gian hiệu lực'),
          findsOneWidget,
        );
      },
    );
  });
}
