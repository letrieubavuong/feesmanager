import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/common_widgets/app_feedback.dart';
import '../../../app/design_system/app_semantic_colors.dart';
import 'app_lock_controller.dart';

Future<bool?> showSetPinBottomSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _SetPinSheet(),
  );
}

class _SetPinSheet extends ConsumerStatefulWidget {
  const _SetPinSheet();

  @override
  ConsumerState<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends ConsumerState<_SetPinSheet> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _stepConfirm = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (!_stepConfirm) {
      if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
        setState(() => _error = 'Mã PIN phải từ 4 đến 6 chữ số');
        return;
      }
      setState(() {
        _stepConfirm = true;
        _error = null;
      });
      return;
    }

    if (pin != confirm) {
      setState(() => _error = 'Xác nhận mã PIN không khớp');
      return;
    }

    final success = await ref
        .read(appLockControllerProvider.notifier)
        .setPin(pin);
    if (success && mounted) {
      AppFeedback.showSuccessSnackBar(context, 'Đã bật khóa ứng dụng bằng PIN');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _stepConfirm ? 'Xác nhận mã PIN' : 'Tạo mã PIN mở khóa',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _stepConfirm
                  ? 'Nhập lại mã PIN để xác nhận'
                  : 'Nhập từ 4 đến 6 chữ số để thiết lập bảo mật',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: semantics.error, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _stepConfirm ? _confirmController : _pinController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
              decoration: InputDecoration(
                labelText: _stepConfirm ? 'Nhập lại mã PIN' : 'Mã PIN mới',
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_stepConfirm)
                  TextButton(
                    onPressed: () => setState(() {
                      _stepConfirm = false;
                      _confirmController.clear();
                      _error = null;
                    }),
                    child: const Text('Quay lại'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: _submit,
                  child: Text(_stepConfirm ? 'Hoàn tất' : 'Tiếp tục'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showChangePinBottomSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _ChangePinSheet(),
  );
}

class _ChangePinSheet extends ConsumerStatefulWidget {
  const _ChangePinSheet();

  @override
  ConsumerState<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends ConsumerState<_ChangePinSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    final current = _currentController.text.trim();
    final newPin = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPin.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (newPin.length < 4 ||
        newPin.length > 6 ||
        int.tryParse(newPin) == null) {
      setState(() => _error = 'Mã PIN mới phải từ 4 đến 6 chữ số');
      return;
    }

    if (newPin != confirm) {
      setState(() => _error = 'Xác nhận mã PIN mới không khớp');
      return;
    }

    final success = await ref
        .read(appLockControllerProvider.notifier)
        .changePin(current, newPin);

    if (success && mounted) {
      AppFeedback.showSuccessSnackBar(context, 'Đã đổi mã PIN thành công');
      Navigator.pop(context, true);
    } else if (mounted) {
      final lockState = ref.read(appLockControllerProvider);
      setState(
        () => _error = lockState.errorMessage ?? 'Không đổi được mã PIN',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đổi mã PIN mở khóa',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: semantics.error, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _currentController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Mã PIN hiện tại *',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Mã PIN mới *',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mã PIN mới *',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: _submit,
                    child: const Text('Lưu thay đổi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showDisableLockDialog(BuildContext context, WidgetRef ref) {
  final pinController = TextEditingController();
  String? error;

  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final semantics = AppSemanticColors.of(context);

          return AlertDialog(
            title: const Text('Tắt khóa ứng dụng'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập mã PIN hiện tại để xác nhận tắt khóa ứng dụng:',
                ),
                const SizedBox(height: 12),
                if (error != null) ...[
                  Text(
                    error!,
                    style: TextStyle(color: semantics.error, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: pinController,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Mã PIN hiện tại',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: semantics.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final pin = pinController.text.trim();
                  if (pin.isEmpty) {
                    setState(() => error = 'Vui lòng nhập mã PIN');
                    return;
                  }

                  final success = await ref
                      .read(appLockControllerProvider.notifier)
                      .removePin(pin);

                  if (success && dialogCtx.mounted) {
                    AppFeedback.showSuccessSnackBar(
                      context,
                      'Đã tắt khóa ứng dụng',
                    );
                    Navigator.pop(dialogCtx, true);
                  } else if (dialogCtx.mounted) {
                    final lockState = ref.read(appLockControllerProvider);
                    setState(() {
                      error = lockState.errorMessage ?? 'Mã PIN không đúng';
                    });
                  }
                },
                child: const Text('Tắt khóa'),
              ),
            ],
          );
        },
      );
    },
  );
}
