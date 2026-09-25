import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/navigation/app_global_drawer.dart';
import 'class_controller.dart';
import 'class_form_page.dart';
import 'class_detail_page.dart';
import '../domain/class.dart';
import '../../memberships/presentation/membership_providers.dart';

import '../domain/class_filter.dart';

class ClassListPage extends ConsumerStatefulWidget {
  const ClassListPage({super.key});

  @override
  ConsumerState<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends ConsumerState<ClassListPage> {
  final _searchController = TextEditingController();
  ClassFilter _filter = ClassFilter.active;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classListAsync = ref.watch(classListControllerProvider);

    return Scaffold(
      drawer: const AppGlobalDrawer(),
      appBar: AppBar(
        leading: const GlobalMenuButton(),
        title: const Text('Lớp học'),
        actions: [
          PopupMenuButton<ClassFilter>(
            initialValue: _filter,
            onSelected: (value) {
              setState(() => _filter = value);
              ref.read(classListControllerProvider.notifier).setFilter(value);
            },
            itemBuilder: (context) => ClassFilter.values
                .map((f) => PopupMenuItem(value: f, child: Text(f.label)))
                .toList(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm kiếm tên lớp, môn học...',
              onChanged: (value) {
                ref.read(classListControllerProvider.notifier).search(value);
              },
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(classListControllerProvider.notifier).search('');
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: classListAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Text(
                'Không tìm thấy lớp học nào (${_filter.label.toLowerCase()}).',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(classListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: classes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cls = classes[index];
                return ClassListTile(cls: cls);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ClassFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ClassListTile extends ConsumerWidget {
  final ClassEntity cls;
  const ClassListTile({super.key, required this.cls});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizeAsync = ref.watch(classSizeProvider(cls.id!));

    return ListTile(
      title: Text(
        cls.tenLop,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: cls.daLuuTru ? TextDecoration.lineThrough : null,
          color: cls.daLuuTru ? Colors.grey : null,
        ),
      ),
      subtitle: Text(
        '${cls.khoi != null ? 'Khối ${cls.khoi}' : ''} ${cls.monHoc != null ? '• ${cls.monHoc}' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          sizeAsync.when(
            data: (size) => Text(
              '$size / ${cls.siSoToiDa ?? '∞'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: (cls.siSoToiDa != null && size >= cls.siSoToiDa!)
                    ? Colors.red
                    : null,
              ),
            ),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text('?'),
          ),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassDetailPage(classId: cls.id!),
          ),
        );
      },
    );
  }
}
