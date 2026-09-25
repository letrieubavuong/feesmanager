import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;
import 'package:tuition2027/core/database/app_database.dart';
import 'package:tuition2027/core/database/database_provider.dart';
import 'package:tuition2027/features/schedule/presentation/assignment_tab.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_reason_code.dart';
import 'package:tuition2027/features/schedule_conflicts/domain/schedule_conflict_result.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_conflict_banner.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_conflict_providers.dart';
import 'package:tuition2027/features/schedule_conflicts/presentation/schedule_constraint_dialogs.dart';
import 'package:tuition2027/features/session_adjustments/presentation/session_adjustment_dialogs.dart';

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
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

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
    testWidgets('showHocBuDialog creates HOC_BU adjustment record in DB', (
      tester,
    ) async {
      late Database db;
      await tester.runAsync(() async {
        db = await createTestDb();
        await setupBaseData(db);

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

      await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận học bù'));
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
    });
  });

  // --- 3. PHAT_SINH UI TEST MATRIX ---
  group('PHAT_SINH Dialog UI Matrix Tests', () {
    testWidgets(
      'showPhatSinhDialog excludes inactive students and creates adjustment with actual originalClassId',
      (tester) async {
        late Database db;
        await tester.runAsync(() async {
          db = await createTestDb();
          await setupBaseData(db);

          // Student 1 has active membership in Class 10A
          // Student 2 has active membership in Class 20B
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

        expect(find.text('Student 1 (Class 10A)'), findsOneWidget);
        expect(find.text('Student No Membership'), findsNothing);

        // Select Student 2 (Class 20B)
        final dropdownFinder = find.byWidgetPredicate(
          (w) => w is DropdownButtonFormField,
        );
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Student 2 (Class 20B)').last);
        await waitForAsyncProviders(tester);

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận thêm'));
        await waitForAsyncProviders(tester);

        // Assert DB record uses actual originalClassId = 20 (Class 20B), NOT target session's class 10
        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('dieu_chinh_buoi_hoc');
        });
        expect(records.length, equals(1));
        expect(records.first['id_hoc_sinh'], equals(2));
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

  // --- 4. CONSTRAINT UI TEST MATRIX ---
  group('Constraint UI Matrix Tests', () {
    testWidgets(
      'showAddConstraintDialog supports HARD_BLOCK, SOFT_PREFERENCE, OTHER_CENTER, and MOT_LAN',
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

        expect(find.text('Thêm ràng buộc lịch học sinh'), findsOneWidget);

        // Save HARD_BLOCK DINH_KY
        await tester.tap(find.text('Lưu ràng buộc'));
        await waitForAsyncProviders(tester);

        late List<Map<String, dynamic>> records;
        await tester.runAsync(() async {
          records = await db.query('rang_buoc_lich_hoc_sinh');
        });
        expect(records.length, equals(1));
        expect(records.first['loai'], equals('HARD_BLOCK'));
        expect(records.first['kieu'], equals('DINH_KY'));

        await tester.runAsync(() async => db.close());
      },
    );
  });

  // --- 5. SCHEDULE CONFLICT BANNER TESTS ---
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

  // --- 6. ASSIGNMENT UI FAIL-CLOSED TESTS ---
  group('Assignment UI Fail-Closed Tests', () {
    testWidgets(
      'AssignStudentDialog disables confirm button on preview loading and error',
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

        // Confirm button is disabled while student is unselected or preview loading
        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Xác nhận'),
        );
        expect(confirmBtn.onPressed, isNull);

        pendingCompleter.complete(ScheduleConflictResult.clear());
        await tester.runAsync(() async => db.close());
      },
    );
  });
}
