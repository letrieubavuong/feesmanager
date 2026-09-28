import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/design_system/app_semantic_colors.dart';
import 'app_lock_controller.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _inputPin = '';
  bool _hasAttemptedBio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoBiometrics();
    });
  }

  void _tryAutoBiometrics() async {
    final state = ref.read(appLockControllerProvider);
    if (!_hasAttemptedBio &&
        state.isBiometricsEnabled &&
        state.isBiometricsAvailable) {
      _hasAttemptedBio = true;
      ref.read(appLockControllerProvider.notifier).unlockWithBiometrics();
    }
  }

  void _onKeyPress(String digit) {
    if (_inputPin.length < 6) {
      setState(() {
        _inputPin += digit;
      });

      if (_inputPin.length >= 4) {
        _submitPin(_inputPin);
      }
    }
  }

  void _onBackspace() {
    if (_inputPin.isNotEmpty) {
      setState(() {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      });
    }
  }

  void _submitPin(String pin) async {
    final success = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithPin(pin);
    if (!success && mounted) {
      setState(() {
        _inputPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final lockState = ref.watch(appLockControllerProvider);
    final isLockedOut = lockState.lockoutSecondsRemaining > 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Tuition2027',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLockedOut
                    ? 'Tạm khóa mở bằng PIN'
                    : 'Nhập mã PIN để mở khóa ứng dụng',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // PIN Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _inputPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHigh,
                      border: Border.all(
                        color: isFilled
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Error or Lockout Message
              if (lockState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    lockState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: semantics.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const Spacer(),

              // Numeric Keypad (3x4 Grid)
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  children: [
                    _buildRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometrics action or Empty
                        if (lockState.isBiometricsEnabled &&
                            lockState.isBiometricsAvailable)
                          IconButton(
                            iconSize: 32,
                            icon: Icon(
                              Icons.fingerprint,
                              color: colorScheme.primary,
                            ),
                            onPressed: () {
                              ref
                                  .read(appLockControllerProvider.notifier)
                                  .unlockWithBiometrics();
                            },
                          )
                        else
                          const SizedBox(width: 64, height: 64),

                        _buildKeyButton('0'),

                        IconButton(
                          iconSize: 28,
                          icon: Icon(
                            Icons.backspace_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: isLockedOut ? null : _onBackspace,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeyButton(d)).toList(),
    );
  }

  Widget _buildKeyButton(String digit) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLockedOut =
        ref.read(appLockControllerProvider).lockoutSecondsRemaining > 0;

    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: EdgeInsets.zero,
        ),
        onPressed: isLockedOut ? null : () => _onKeyPress(digit),
        child: Text(
          digit,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
