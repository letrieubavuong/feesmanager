import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_lock_controller.dart';
import 'lock_screen.dart';

class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused) {
      final lockState = ref.read(appLockControllerProvider);
      if (lockState.isPinSet &&
          !lockState.isPromptingBiometrics &&
          !lockState.isLocked) {
        ref.read(appLockControllerProvider.notifier).lockApp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);

    if (lockState.isPinSet && lockState.isLocked) {
      return const LockScreen();
    }

    return widget.child;
  }
}
