import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}

@Riverpod(keepAlive: true)
Future<Database> database(DatabaseRef ref) {
  return ref.watch(appDatabaseProvider).database;
}
