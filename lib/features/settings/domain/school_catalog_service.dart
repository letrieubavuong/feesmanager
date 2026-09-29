import '../data/school_repository.dart';

class SchoolCatalogService {
  final SchoolRepository repository;
  SchoolCatalogService(this.repository);

  Future<List<String>> list() => repository.list();

  Future<void> add(String name) async {
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) throw Exception('Vui lòng nhập tên trường');
    await repository.add(normalized);
  }

  Future<void> remove(String name) => repository.remove(name);
}
