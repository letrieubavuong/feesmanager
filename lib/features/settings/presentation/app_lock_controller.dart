import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_lock_repository.dart';

final appLockRepositoryProvider = Provider<AppLockRepository>((ref) {
  return AppLockRepository();
});

class AppLockState {
  final bool isPinSet;
  final bool isBiometricsEnabled;
  final bool isBiometricsAvailable;
  final bool isLocked;
  final int failedAttempts;
  final int lockoutSecondsRemaining;
  final String? errorMessage;
  final bool isPromptingBiometrics;

  const AppLockState({
    required this.isPinSet,
    required this.isBiometricsEnabled,
    required this.isBiometricsAvailable,
    required this.isLocked,
    this.failedAttempts = 0,
    this.lockoutSecondsRemaining = 0,
    this.errorMessage,
    this.isPromptingBiometrics = false,
  });

  AppLockState copyWith({
    bool? isPinSet,
    bool? isBiometricsEnabled,
    bool? isBiometricsAvailable,
    bool? isLocked,
    int? failedAttempts,
    int? lockoutSecondsRemaining,
    String? errorMessage,
    bool? isPromptingBiometrics,
  }) {
    return AppLockState(
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isBiometricsAvailable:
          isBiometricsAvailable ?? this.isBiometricsAvailable,
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutSecondsRemaining:
          lockoutSecondsRemaining ?? this.lockoutSecondsRemaining,
      errorMessage: errorMessage,
      isPromptingBiometrics:
          isPromptingBiometrics ?? this.isPromptingBiometrics,
    );
  }
}

class AppLockController extends StateNotifier<AppLockState> {
  final AppLockRepository _repository;
  Timer? _lockoutTimer;

  AppLockController(this._repository)
    : super(
        const AppLockState(
          isPinSet: false,
          isBiometricsEnabled: false,
          isBiometricsAvailable: false,
          isLocked: false,
        ),
      ) {
    _loadState();
  }

  Future<void> _loadState() async {
    final isPinSet = await _repository.isPinSet();
    final isBioEnabled = await _repository.isBiometricsEnabled();
    final isBioAvailable = await _repository.isBiometricsAvailable();
    final failedAttempts = await _repository.getFailedAttempts();
    final lockoutEnd = await _repository.getLockoutEndTime();

    int lockoutRemaining = 0;
    if (lockoutEnd != null) {
      lockoutRemaining = lockoutEnd.difference(DateTime.now()).inSeconds;
      if (lockoutRemaining > 0) {
        _startLockoutCountdown(lockoutRemaining);
      }
    }

    state = AppLockState(
      isPinSet: isPinSet,
      isBiometricsEnabled: isBioEnabled,
      isBiometricsAvailable: isBioAvailable,
      isLocked: isPinSet, // Automatically locked on startup if PIN is set
      failedAttempts: failedAttempts,
      lockoutSecondsRemaining: lockoutRemaining,
    );
  }

  void setPromptingBiometrics(bool isPrompting) {
    state = state.copyWith(isPromptingBiometrics: isPrompting);
  }

  void lockApp() {
    if (state.isPinSet && !state.isLocked) {
      state = state.copyWith(isLocked: true, errorMessage: null);
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    if (state.lockoutSecondsRemaining > 0) {
      state = state.copyWith(
        errorMessage:
            'Vui lòng thử lại sau ${state.lockoutSecondsRemaining} giây',
      );
      return false;
    }

    final isValid = await _repository.verifyPin(pin);
    if (isValid) {
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        errorMessage: null,
      );
      return true;
    } else {
      final attempts = await _repository.getFailedAttempts();
      final lockoutEnd = await _repository.getLockoutEndTime();
      int remaining = 0;
      if (lockoutEnd != null) {
        remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          _startLockoutCountdown(remaining);
        }
      }

      state = state.copyWith(
        failedAttempts: attempts,
        lockoutSecondsRemaining: remaining,
        errorMessage: remaining > 0
            ? 'Nhập sai 5 lần. Tạm khóa trong $remaining giây'
            : 'Mã PIN không đúng ($attempts/5 lần)',
      );
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    if (!state.isBiometricsAvailable || !state.isBiometricsEnabled) {
      return false;
    }

    setPromptingBiometrics(true);
    try {
      final success = await _repository.authenticateBiometrics(
        'Xác thực sinh trắc học để mở khóa Tuition2027',
      );
      if (success) {
        await _repository.resetFailedAttempts();
        state = state.copyWith(
          isLocked: false,
          failedAttempts: 0,
          errorMessage: null,
        );
        return true;
      }
    } finally {
      setPromptingBiometrics(false);
    }
    return false;
  }

  Future<bool> setPin(String newPin) async {
    if (newPin.length < 4 || newPin.length > 6) {
      state = state.copyWith(errorMessage: 'Mã PIN phải gồm 4 đến 6 chữ số');
      return false;
    }

    await _repository.setPin(newPin);
    state = state.copyWith(isPinSet: true, isLocked: false, errorMessage: null);
    return true;
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    final isCurrentValid = await _repository.verifyPin(currentPin);
    if (!isCurrentValid) {
      state = state.copyWith(errorMessage: 'Mã PIN hiện tại không đúng');
      return false;
    }

    return await setPin(newPin);
  }

  Future<bool> removePin(String currentPin) async {
    final isCurrentValid = await _repository.verifyPin(currentPin);
    if (!isCurrentValid) {
      state = state.copyWith(errorMessage: 'Mã PIN hiện tại không đúng');
      return false;
    }

    await _repository.removePin();
    state = state.copyWith(
      isPinSet: false,
      isBiometricsEnabled: false,
      isLocked: false,
      errorMessage: null,
    );
    return true;
  }

  Future<bool> setBiometricsEnabled(bool enabled) async {
    if (enabled) {
      final isAvailable = await _repository.isBiometricsAvailable();
      if (!isAvailable) {
        state = state.copyWith(
          errorMessage: 'Thiết bị không hỗ trợ hoặc chưa cài sinh trắc học',
        );
        return false;
      }

      setPromptingBiometrics(true);
      try {
        final authenticated = await _repository.authenticateBiometrics(
          'Xác nhận sinh trắc học để bật khóa ứng dụng',
        );
        if (!authenticated) return false;
      } finally {
        setPromptingBiometrics(false);
      }
    }

    await _repository.setBiometricsEnabled(enabled);
    state = state.copyWith(isBiometricsEnabled: enabled, errorMessage: null);
    return true;
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    state = state.copyWith(lockoutSecondsRemaining: seconds);

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.lockoutSecondsRemaining - 1;
      if (current <= 0) {
        timer.cancel();
        state = state.copyWith(lockoutSecondsRemaining: 0, errorMessage: null);
      } else {
        state = state.copyWith(lockoutSecondsRemaining: current);
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}

final appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
      final repository = ref.watch(appLockRepositoryProvider);
      return AppLockController(repository);
    });
