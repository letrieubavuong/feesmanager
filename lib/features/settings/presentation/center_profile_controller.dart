import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CenterProfile {
  const CenterProfile({
    this.name = 'Tuition2027',
    this.address = '',
    this.phone = '',
  });

  final String name;
  final String address;
  final String phone;

  String get subtitle {
    if (address.trim().isNotEmpty) return address.trim();
    return phone.trim();
  }
}

final centerProfileProvider =
    NotifierProvider<CenterProfileController, CenterProfile>(
      CenterProfileController.new,
    );

class CenterProfileController extends Notifier<CenterProfile> {
  @override
  CenterProfile build() {
    _load();
    return const CenterProfile();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = CenterProfile(
        name: prefs.getString('center_name') ?? 'Tuition2027',
        address: prefs.getString('center_address') ?? '',
        phone: prefs.getString('center_phone') ?? '',
      );
    } catch (_) {
      // The default title remains available while preferences load.
    }
  }

  Future<void> save(CenterProfile profile) async {
    final name = profile.name.trim();
    if (name.isEmpty) throw ArgumentError('Tên trung tâm không được để trống');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('center_name', name);
    await prefs.setString('center_address', profile.address.trim());
    await prefs.setString('center_phone', profile.phone.trim());
    state = CenterProfile(
      name: name,
      address: profile.address.trim(),
      phone: profile.phone.trim(),
    );
  }
}
