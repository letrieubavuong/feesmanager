import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/dirty_form_scope.dart';
import '../../../app/navigation/app_global_drawer.dart';
import '../domain/class.dart';
import 'class_controller.dart';

class ClassFormPage extends ConsumerStatefulWidget {
  final ClassEntity? cls;
  const ClassFormPage({super.key, this.cls});

  @override
  ConsumerState<ClassFormPage> createState() => _ClassFormPageState();
}

class _ClassFormPageState extends ConsumerState<ClassFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tenLopController;
  late TextEditingController _monHocController;
  late TextEditingController _siSoToiDaController;
  late TextEditingController _ghiChuController;
  int? _khoi;
  bool _isDirty = false;

  void _onChanged() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final c = widget.cls;
    _tenLopController = TextEditingController(text: c?.tenLop)..addListener(_onChanged);
    _monHocController = TextEditingController(text: c?.monHoc)..addListener(_onChanged);
    _siSoToiDaController = TextEditingController(
      text: c?.siSoToiDa?.toString(),
    )..addListener(_onChanged);
    _ghiChuController = TextEditingController(text: c?.ghiChu)..addListener(_onChanged);
    _khoi = c?.khoi;
  }

  @override
  void dispose() {
    _tenLopController.dispose();
    _monHocController.dispose();
    _siSoToiDaController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DirtyFormScope(
      isDirty: _isDirty,
      child: Scaffold(
        drawer: const AppGlobalDrawer(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const BackButton(),
          title: Text(widget.cls == null ? 'Thêm lớp học' : 'Sửa lớp học'),
          actions: [
            const GlobalMenuButton(),
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _tenLopController,
                  decoration: const InputDecoration(
                    labelText: 'Tên lớp *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Vui lòng nhập tên lớp'
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
                        onChanged: (v) {
                          _onChanged();
                          setState(() => _khoi = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _siSoToiDaController,
                        decoration: const InputDecoration(
                          labelText: 'Sĩ số tối đa',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monHocController,
                  decoration: const InputDecoration(
                    labelText: 'Môn học',
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
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final classEntity =
        (widget.cls ??
                ClassEntity(
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  tenLop: '',
                ))
            .copyWith(
              tenLop: _tenLopController.text,
              monHoc: _monHocController.text,
              siSoToiDa: int.tryParse(_siSoToiDaController.text),
              khoi: _khoi,
              ghiChu: _ghiChuController.text,
            );

    final success = await ref
        .read(classFormControllerProvider.notifier)
        .save(classEntity);
    if (success && mounted) {
      _isDirty = false;
      ref.read(classListControllerProvider.notifier).refresh();
      Navigator.of(context).pop();
    }
  }
}
