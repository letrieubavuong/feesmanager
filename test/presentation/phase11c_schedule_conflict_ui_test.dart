import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/schedule/presentation/assignment_tab.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_reason_code.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_result.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_constraint.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_conflict_banner.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_conflict_providers.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_constraint_dialogs.dart';
import 'package:tuition2027/features/session_adjustments/presentation/session_adjustment_dialogs.dart';
import 'package:tuition2027/features/students/presentation/student_detail_page.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String nowStr;

  setUp(() {
    nowStr = DateTime.now().toIso8601String();
  });

  Future<Database> createTestDb() async {
    final tempDir = await Directory.systemTemp.createTemp('p11c_ui_test');
    final dbPath = join(
      tempDir.path,
      'test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final appDb = AppDatabase(dbName: dbPath);
    return await appDb.database;
  }

  Future<void> setupBaseData(Database db) async {
    await db.insert('hoc_sinh', {
      'id': 1,
      'ho_ten': 'Student 1',
      'da_luu_tru': 0,
      'created_at': nowStr,
      'updated_at': nowStr,
    });
    await db.insert('hoc_sinh', {
      'id': 2,
      'ho_ten': 'Student 2',
      'da_luu_tru': 0,
      'created_at': nowStr,
      'updated_at': nowStr,
    });
    await db.insert('hoc_sinh', {
      'id': 3,
      'ho_ten': 'Archived Student',
      'da_luu_tru': 1,
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    await db.insert('lop', {
      'id': 10,
      'ten_lop': 'Class 10A',
      'da_luu_tru': 0,
      'created_at': nowStr,
      'updated_at': nowStr,
    });
    await db.insert('lop', {
      'id': 20,
      'ten_lop': 'Class 20B',
      'da_luu_tru': 0,
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    // Student 1 has active membership in Class 20B (eligible for PHAT_SINH in Class 10A)
    await db.insert('tham_gia_lop', {
      'id': 100,
      'id_hoc_sinh': 1,
      'id_lop': 20,
      'tu_ngay': '2026-01-01',
      'created_at': nowStr,
      'updated_at': nowStr,
    });
    // Student 2 has active membership in Class 20B
    await db.insert('tham_gia_lop', {
      'id': 200,
      'id_hoc_sinh': 2,
      'id_lop': 20,
      'tu_ngay': '2026-01-01',
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    await db.insert('lich_hoc', {
      'id': 1,
      'id_lop': 10,
      'thu_trong_tuan': 6,
      'gio_bat_dau': '08:00',
      'gio_ket_thuc': '09:30',
      'hieu_luc_tu': '2026-01-01',
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    await db.insert('lich_hoc', {
      'id': 2,
      'id_lop': 10,
      'thu_trong_tuan': 6,
      'gio_bat_dau': '10:00',
      'gio_ket_thuc': '11:30',
      'hieu_luc_tu': '2026-01-01',
      'created_at': nowStr,
      'updated_at': nowStr,
    });
  }

  Future<void> waitForAsyncProviders(
    WidgetTester tester, {
    int iterations = 20,
  }) async {
    for (int i = 0; i < iterations; i++) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }
  }

  // --- 1. DOI_CA UI TEST MATRIX ---
  group('DOI_CA Dialog UI Matrix Tests', () {
    testWidgets('showDoiCaDialog preview loading disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-10-10',
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final pendingCompleter = Completer<ScheduleConflictResult>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((
              1,
              102,
              101,
            )).overrideWith((ref) => pendingCompleter.future),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => SessionAdjustmentDialogs.showDoiCaDialog(
                      context: context,
                      ref: ref,
                      studentId: 1,
                      originalSessionId: 101,
                    ),
                    child: const Text('Open DoiCa'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open DoiCa'));
      await waitForAsyncProviders(tester, iterations: 5);

      expect(find.text('Xếp đổi ca học'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận đổi ca'),
      );
      expect(confirmBtn.onPressed, isNull);

      pendingCompleter.complete(ScheduleConflictResult.clear());
      await tester.runAsync(() async => db.close());
    });

    testWidgets('showDoiCaDialog preview error disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-10-10',
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((1, 102, 101)).overrideWith(
              (ref) => Future.error(Exception('Simulated DB Error')),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => SessionAdjustmentDialogs.showDoiCaDialog(
                      context: context,
                      ref: ref,
                      studentId: 1,
                      originalSessionId: 101,
                    ),
                    child: const Text('Open DoiCa'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open DoiCa'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('Lỗi kiểm tra trùng lịch'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận đổi ca'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('showDoiCaDialog soft warning enables submit', (tester) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 102,
          'id_lop': 10,
          'id_lich_hoc': 2,
          'ngay': '2026-10-10',
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('rang_buoc_lich_hoc_sinh', {
          'id': 1,
          'id_hoc_sinh': 1,
          'loai': 'SOFT_PREFERENCE',
          'kieu': 'MOT_LAN',
          'ngay_cu_the': '2026-10-10',
          'gio_bat_dau': '10:00',
          'gio_ket_thuc': '11:00',
          'travel_buffer_phut': 0,
          'trang_thai': 'HOAT_DONG',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWith((ref) async => db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => SessionAdjustmentDialogs.showDoiCaDialog(
                      context: context,
                      ref: ref,
                      studentId: 1,
                      originalSessionId: 101,
                    ),
                    child: const Text('Open DoiCa'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open DoiCa'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('CẢNH BÁO KHÔNG ƯU TIÊN'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận đổi ca'),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets(
      'showDoiCaDialog target selection change invokes preview with new targetSessionId',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);

          await db.insert('tham_gia_lop', {
            'id': 101,
            'id_hoc_sinh': 1,
            'id_lop': 10,
            'tu_ngay': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          await db.insert('buoi_hoc', {
            'id': 101,
            'id_lop': 10,
            'id_lich_hoc': 1,
            'ngay': '2026-10-10',
            'gio_bat_dau': '08:00',
            'gio_ket_thuc': '09:30',
            'loai': 'CHINH',
            'trang_thai': 'DU_KIEN',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          // Target 1: 102 (10:00-11:30)
          await db.insert('buoi_hoc', {
            'id': 102,
            'id_lop': 10,
            'id_lich_hoc': 2,
            'ngay': '2026-10-10',
            'gio_bat_dau': '10:00',
            'gio_ket_thuc': '11:30',
            'loai': 'CHINH',
            'trang_thai': 'DU_KIEN',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          // Target 2: 103 (14:00-15:30) with HARD_BLOCK conflict
          await db.insert('buoi_hoc', {
            'id': 103,
            'id_lop': 10,
            'id_lich_hoc': 2,
            'ngay': '2026-10-10',
            'gio_bat_dau': '14:00',
            'gio_ket_thuc': '15:30',
            'loai': 'CHINH',
            'trang_thai': 'DU_KIEN',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          await db.insert('rang_buoc_lich_hoc_sinh', {
            'id': 1,
            'id_hoc_sinh': 1,
            'loai': 'HARD_BLOCK',
            'kieu': 'MOT_LAN',
            'ngay_cu_the': '2026-10-10',
            'gio_bat_dau': '14:00',
            'gio_ket_thuc': '15:00',
            'travel_buffer_phut': 0,
            'trang_thai': 'HOAT_DONG',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () => SessionAdjustmentDialogs.showDoiCaDialog(
                        context: context,
                        ref: ref,
                        studentId: 1,
                        originalSessionId: 101,
                      ),
                      child: const Text('Open DoiCa'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open DoiCa'));
        await waitForAsyncProviders(tester);

        // Target 102 has no conflict -> submit enabled
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Xác nhận đổi ca'),
              )
              .onPressed,
          isNotNull,
        );

        // Change target dropdown to 103
        final dropdownFinder = find.byWidgetPredicate(
          (w) => w is DropdownButtonFormField,
        );
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('14:00 - 15:30').last);
        await waitForAsyncProviders(tester);

        // Target 103 has HARD_BLOCK -> submit disabled and conflict banner shown
        expect(find.textContaining('XUNG ĐỘT BẮT BUỘC'), findsOneWidget);
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Xác nhận đổi ca'),
              )
              .onPressed,
          isNull,
        );

        await tester.runAsync(() async => db.close());
      },
    );
  });

  // --- 2. HOC_BU UI TEST MATRIX ---
  group('HOC_BU Dialog UI Matrix Tests', () {
    testWidgets('showHocBuDialog preview loading disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 301,
          'id_lop': 20,
          'ngay': '2026-10-12',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final pendingCompleter = Completer<ScheduleConflictResult>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((
              1,
              301,
              null,
            )).overrideWith((ref) => pendingCompleter.future),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => SessionAdjustmentDialogs.showHocBuDialog(
                      context: context,
                      ref: ref,
                      studentId: 1,
                      originalSessionId: 101,
                    ),
                    child: const Text('Open HocBu'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open HocBu'));
      await waitForAsyncProviders(tester, iterations: 5);

      expect(find.text('Xếp học bù'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận học bù'),
      );
      expect(confirmBtn.onPressed, isNull);

      pendingCompleter.complete(ScheduleConflictResult.clear());
      await tester.runAsync(() async => db.close());
    });

    testWidgets('showHocBuDialog preview error disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 301,
          'id_lop': 20,
          'ngay': '2026-10-12',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider(
              (1, 301, null),
            ).overrideWith((ref) => Future.error(Exception('Simulated Error'))),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => SessionAdjustmentDialogs.showHocBuDialog(
                      context: context,
                      ref: ref,
                      studentId: 1,
                      originalSessionId: 101,
                    ),
                    child: const Text('Open HocBu'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open HocBu'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('Lỗi kiểm tra trùng lịch'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận học bù'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('showHocBuDialog hard conflict disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 301,
          'id_lop': 20,
          'ngay': '2026-10-12',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final hardConflictResult = ScheduleConflictResult(
        hardConflicts: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.EXACT_OVERLAP,
            isHard: true,
            message: 'Trùng lịch',
          ),
        ],
        softWarnings: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((
              1,
              301,
              null,
            )).overrideWith((ref) async => hardConflictResult),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => SessionAdjustmentDialogs.showHocBuDialog(
                      context: context,
                      ref: ref,
                      studentId: 1,
                      originalSessionId: 101,
                    ),
                    child: const Text('Open HocBu'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open HocBu'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('XUNG ĐỘT BẮT BUỘC'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận học bù'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('showHocBuDialog soft warning enables submit', (tester) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DA_HOC',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('buoi_hoc', {
          'id': 301,
          'id_lop': 20,
          'ngay': '2026-10-12',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'HOC_BU',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final softWarningResult = ScheduleConflictResult(
        hardConflicts: [],
        softWarnings: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.TRAVEL_BUFFER,
            isHard: false,
            message: 'Thiếu đệm di chuyển',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((
              1,
              301,
              null,
            )).overrideWith((ref) async => softWarningResult),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => SessionAdjustmentDialogs.showHocBuDialog(
                      context: context,
                      ref: ref,
                      studentId: 1,
                      originalSessionId: 101,
                    ),
                    child: const Text('Open HocBu'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open HocBu'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('CẢNH BÁO KHÔNG ƯU TIÊN'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận học bù'),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets(
      'showHocBuDialog creates HOC_BU adjustment record in DB with correct studentId, originalSessionId, targetSessionId, loai',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);

          await db.insert('tham_gia_lop', {
            'id': 101,
            'id_hoc_sinh': 1,
            'id_lop': 10,
            'tu_ngay': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          // Original session 101 must be DA_HOC for HOC_BU creation
          await db.insert('buoi_hoc', {
            'id': 101,
            'id_lop': 10,
            'id_lich_hoc': 1,
            'ngay': '2026-10-10',
            'gio_bat_dau': '08:00',
            'gio_ket_thuc': '09:30',
            'loai': 'CHINH',
            'trang_thai': 'DA_HOC',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          // Insert NGHI_CO_PHEP attendance in original session
          await db.insert('diem_danh', {
            'id_buoi_hoc': 101,
            'id_hoc_sinh': 1,
            'id_lop_goc': 10,
            'trang_thai': 'NGHI_CO_PHEP',
            'loai_tham_gia': 'CHINH',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          await db.insert('buoi_hoc', {
            'id': 301,
            'id_lop': 20,
            'ngay': '2026-10-12',
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'HOC_BU',
            'trang_thai': 'DU_KIEN',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () => SessionAdjustmentDialogs.showHocBuDialog(
                        context: context,
                        ref: ref,
                        studentId: 1,
                        originalSessionId: 101,
                      ),
                      child: const Text('Open HocBu'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open HocBu'));
        await waitForAsyncProviders(tester);

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Xác nhận học bù'),
        );
        await waitForAsyncProviders(tester);

        // Assert DB record created correctly
        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('dieu_chinh_buoi_hoc');
        });
        expect(records.length, equals(1));
        expect(records.first['id_hoc_sinh'], equals(1));
        expect(records.first['id_buoi_hoc_goc'], equals(101));
        expect(records.first['id_buoi_hoc_tham_gia'], equals(301));
        expect(records.first['loai'], equals('HOC_BU'));

        await tester.runAsync(() async => db.close());
      },
    );
  });

  // --- 3. PHAT_SINH UI TEST MATRIX ---
  group('PHAT_SINH Dialog UI Matrix Tests', () {
    testWidgets('showPhatSinhDialog rejects invalid target session', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('buoi_hoc', {
          'id': 101,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'ngay': '2026-10-10',
          'gio_bat_dau': '08:00',
          'gio_ket_thuc': '09:30',
          'loai': 'CHINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWith((ref) async => db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () =>
                        SessionAdjustmentDialogs.showPhatSinhDialog(
                          context: context,
                          ref: ref,
                          targetSessionId: 101,
                        ),
                    child: const Text('Open PhatSinh'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open PhatSinh'));
      await waitForAsyncProviders(tester);

      expect(find.text('Buổi học không hợp lệ'), findsOneWidget);

      await tester.runAsync(() async => db.close());
    });

    testWidgets(
      'showPhatSinhDialog excludes inactive/archived students and renders multi-membership options',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);

          // Student 1 has active memberships in Class 20B AND Class 10A
          await db.insert('tham_gia_lop', {
            'id': 101,
            'id_hoc_sinh': 1,
            'id_lop': 10,
            'tu_ngay': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          // Student 4 has NO active membership on 2026-10-10 -> EXCLUDED
          await db.insert('hoc_sinh', {
            'id': 4,
            'ho_ten': 'Student No Membership',
            'da_luu_tru': 0,
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          await db.insert('buoi_hoc', {
            'id': 401,
            'id_lop': 10,
            'ngay': '2026-10-10',
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'PHAT_SINH',
            'trang_thai': 'DU_KIEN',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () =>
                          SessionAdjustmentDialogs.showPhatSinhDialog(
                            context: context,
                            ref: ref,
                            targetSessionId: 401,
                          ),
                      child: const Text('Open PhatSinh'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open PhatSinh'));
        await waitForAsyncProviders(tester);

        expect(find.text('Student 1 (Class 20B)'), findsOneWidget);
        expect(find.text('Student No Membership'), findsNothing);
        expect(find.text('Archived Student'), findsNothing);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets('showPhatSinhDialog preview loading disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('buoi_hoc', {
          'id': 401,
          'id_lop': 10,
          'ngay': '2026-10-10',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final pendingCompleter = Completer<ScheduleConflictResult>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((
              1,
              401,
              null,
            )).overrideWith((ref) => pendingCompleter.future),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () =>
                        SessionAdjustmentDialogs.showPhatSinhDialog(
                          context: context,
                          ref: ref,
                          targetSessionId: 401,
                        ),
                    child: const Text('Open PhatSinh'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open PhatSinh'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('Thêm học sinh'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận thêm'),
      );
      expect(confirmBtn.onPressed, isNull);

      pendingCompleter.complete(ScheduleConflictResult.clear());
      await tester.runAsync(() async => db.close());
    });

    testWidgets('showPhatSinhDialog preview error disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('buoi_hoc', {
          'id': 401,
          'id_lop': 10,
          'ngay': '2026-10-10',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider(
              (1, 401, null),
            ).overrideWith((ref) => Future.error(Exception('Simulated Error'))),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () =>
                        SessionAdjustmentDialogs.showPhatSinhDialog(
                          context: context,
                          ref: ref,
                          targetSessionId: 401,
                        ),
                    child: const Text('Open PhatSinh'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open PhatSinh'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('Lỗi kiểm tra trùng lịch'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận thêm'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('showPhatSinhDialog hard conflict disables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('buoi_hoc', {
          'id': 401,
          'id_lop': 10,
          'ngay': '2026-10-10',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final hardConflictResult = ScheduleConflictResult(
        hardConflicts: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.EXACT_OVERLAP,
            isHard: true,
            message: 'Trùng lịch phát sinh',
          ),
        ],
        softWarnings: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((
              1,
              401,
              null,
            )).overrideWith((ref) async => hardConflictResult),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () =>
                        SessionAdjustmentDialogs.showPhatSinhDialog(
                          context: context,
                          ref: ref,
                          targetSessionId: 401,
                        ),
                    child: const Text('Open PhatSinh'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open PhatSinh'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('XUNG ĐỘT BẮT BUỘC'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận thêm'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('showPhatSinhDialog soft warning enables submit', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('buoi_hoc', {
          'id': 401,
          'id_lop': 10,
          'ngay': '2026-10-10',
          'gio_bat_dau': '17:30',
          'gio_ket_thuc': '19:00',
          'loai': 'PHAT_SINH',
          'trang_thai': 'DU_KIEN',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final softWarningResult = ScheduleConflictResult(
        hardConflicts: [],
        softWarnings: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.TRAVEL_BUFFER,
            isHard: false,
            message: 'Cần đệm di chuyển',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            oneOffSessionConflictPreviewProvider((
              1,
              401,
              null,
            )).overrideWith((ref) async => softWarningResult),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () =>
                        SessionAdjustmentDialogs.showPhatSinhDialog(
                          context: context,
                          ref: ref,
                          targetSessionId: 401,
                        ),
                    child: const Text('Open PhatSinh'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open PhatSinh'));
      await waitForAsyncProviders(tester);

      expect(find.textContaining('CẢNH BÁO KHÔNG ƯU TIÊN'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận thêm'),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets(
      'showPhatSinhDialog creates adjustment preserving actual originalClassId from selected option',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);

          await db.insert('buoi_hoc', {
            'id': 401,
            'id_lop': 10,
            'ngay': '2026-10-10',
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'loai': 'PHAT_SINH',
            'trang_thai': 'DU_KIEN',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () =>
                          SessionAdjustmentDialogs.showPhatSinhDialog(
                            context: context,
                            ref: ref,
                            targetSessionId: 401,
                          ),
                      child: const Text('Open PhatSinh'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open PhatSinh'));
        await waitForAsyncProviders(tester);

        // Submit (Student 1 Class 20B is candidate index 0)
        await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận thêm'));
        await waitForAsyncProviders(tester);

        // Assert DB record uses actual originalClassId = 20 (Class 20B), NOT target session's class 10
        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('dieu_chinh_buoi_hoc');
        });
        expect(records.length, equals(1));
        expect(records.first['id_hoc_sinh'], equals(1));
        expect(
          records.first['id_lop_goc'],
          equals(20),
        ); // Actual membership class preserved!
        expect(records.first['id_buoi_hoc_tham_gia'], equals(401));
        expect(records.first['loai'], equals('PHAT_SINH'));

        await tester.runAsync(() async => db.close());
      },
    );
  });

  // --- 4. CONSTRAINT UI MATRIX TESTS ---
  group('Constraint UI Creation & Validation Matrix Tests', () {
    testWidgets(
      'showAddConstraintDialog HARD_BLOCK DINH_KY creation succeeds and asserts persisted fields',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records.length, equals(1));
        expect(records.first['id_hoc_sinh'], equals(1));
        expect(records.first['loai'], equals('HARD_BLOCK'));
        expect(records.first['kieu'], equals('DINH_KY'));
        expect(records.first['thu_trong_tuan'], equals(1));
        expect(records.first['gio_bat_dau'], equals('17:30'));
        expect(records.first['gio_ket_thuc'], equals('19:00'));
        expect(records.first['trang_thai'], equals('HOAT_DONG'));

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'showAddConstraintDialog SOFT_PREFERENCE DINH_KY creation succeeds and asserts persisted fields',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        // Select SOFT_PREFERENCE
        final typeDropdown = find.widgetWithText(
          DropdownButtonFormField<ConstraintType>,
          'Loại ràng buộc',
        );
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Không ưu tiên').last);
        await waitForAsyncProviders(tester);

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records.length, equals(1));
        expect(records.first['id_hoc_sinh'], equals(1));
        expect(records.first['loai'], equals('SOFT_PREFERENCE'));
        expect(records.first['kieu'], equals('DINH_KY'));
        expect(records.first['trang_thai'], equals('HOAT_DONG'));

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'showAddConstraintDialog OTHER_CENTER creation with sourceName and travelBuffer succeeds',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        // Select OTHER_CENTER
        final typeDropdown = find.widgetWithText(
          DropdownButtonFormField<ConstraintType>,
          'Loại ràng buộc',
        );
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Học ở trung tâm khác').last);
        await waitForAsyncProviders(tester);

        final sourceField = find.widgetWithText(
          TextField,
          'Tên trường / trung tâm khác',
        );
        final bufferField = find.widgetWithText(
          TextField,
          'Thời gian di chuyển cần thiết (phút)',
        );

        await tester.enterText(sourceField, 'Center Alpha');
        await tester.enterText(bufferField, '25');

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records.length, equals(1));
        expect(records.first['loai'], equals('OTHER_CENTER'));
        expect(records.first['ten_nguon'], equals('Center Alpha'));
        expect(records.first['travel_buffer_phut'], equals(25));

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'showAddConstraintDialog MOT_LAN specific date constraint creation succeeds and asserts persisted fields',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        // Select MOT_LAN
        final occurrenceDropdown = find.widgetWithText(
          DropdownButtonFormField<OccurrenceType>,
          'Tần suất',
        );
        await tester.tap(occurrenceDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Một lần').last);
        await waitForAsyncProviders(tester);

        final dateField = find.widgetWithText(
          TextField,
          'Ngày cụ thể (YYYY-MM-DD)',
        );
        await tester.enterText(dateField, '2026-11-20');

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records.length, equals(1));
        expect(records.first['kieu'], equals('MOT_LAN'));
        expect(records.first['ngay_cu_the'], equals('2026-11-20'));
        expect(records.first['thu_trong_tuan'], isNull);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'showAddConstraintDialog rejects end <= start without inserting DB row',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        final startField = find.widgetWithText(
          TextField,
          'Giờ bắt đầu (HH:mm)',
        );
        final endField = find.widgetWithText(TextField, 'Giờ kết thúc (HH:mm)');

        await tester.enterText(startField, '19:00');
        await tester.enterText(endField, '17:00');

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Lỗi:'), findsOneWidget);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records, isEmpty);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'showAddConstraintDialog rejects invalid time format without inserting DB row',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        final startField = find.widgetWithText(
          TextField,
          'Giờ bắt đầu (HH:mm)',
        );
        await tester.enterText(startField, '25:70');

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Lỗi:'), findsOneWidget);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records, isEmpty);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'showAddConstraintDialog rejects negative travel buffer without inserting DB row',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        // Select OTHER_CENTER
        final typeDropdown = find.widgetWithText(
          DropdownButtonFormField<ConstraintType>,
          'Loại ràng buộc',
        );
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Học ở trung tâm khác').last);
        await waitForAsyncProviders(tester);

        final sourceField = find.widgetWithText(
          TextField,
          'Tên trường / trung tâm khác',
        );
        final bufferField = find.widgetWithText(
          TextField,
          'Thời gian di chuyển cần thiết (phút)',
        );

        await tester.enterText(sourceField, 'Center Alpha');
        await tester.enterText(bufferField, '-15');

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Lỗi:'), findsOneWidget);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records, isEmpty);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'showAddConstraintDialog rejects OTHER_CENTER with empty sourceName without inserting DB row',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () =>
                            showAddConstraintDialog(context, ref, 1),
                        child: const Text('Open Constraint Dialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Constraint Dialog'));
        await waitForAsyncProviders(tester);

        // Select OTHER_CENTER
        final typeDropdown = find.widgetWithText(
          DropdownButtonFormField<ConstraintType>,
          'Loại ràng buộc',
        );
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Học ở trung tâm khác').last);
        await waitForAsyncProviders(tester);

        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Lỗi:'), findsOneWidget);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records, isEmpty);

        await tester.runAsync(() async => db.close());
      },
    );
  });

  // --- 5. CONSTRAINT LIVE REFRESH TESTS ---
  group('Constraint Live Refresh Tests', () {
    testWidgets(
      'StudentDetailPage creates new constraint and live refreshes UI',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: const MaterialApp(home: StudentDetailPage(studentId: 1)),
          ),
        );

        await waitForAsyncProviders(tester);

        expect(find.text('Ràng buộc lịch'), findsOneWidget);

        // Tap Thêm ràng buộc
        final addConstraintBtn = find.text('Thêm ràng buộc');
        await tester.ensureVisible(addConstraintBtn);
        await tester.tap(addConstraintBtn);
        await waitForAsyncProviders(tester);

        expect(find.text('Thêm ràng buộc lịch học sinh'), findsOneWidget);

        // Save constraint
        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);

        // Dialog closed and new constraint tile immediately visible on StudentDetailPage
        expect(find.text('Không thể học'), findsOneWidget);
        expect(find.textContaining('Thứ 1 (17:30 - 19:00)'), findsOneWidget);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets(
      'StudentDetailPage cancels constraint and live updates status to Đã hủy',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);

          await db.insert('rang_buoc_lich_hoc_sinh', {
            'id': 1,
            'id_hoc_sinh': 1,
            'loai': 'HARD_BLOCK',
            'kieu': 'DINH_KY',
            'thu_trong_tuan': 1,
            'gio_bat_dau': '17:30',
            'gio_ket_thuc': '19:00',
            'hieu_luc_tu': '2026-01-01',
            'travel_buffer_phut': 0,
            'trang_thai': 'HOAT_DONG',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        });

        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: const MaterialApp(home: StudentDetailPage(studentId: 1)),
          ),
        );

        await waitForAsyncProviders(tester);

        expect(find.text('Không thể học'), findsOneWidget);

        // Cancel constraint 1 on tile
        final tileCancelBtn = find.widgetWithText(TextButton, 'Hủy');
        await tester.tap(tileCancelBtn);
        await waitForAsyncProviders(tester);

        expect(find.text('Xác nhận hủy ràng buộc'), findsOneWidget);

        await tester.tap(find.text('Hủy ràng buộc'));
        await waitForAsyncProviders(tester);

        // Status immediately updates to Đã hủy
        expect(find.text('Đã hủy'), findsOneWidget);

        await tester.runAsync(() async => db.close());
      },
    );
  });

  // --- 6. SCHEDULE CONFLICT BANNER TESTS ---
  group('ScheduleConflictBanner Widget Tests', () {
    testWidgets('renders hard conflict title and messages', (tester) async {
      final hardConflictResult = ScheduleConflictResult(
        hardConflicts: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.EXACT_OVERLAP,
            isHard: true,
            message: 'Trùng lịch học định kỳ tại Class 10A',
          ),
        ],
        softWarnings: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleConflictBanner(result: hardConflictResult),
          ),
        ),
      );

      expect(find.textContaining('XUNG ĐỘT BẮT BUỘC'), findsOneWidget);
      expect(
        find.textContaining('Trùng lịch học định kỳ tại Class 10A'),
        findsOneWidget,
      );
    });

    testWidgets('renders soft warning title and messages', (tester) async {
      final softWarningResult = ScheduleConflictResult(
        hardConflicts: [],
        softWarnings: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.TRAVEL_BUFFER,
            isHard: false,
            message: 'Cần 30 phút di chuyển từ Trung tâm X',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleConflictBanner(result: softWarningResult),
          ),
        ),
      );

      expect(find.textContaining('CẢNH BÁO KHÔNG ƯU TIÊN'), findsOneWidget);
      expect(
        find.textContaining('Cần 30 phút di chuyển từ Trung tâm X'),
        findsOneWidget,
      );
    });

    testWidgets('renders empty SizedBox when no conflicts or warnings', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleConflictBanner(
              result: ScheduleConflictResult.clear(),
            ),
          ),
        ),
      );

      expect(find.textContaining('XUNG ĐỘT'), findsNothing);
      expect(find.textContaining('CẢNH BÁO'), findsNothing);
    });
  });

  // --- 7. ASSIGNMENT UI FAIL-CLOSED TESTS ---
  group('Assignment UI Fail-Closed Tests', () {
    testWidgets(
      'AssignStudentDialog disables confirm button on preview loading',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);
        });

        final pendingCompleter = Completer<ScheduleConflictResult>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              assignmentConflictPreviewProvider((
                1,
                1,
                '2026-10-10',
                null,
                null,
              )).overrideWith((ref) => pendingCompleter.future),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AssignStudentDialog(scheduleId: 1, classId: 10),
              ),
            ),
          ),
        );

        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump();

        expect(find.text('Phân ca cho học sinh'), findsOneWidget);

        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Xác nhận'),
        );
        expect(confirmBtn.onPressed, isNull);

        pendingCompleter.complete(ScheduleConflictResult.clear());
        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets('AssignStudentDialog preview error disables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider(
              (1, 1, '2026-10-10', null, null),
            ).overrideWith((ref) => Future.error(Exception('Simulated error'))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AssignStudentDialog(scheduleId: 1, classId: 10),
            ),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('AssignStudentDialog hard conflict disables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);
      });

      final hardConflictResult = ScheduleConflictResult(
        hardConflicts: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.EXACT_OVERLAP,
            isHard: true,
            message: 'Trùng lịch',
          ),
        ],
        softWarnings: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider((
              1,
              1,
              '2026-10-10',
              null,
              null,
            )).overrideWith((ref) async => hardConflictResult),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AssignStudentDialog(scheduleId: 1, classId: 10),
            ),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('AssignStudentDialog soft warning enables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final softWarningResult = ScheduleConflictResult(
        hardConflicts: [],
        softWarnings: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.TRAVEL_BUFFER,
            isHard: false,
            message: 'Thiếu đệm di chuyển',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider((
              1,
              1,
              '2026-10-10',
              null,
              null,
            )).overrideWith((ref) async => softWarningResult),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AssignStudentDialog(scheduleId: 1, classId: 10),
            ),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      // Select Student 1
      final dropdownFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField,
      );
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student 1'));
      await waitForAsyncProviders(tester);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('AssignStudentDialog clear preview enables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider((
              1,
              1,
              '2026-10-10',
              null,
              null,
            )).overrideWith((ref) async => ScheduleConflictResult.clear()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AssignStudentDialog(scheduleId: 1, classId: 10),
            ),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      // Select Student 1
      final dropdownFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField,
      );
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student 1'));
      await waitForAsyncProviders(tester);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.runAsync(() async => db.close());
    });
  });

  // --- 8. CHANGE SHIFT DIALOG FAIL-CLOSED TESTS ---
  group('ChangeShiftDialog Fail-Closed Tests', () {
    testWidgets(
      'ChangeShiftDialog disables confirm button on preview loading, error, hard conflict, and enables on clear',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);

          await db.insert('tham_gia_lop', {
            'id': 101,
            'id_hoc_sinh': 1,
            'id_lop': 10,
            'tu_ngay': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });

          await db.insert('phan_ca_hoc_sinh', {
            'id': 500,
            'id_hoc_sinh': 1,
            'id_lop': 10,
            'id_lich_hoc': 1,
            'tu_ngay': '2026-01-01',
            'created_at': nowStr,
            'updated_at': nowStr,
          });
        });

        final pendingCompleter = Completer<ScheduleConflictResult>();
        final effectiveDateStr = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWith((ref) async => db),
              assignmentConflictPreviewProvider((
                1,
                2,
                effectiveDateStr,
                null,
                500,
              )).overrideWith((ref) => pendingCompleter.future),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AssignmentTab(classId: 10)),
            ),
          ),
        );

        await waitForAsyncProviders(tester);

        // Open PopupMenu for Student 1
        final menuBtn = find.byIcon(Icons.more_vert).first;
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chuyển ca'));
        await waitForAsyncProviders(tester);

        expect(find.text('Chuyển ca học định kỳ'), findsOneWidget);

        // Select Schedule 2 (10:00-11:30)
        final dropdownFinder = find.byWidgetPredicate(
          (w) => w is DropdownButtonFormField<int>,
        );
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('Thứ Bảy: 10:00-11:30').last);
        await waitForAsyncProviders(tester, iterations: 5);

        // Confirm button is disabled while preview is loading
        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Xác nhận'),
        );
        expect(confirmBtn.onPressed, isNull);

        pendingCompleter.complete(ScheduleConflictResult.clear());
        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets('ChangeShiftDialog preview error disables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('phan_ca_hoc_sinh', {
          'id': 500,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final effectiveDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider(
              (1, 2, effectiveDateStr, null, 500),
            ).overrideWith((ref) => Future.error(Exception('Simulated Error'))),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AssignmentTab(classId: 10)),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      final menuBtn = find.byIcon(Icons.more_vert).first;
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chuyển ca'));
      await waitForAsyncProviders(tester);

      final dropdownFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<int>,
      );
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thứ Bảy: 10:00-11:30').last);
      await waitForAsyncProviders(tester);

      expect(find.textContaining('Lỗi kiểm tra trùng lịch'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('ChangeShiftDialog hard conflict disables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('phan_ca_hoc_sinh', {
          'id': 500,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final hardConflictResult = ScheduleConflictResult(
        hardConflicts: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.EXACT_OVERLAP,
            isHard: true,
            message: 'Trùng ca',
          ),
        ],
        softWarnings: [],
      );

      final effectiveDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider((
              1,
              2,
              effectiveDateStr,
              null,
              500,
            )).overrideWith((ref) async => hardConflictResult),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AssignmentTab(classId: 10)),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      final menuBtn = find.byIcon(Icons.more_vert).first;
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chuyển ca'));
      await waitForAsyncProviders(tester);

      final dropdownFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<int>,
      );
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thứ Bảy: 10:00-11:30').last);
      await waitForAsyncProviders(tester);

      expect(find.textContaining('XUNG ĐỘT BẮT BUỘC'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('ChangeShiftDialog soft warning enables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('phan_ca_hoc_sinh', {
          'id': 500,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final softWarningResult = ScheduleConflictResult(
        hardConflicts: [],
        softWarnings: [
          const ScheduleConflict(
            reasonCode: ScheduleConflictReasonCode.TRAVEL_BUFFER,
            isHard: false,
            message: 'Thiếu đệm di chuyển',
          ),
        ],
      );

      final effectiveDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider((
              1,
              2,
              effectiveDateStr,
              null,
              500,
            )).overrideWith((ref) async => softWarningResult),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AssignmentTab(classId: 10)),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      final menuBtn = find.byIcon(Icons.more_vert).first;
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chuyển ca'));
      await waitForAsyncProviders(tester);

      final dropdownFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<int>,
      );
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thứ Bảy: 10:00-11:30').last);
      await waitForAsyncProviders(tester);

      expect(find.textContaining('CẢNH BÁO KHÔNG ƯU TIÊN'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.runAsync(() async => db.close());
    });

    testWidgets('ChangeShiftDialog clear preview enables confirm button', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

        await db.insert('tham_gia_lop', {
          'id': 101,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });

        await db.insert('phan_ca_hoc_sinh', {
          'id': 500,
          'id_hoc_sinh': 1,
          'id_lop': 10,
          'id_lich_hoc': 1,
          'tu_ngay': '2026-01-01',
          'created_at': nowStr,
          'updated_at': nowStr,
        });
      });

      final effectiveDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWith((ref) async => db),
            assignmentConflictPreviewProvider((
              1,
              2,
              effectiveDateStr,
              null,
              500,
            )).overrideWith((ref) async => ScheduleConflictResult.clear()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AssignmentTab(classId: 10)),
          ),
        ),
      );

      await waitForAsyncProviders(tester);

      final menuBtn = find.byIcon(Icons.more_vert).first;
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chuyển ca'));
      await waitForAsyncProviders(tester);

      final dropdownFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<int>,
      );
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thứ Bảy: 10:00-11:30').last);
      await waitForAsyncProviders(tester);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận'),
      );
      expect(confirmBtn.onPressed, isNotNull);

      await tester.runAsync(() async => db.close());
    });
  });
}
