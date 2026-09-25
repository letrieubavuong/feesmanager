import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
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

    await db.insert('tham_gia_lop', {
      'id': 100,
      'id_hoc_sinh': 1,
      'id_lop': 10,
      'tu_ngay': '2026-01-01',
      'created_at': nowStr,
      'updated_at': nowStr,
    });
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
    int iterations = 15,
  }) async {
    for (int i = 0; i < iterations; i++) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }
  }

  group('DOI_CA Dialog UI Tests', () {
    testWidgets(
      'showDoiCaDialog displays eligible targets and enables submit on no conflict',
      (tester) async {
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

        expect(find.text('Xếp đổi ca học'), findsOneWidget);
        expect(find.text('10:00 - 11:30'), findsOneWidget);

        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Xác nhận đổi ca'),
        );
        expect(confirmBtn.onPressed, isNotNull);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets('showDoiCaDialog disables submit on hard conflict', (
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
          'loai': 'HARD_BLOCK',
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

      expect(find.textContaining('XUNG ĐỘT BẮT BUỘC'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Xác nhận đổi ca'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.runAsync(() async => db.close());
    });
  });

  group('HOC_BU Dialog UI Tests', () {
    testWidgets(
      'showHocBuDialog fetches upcoming HOC_BU with real batch class names and no class 0',
      (tester) async {
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

        expect(find.text('Xếp học bù'), findsOneWidget);
        expect(
          find.text('Class 20B - 2026-10-12 (17:30 - 19:00)'),
          findsOneWidget,
        );

        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Xác nhận học bù'),
        );
        expect(confirmBtn.onPressed, isNotNull);

        await tester.runAsync(() async => db.close());
      },
    );
  });

  group('PHAT_SINH Dialog UI Tests', () {
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
      'showPhatSinhDialog derives candidates from active memberships and respects cross-class',
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

        expect(
          find.text('Thêm học sinh tham gia buổi phát sinh'),
          findsOneWidget,
        );
        expect(find.text('Student 1 (Class 10A)'), findsOneWidget);

        await tester.runAsync(() async => db.close());
      },
    );
  });

  group('Constraint UI Integration Tests', () {
    testWidgets(
      'StudentDetailPage displays constraints and allows adding & canceling constraints',
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWith((ref) async => db)],
            child: const MaterialApp(home: StudentDetailPage(studentId: 1)),
          ),
        );

        await waitForAsyncProviders(tester);

        expect(find.text('Ràng buộc lịch'), findsOneWidget);
        expect(find.text('Không thể học'), findsOneWidget);
        expect(find.textContaining('Thứ 1 (17:30 - 19:00)'), findsOneWidget);

        // Open Add Constraint dialog
        final addConstraintBtn = find.text('Thêm ràng buộc');
        await tester.ensureVisible(addConstraintBtn);
        await tester.tap(addConstraintBtn);
        await waitForAsyncProviders(tester);

        expect(find.text('Thêm ràng buộc lịch học sinh'), findsOneWidget);

        // Cancel dialog
        final dialogCancelBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hủy'),
        );
        await tester.tap(dialogCancelBtn);
        await waitForAsyncProviders(tester);

        // Cancel constraint 1 on tile
        final tileCancelBtn = find.widgetWithText(TextButton, 'Hủy');
        await tester.tap(tileCancelBtn);
        await waitForAsyncProviders(tester);

        expect(find.text('Xác nhận hủy ràng buộc'), findsOneWidget);

        await tester.tap(find.text('Hủy ràng buộc'));
        await waitForAsyncProviders(tester);

        expect(find.text('Đã hủy'), findsOneWidget);

        await tester.runAsync(() async => db.close());
      },
    );

    testWidgets('showAddConstraintDialog rejects invalid inputs', (
      tester,
    ) async {
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
                      onPressed: () => showAddConstraintDialog(context, ref, 1),
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

      // Enter start time 19:00, end time 17:00 (end < start)
      final startField = find.widgetWithText(TextField, 'Giờ bắt đầu (HH:mm)');
      final endField = find.widgetWithText(TextField, 'Giờ kết thúc (HH:mm)');

      await tester.enterText(startField, '19:00');
      await tester.enterText(endField, '17:00');

      await tester.tap(find.text('Lưu ràng buộc'));
      await waitForAsyncProviders(tester);

      expect(
        find.textContaining(
          'Thời gian kết thúc (17:00) phải lớn hơn thời gian bắt đầu (19:00)',
        ),
        findsOneWidget,
      );

      await tester.runAsync(() async => db.close());
    });
  });
}
