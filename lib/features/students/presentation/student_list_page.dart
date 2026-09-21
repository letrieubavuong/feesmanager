import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_controller.dart';
import 'student_form_page.dart';
import 'student_detail_page.dart';

class StudentListPage extends ConsumerStatefulWidget {
  const StudentListPage({super.key});

  @override
  ConsumerState<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends ConsumerState<StudentListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentListAsync = ref.watch(studentListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Học sinh'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm kiếm tên, SĐT, trường...',
              onChanged: (value) {
                ref.read(studentListControllerProvider.notifier).search(value);
              },
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(studentListControllerProvider.notifier).search('');
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: studentListAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy học sinh nào.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(studentListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  title: Text(
                    student.hoTen,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${student.khoi != null ? 'Khối ${student.khoi}' : ''} ${student.truongDangHoc != null ? '- ${student.truongDangHoc}' : ''}\nPH: ${student.tenPhuHuynh ?? 'N/A'} - ${student.sdtPhuHuynh ?? 'N/A'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StudentDetailPage(studentId: student.id!),
                      ),
                    );
                  },
                );
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
            MaterialPageRoute(
              builder: (context) => const StudentFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
