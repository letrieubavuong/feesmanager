import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const _keyPinSalt = 'app_lock_pin_salt';
const _keyPinVerifier = 'app_lock_pin_verifier';
const _keyBiometricsEnabled = 'app_lock_biometrics_enabled';
const _keyFailedAttempts = 'app_lock_failed_attempts';
const _keyLockoutUntil = 'app_lock_lockout_until';

class AppLockRepository {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  AppLockRepository({FlutterSecureStorage? storage, LocalAuthentication? auth})
    : _storage = storage ?? const FlutterSecureStorage(),
      _auth = auth ?? LocalAuthentication();

  Future<bool> isPinSet() async {
    final verifier = await _storage.read(key: _keyPinVerifier);
    return verifier != null && verifier.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final saltHex = base64Encode(saltBytes);
    final verifier = _hashPin(pin, saltHex);

    await _storage.write(key: _keyPinSalt, value: saltHex);
    await _storage.write(key: _keyPinVerifier, value: verifier);
    await resetFailedAttempts();
  }

  Future<bool> verifyPin(String pin) async {
    final lockoutEnd = await getLockoutEndTime();
    if (lockoutEnd != null && DateTime.now().isBefore(lockoutEnd)) {
      return false;
    }

    final saltHex = await _storage.read(key: _keyPinSalt);
    final verifier = await _storage.read(key: _keyPinVerifier);

    if (saltHex == null || verifier == null) return false;

    final computedHash = _hashPin(pin, saltHex);
    final isMatch = _constantTimeEquals(computedHash, verifier);

    if (isMatch) {
      await resetFailedAttempts();
      return true;
    } else {
      await incrementFailedAttempts();
      return false;
    }
  }

  Future<void> removePin() async {
    await _storage.delete(key: _keyPinSalt);
    await _storage.delete(key: _keyPinVerifier);
    await _storage.delete(key: _keyBiometricsEnabled);
    await resetFailedAttempts();
  }

  Future<bool> isBiometricsEnabled() async {
    final val = await _storage.read(key: _keyBiometricsEnabled);
    return val == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometrics(String reason) async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<int> getFailedAttempts() async {
    final str = await _storage.read(key: _keyFailedAttempts);
    return int.tryParse(str ?? '0') ?? 0;
  }

  Future<void> incrementFailedAttempts() async {
    final attempts = (await getFailedAttempts()) + 1;
    await _storage.write(key: _keyFailedAttempts, value: attempts.toString());

    if (attempts >= 5) {
      final lockoutEnd = DateTime.now().add(const Duration(seconds: 30));
      await _storage.write(
        key: _keyLockoutUntil,
        value: lockoutEnd.toIso8601String(),
      );
    }
  }

  Future<void> resetFailedAttempts() async {
    await _storage.write(key: _keyFailedAttempts, value: '0');
    await _storage.delete(key: _keyLockoutUntil);
  }

  Future<DateTime?> getLockoutEndTime() async {
    final str = await _storage.read(key: _keyLockoutUntil);
    if (str == null) return null;
    final date = DateTime.tryParse(str);
    if (date != null && DateTime.now().isAfter(date)) {
      await resetFailedAttempts();
      return null;
    }
    return date;
  }

  String _hashPin(String pin, String saltHex) {
    final bytes = utf8.encode('$saltHex:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
