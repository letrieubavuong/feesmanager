import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/student.dart';
import 'student_controller.dart';

class StudentFormPage extends ConsumerStatefulWidget {
  final Student? student;
  const StudentFormPage({super.key, this.student});

  @override
  ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends ConsumerState<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _hoTenController;
  late TextEditingController _ngaySinhController;
  late TextEditingController _tenPhuHuynhController;
  late TextEditingController _sdtPhuHuynhController;
  late TextEditingController _sdtHocSinhController;
  late TextEditingController _emailController;
  late TextEditingController _truongController;
  late TextEditingController _diaChiController;
  late TextEditingController _facebookController;
  late TextEditingController _ghiChuController;

  int? _khoi;
  String? _gioiTinh;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _hoTenController = TextEditingController(text: s?.hoTen);
    _ngaySinhController = TextEditingController(text: s?.ngaySinh);
    _tenPhuHuynhController = TextEditingController(text: s?.tenPhuHuynh);
    _sdtPhuHuynhController = TextEditingController(text: s?.sdtPhuHuynh);
    _sdtHocSinhController = TextEditingController(text: s?.sdtHocSinh);
    _emailController = TextEditingController(text: s?.email);
    _truongController = TextEditingController(text: s?.truongDangHoc);
    _diaChiController = TextEditingController(text: s?.diaChi);
    _facebookController = TextEditingController(text: s?.facebook);
    _ghiChuController = TextEditingController(text: s?.ghiChu);
    _khoi = s?.khoi;
    _gioiTinh = s?.gioiTinh;
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _ngaySinhController.dispose();
    _tenPhuHuynhController.dispose();
    _sdtPhuHuynhController.dispose();
    _sdtHocSinhController.dispose();
    _emailController.dispose();
    _truongController.dispose();
    _diaChiController.dispose();
    _facebookController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Thêm học sinh' : 'Sửa học sinh'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _hoTenController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập họ tên'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _khoi,
                      decoration: const InputDecoration(
                        labelText: 'Khối',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(12, (index) => index + 1)
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text('Khối $k'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _khoi = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gioiTinh,
                      decoration: const InputDecoration(
                        labelText: 'Giới tính',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'NAM', child: Text('Nam')),
                        DropdownMenuItem(value: 'NU', child: Text('Nữ')),
                        DropdownMenuItem(value: 'KHAC', child: Text('Khác')),
                      ],
                      onChanged: (v) => setState(() => _gioiTinh = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _truongController,
                decoration: const InputDecoration(
                  labelText: 'Trường đang học',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Thông tin phụ huynh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tenPhuHuynhController,
                decoration: const InputDecoration(
                  labelText: 'Tên phụ huynh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sdtPhuHuynhController,
                decoration: const InputDecoration(
                  labelText: 'SĐT phụ huynh',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Liên hệ khác',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sdtHocSinhController,
                decoration: const InputDecoration(
                  labelText: 'SĐT học sinh',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diaChiController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _facebookController,
                decoration: const InputDecoration(
                  labelText: 'Facebook',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ghiChuController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final student =
        (widget.student ??
                Student(
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  hoTen: '',
                ))
            .copyWith(
              hoTen: _hoTenController.text,
              ngaySinh: _ngaySinhController.text,
              tenPhuHuynh: _tenPhuHuynhController.text,
              sdtPhuHuynh: _sdtPhuHuynhController.text,
              sdtHocSinh: _sdtHocSinhController.text,
              email: _emailController.text,
              truongDangHoc: _truongController.text,
              khoi: _khoi,
              gioiTinh: _gioiTinh,
              diaChi: _diaChiController.text,
              facebook: _facebookController.text,
              ghiChu: _ghiChuController.text,
            );

    final success = await ref
        .read(studentFormControllerProvider.notifier)
        .save(student);
    if (success && mounted) {
      ref.read(studentListControllerProvider.notifier).refresh();
      Navigator.of(context).pop();
    }
  }
}
