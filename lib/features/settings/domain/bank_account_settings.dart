import 'dart:convert';

class BankInfo {
  final String name;
  final String code;
  final String bin;

  const BankInfo({required this.name, required this.code, required this.bin});
}

class SupportedBanks {
  static const List<BankInfo> list = [
    BankInfo(name: 'Vietcombank', code: 'VCB', bin: '970436'),
    BankInfo(name: 'VietinBank', code: 'CTG', bin: '970415'),
    BankInfo(name: 'BIDV', code: 'BIDV', bin: '970418'),
    BankInfo(name: 'MBBank', code: 'MB', bin: '970422'),
    BankInfo(name: 'Techcombank', code: 'TCB', bin: '970407'),
    BankInfo(name: 'TPBank', code: 'TPB', bin: '970423'),
    BankInfo(name: 'VPBank', code: 'VPB', bin: '970432'),
    BankInfo(name: 'ACB', code: 'ACB', bin: '970416'),
    BankInfo(name: 'Sacombank', code: 'STB', bin: '970403'),
    BankInfo(name: 'Agribank', code: 'VBA', bin: '970405'),
    BankInfo(name: 'SHB', code: 'SHB', bin: '970443'),
    BankInfo(name: 'MSB', code: 'MSB', bin: '970426'),
    BankInfo(name: 'HDBank', code: 'HDB', bin: '970437'),
    BankInfo(name: 'VIB', code: 'VIB', bin: '970441'),
    BankInfo(name: 'OCB', code: 'OCB', bin: '970448'),
    BankInfo(name: 'LPBank', code: 'LPB', bin: '970449'),
    BankInfo(name: 'Eximbank', code: 'EIB', bin: '970431'),
    BankInfo(name: 'SeABank', code: 'SEAB', bin: '970433'),
  ];

  static BankInfo findByCodeOrBin(String? query) {
    if (query == null || query.isEmpty) return list.first;
    return list.firstWhere(
      (b) => b.code == query || b.bin == query || b.name == query,
      orElse: () => list.first,
    );
  }
}

class BankAccountSettings {
  final String bankName;
  final String bankCode;
  final String bankBin;
  final String accountNumber;
  final String accountHolder;
  final String transferTemplate;

  const BankAccountSettings({
    required this.bankName,
    required this.bankCode,
    required this.bankBin,
    required this.accountNumber,
    required this.accountHolder,
    required this.transferTemplate,
  });

  static const BankAccountSettings defaultSettings = BankAccountSettings(
    bankName: 'MBBank',
    bankCode: 'MB',
    bankBin: '970422',
    accountNumber: '',
    accountHolder: '',
    transferTemplate: 'HP {maHocSinh} {thang}',
  );

  bool get isConfigured =>
      accountNumber.trim().isNotEmpty && accountHolder.trim().isNotEmpty;

  BankAccountSettings copyWith({
    String? bankName,
    String? bankCode,
    String? bankBin,
    String? accountNumber,
    String? accountHolder,
    String? transferTemplate,
  }) {
    return BankAccountSettings(
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      bankBin: bankBin ?? this.bankBin,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      transferTemplate: transferTemplate ?? this.transferTemplate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'bankCode': bankCode,
      'bankBin': bankBin,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'transferTemplate': transferTemplate,
    };
  }

  factory BankAccountSettings.fromMap(Map<String, dynamic> map) {
    return BankAccountSettings(
      bankName: map['bankName'] as String? ?? 'MBBank',
      bankCode: map['bankCode'] as String? ?? 'MB',
      bankBin: map['bankBin'] as String? ?? '970422',
      accountNumber: map['accountNumber'] as String? ?? '',
      accountHolder: map['accountHolder'] as String? ?? '',
      transferTemplate:
          map['transferTemplate'] as String? ?? 'HP {maHocSinh} {thang}',
    );
  }

  String toJson() => json.encode(toMap());

  factory BankAccountSettings.fromJson(String source) =>
      BankAccountSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}
