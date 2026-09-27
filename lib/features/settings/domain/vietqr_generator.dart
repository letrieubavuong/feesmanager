import 'bank_account_settings.dart';

class VietQrGenerator {
  /// Generates a standard VietQR EMVCo string payload.
  static String generateEmvCoPayload({
    required BankAccountSettings settings,
    int? amount,
    String? transferContent,
  }) {
    if (!settings.isConfigured) return '';

    final StringBuffer buffer = StringBuffer();

    // Tag 00: Payload Format Indicator
    buffer.write('000201');

    // Tag 01: Point of Initiation Method (12 = Dynamic, 11 = Static)
    buffer.write(amount != null && amount > 0 ? '010212' : '010211');

    // Tag 38: Merchant Account Information
    final bankBin = settings.bankBin.trim();
    final accNo = settings.accountNumber.trim();

    // Sub-tag 00: GUID
    const guid = 'A000000727';
    final sub00 = '00${_formatLength(guid.length)}$guid';

    // Sub-tag 01: Consumer ID (Bank Bin + Account Number)
    final sub0100 = '00${_formatLength(bankBin.length)}$bankBin';
    final sub0101 = '01${_formatLength(accNo.length)}$accNo';
    final sub01Content = '$sub0100$sub0101';
    final sub01 = '01${_formatLength(sub01Content.length)}$sub01Content';

    // Sub-tag 02: Service Code
    const serviceCode = 'QRIBFTTA';
    final sub02 = '02${_formatLength(serviceCode.length)}$serviceCode';

    final tag38Content = '$sub00$sub01$sub02';
    buffer.write('38${_formatLength(tag38Content.length)}$tag38Content');

    // Tag 53: Transaction Currency (704 = VND)
    buffer.write('5303704');

    // Tag 54: Transaction Amount (if present)
    if (amount != null && amount > 0) {
      final amountStr = amount.toString();
      buffer.write('54${_formatLength(amountStr.length)}$amountStr');
    }

    // Tag 58: Country Code
    buffer.write('5802VN');

    // Tag 62: Additional Data Field (Transfer content)
    if (transferContent != null && transferContent.trim().isNotEmpty) {
      final content = _sanitizeContent(transferContent.trim());
      final sub08 = '08${_formatLength(content.length)}$content';
      buffer.write('62${_formatLength(sub08.length)}$sub08');
    }

    // Tag 63: CRC16
    final rawForCrc = '${buffer.toString()}6304';
    final crc = _calculateCrc16(rawForCrc);
    final crcHex = crc.toRadixString(16).padLeft(4, '0').toUpperCase();

    return '$rawForCrc$crcHex';
  }

  /// Formats transfer content from template string.
  /// Example template: "HP {maHocSinh} {thang}"
  static String formatTransferContent({
    required String template,
    String? studentCode,
    String? month,
  }) {
    String result = template;
    result = result.replaceAll('{maHocSinh}', studentCode ?? '');
    result = result.replaceAll('{thang}', month ?? '');
    return _sanitizeContent(result.trim());
  }

  static String _formatLength(int length) {
    return length.toString().padLeft(2, '0');
  }

  static String _sanitizeContent(String input) {
    var output = input;
    const map = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'À': 'A',
      'Á': 'A',
      'Ả': 'A',
      'Ã': 'A',
      'Ạ': 'A',
      'Ă': 'A',
      'Ằ': 'A',
      'Ắ': 'A',
      'Ẳ': 'A',
      'Ẵ': 'A',
      'Ặ': 'A',
      'Â': 'A',
      'Ầ': 'A',
      'Ấ': 'A',
      'Ẩ': 'A',
      'Ẫ': 'A',
      'Ậ': 'A',
      'Đ': 'D',
      'È': 'E',
      'É': 'E',
      'Ẻ': 'E',
      'Ẽ': 'E',
      'Ẹ': 'E',
      'Ê': 'E',
      'Ề': 'E',
      'Ế': 'E',
      'Ể': 'E',
      'Ễ': 'E',
      'Ệ': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Ỉ': 'I',
      'Ĩ': 'I',
      'Ị': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ỏ': 'O',
      'Õ': 'O',
      'Ọ': 'O',
      'Ô': 'O',
      'Ồ': 'O',
      'Ố': 'O',
      'Ổ': 'O',
      'Ỗ': 'O',
      'Ộ': 'O',
      'Ơ': 'O',
      'Ờ': 'O',
      'Ớ': 'O',
      'Ở': 'O',
      'Ỡ': 'O',
      'Ợ': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Ủ': 'U',
      'Ũ': 'U',
      'Ụ': 'U',
      'Ư': 'U',
      'Ừ': 'U',
      'Ứ': 'U',
      'Ử': 'U',
      'Ữ': 'U',
      'Ự': 'U',
      'Ỳ': 'Y',
      'Ý': 'Y',
      'Ỷ': 'Y',
      'Ỹ': 'Y',
      'Ỵ': 'Y',
    };
    map.forEach((key, value) {
      output = output.replaceAll(key, value);
    });
    output = output.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    return output.toUpperCase();
  }

  static int _calculateCrc16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      int byte = data.codeUnitAt(i);
      crc ^= (byte << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc & 0xFFFF;
  }
}
