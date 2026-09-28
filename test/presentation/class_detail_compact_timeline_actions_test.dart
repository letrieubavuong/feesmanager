import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuition2027/features/classes/domain/class.dart';
import 'package:tuition2027/features/classes/presentation/class_controller.dart';
import 'package:tuition2027/features/classes/presentation/class_detail_page.dart';
import 'package:tuition2027/features/sessions/domain/class_session.dart';
import 'package:tuition2027/features/attendance/domain/class_attendance_timeline_item.dart';
import 'package:tuition2027/features/attendance/presentation/class_attendance_timeline_controller.dart';
import 'package:tuition2027/l10n/app_localizations.dart';

void main() {
  group('Class Attendance Timeline Compact Action Buttons Tests', () {
    testWidgets('DA_HOC timeline row renders compact Xem and Sửa điểm danh buttons without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dahocItem = ClassAttendanceTimelineItem(
        session: ClassSession(
          id: 101,
          idLop: 1,
          ngay: '2026-09-28',
          gioBatDau: '19:15',
          gioKetThuc: '20:45',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DA_HOC,
          createdAt: DateTime.parse('2026-09-01'),
          updatedAt: DateTime.parse('2026-09-01'),
        ),
        presentCount: 19,
        lateCount: 1,
        excusedCount: 1,
        unexcusedCount: 1,
        recordedCount: 22,
        hasCorrectionHistory: false,
      );

      final testClass = ClassEntity(
        id: 1,
        tenLop: 'Toán 10',
        daLuuTru: false,
        createdAt: DateTime.parse('2026-09-01'),
        updatedAt: DateTime.parse('2026-09-01'),
      );

      final container = ProviderContainer(
        overrides: [
          classDetailProvider(1).overrideWith((ref) async => testClass),
          classAttendanceTimelineProvider(classId: 1, yearMonth: '2026-09')
              .overrideWith((ref) async => [dahocItem]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ClassDetailPage(classId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on TabBar "Điểm danh" tab
      final tabFinder = find.byWidgetPredicate(
        (widget) => widget is Tab && widget.text == 'Điểm danh',
      );
      expect(tabFinder, findsOneWidget);
      await tester.ensureVisible(tabFinder);
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();

      final xemFinder = find.widgetWithText(OutlinedButton, 'Xem');
      final suaFinder = find.widgetWithText(ElevatedButton, 'Sửa điểm danh');

      expect(xemFinder, findsOneWidget);
      expect(suaFinder, findsOneWidget);

      final OutlinedButton xemBtn = tester.widget(xemFinder);
      final ElevatedButton suaBtn = tester.widget(suaFinder);

      expect(xemBtn.style?.minimumSize?.resolve({}), const Size(0, 32));
      expect(suaBtn.style?.minimumSize?.resolve({}), const Size(0, 32));

      expect(tester.takeException(), isNull);
    });

    testWidgets('DU_KIEN timeline row renders compact Điểm danh button with 32px height constraint', (tester) async {
      final dukienItem = ClassAttendanceTimelineItem(
        session: ClassSession(
          id: 102,
          idLop: 1,
          ngay: '2026-09-29',
          gioBatDau: '19:15',
          gioKetThuc: '20:45',
          loai: SessionType.CHINH,
          trangThai: SessionStatus.DU_KIEN,
          createdAt: DateTime.parse('2026-09-01'),
          updatedAt: DateTime.parse('2026-09-01'),
        ),
        presentCount: 0,
        lateCount: 0,
        excusedCount: 0,
        unexcusedCount: 0,
        recordedCount: 0,
        hasCorrectionHistory: false,
      );

      final testClass = ClassEntity(
        id: 1,
        tenLop: 'Toán 10',
        daLuuTru: false,
        createdAt: DateTime.parse('2026-09-01'),
        updatedAt: DateTime.parse('2026-09-01'),
      );

      final container = ProviderContainer(
        overrides: [
          classDetailProvider(1).overrideWith((ref) async => testClass),
          classAttendanceTimelineProvider(classId: 1, yearMonth: '2026-09')
              .overrideWith((ref) async => [dukienItem]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ClassDetailPage(classId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final tabFinder = find.byWidgetPredicate(
        (widget) => widget is Tab && widget.text == 'Điểm danh',
      );
      expect(tabFinder, findsOneWidget);
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();

      final diemDanhBtnFinder = find.widgetWithText(ElevatedButton, 'Điểm danh');
      expect(diemDanhBtnFinder, findsOneWidget);

      final ElevatedButton diemDanhBtn = tester.widget(diemDanhBtnFinder);
      expect(diemDanhBtn.style?.minimumSize?.resolve({}), const Size(0, 32));

      expect(tester.takeException(), isNull);
    });
  });
}
