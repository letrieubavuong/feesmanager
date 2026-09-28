import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:tuition2027/features/settings/data/app_lock_repository.dart';
import 'package:tuition2027/features/settings/presentation/app_lock_controller.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    iOptions,
    aOptions,
    eOptions,
    mOptions,
    lOptions,
    wOptions,
    webOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    iOptions,
    aOptions,
    eOptions,
    mOptions,
    lOptions,
    wOptions,
    webOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    iOptions,
    aOptions,
    eOptions,
    mOptions,
    lOptions,
    wOptions,
    webOptions,
  }) async {
    _data.remove(key);
  }
}

class FakeLocalAuthentication extends LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => true;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [
    BiometricType.fingerprint,
  ];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object>? authMessages,
    Object? options,
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    return true;
  }
}

void main() {
  group('AppLockRepository & Controller Tests', () {
    late AppLockRepository repository;
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
      repository = AppLockRepository(
        storage: storage,
        auth: FakeLocalAuthentication(),
      );
    });

    test('PIN is not set initially', () async {
      expect(await repository.isPinSet(), isFalse);
    });

    test('setPin hashes PIN with salt and verifies correctly', () async {
      await repository.setPin('1234');
      expect(await repository.isPinSet(), isTrue);

      final isCorrect = await repository.verifyPin('1234');
      expect(isCorrect, isTrue);

      final isWrong = await repository.verifyPin('9999');
      expect(isWrong, isFalse);
    });

    test('5 failed attempts triggers 30-second lockout', () async {
      await repository.setPin('1234');

      for (int i = 0; i < 4; i++) {
        expect(await repository.verifyPin('0000'), isFalse);
      }

      expect(await repository.getLockoutEndTime(), isNull);

      // 5th failed attempt
      expect(await repository.verifyPin('0000'), isFalse);

      final lockoutEnd = await repository.getLockoutEndTime();
      expect(lockoutEnd, isNotNull);
      expect(lockoutEnd!.isAfter(DateTime.now()), isTrue);

      // Even correct PIN is rejected during lockout!
      expect(await repository.verifyPin('1234'), isFalse);
    });

    test('removePin clears PIN and verifier', () async {
      await repository.setPin('1234');
      expect(await repository.isPinSet(), isTrue);

      await repository.removePin();
      expect(await repository.isPinSet(), isFalse);
    });

    test(
      'AppLockController locks app when PIN is set and unlocks on valid PIN',
      () async {
        final controller = AppLockController(repository);
        await controller.setPin('1234');

        controller.lockApp();
        expect(controller.state.isLocked, isTrue);

        final unlocked = await controller.unlockWithPin('1234');
        expect(unlocked, isTrue);
        expect(controller.state.isLocked, isFalse);
      },
    );
  });
}
