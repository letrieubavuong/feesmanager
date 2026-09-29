import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/school_repository.dart';
import '../domain/school_catalog_service.dart';

final schoolCatalogServiceProvider = FutureProvider<SchoolCatalogService>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return SchoolCatalogService(SchoolRepository(db));
});

final schoolCatalogProvider = FutureProvider<List<String>>((ref) async {
  final service = await ref.watch(schoolCatalogServiceProvider.future);
  return service.list();
});
