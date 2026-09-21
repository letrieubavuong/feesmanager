class PhoneNormalizer {
  /// Normalizes a phone number to a canonical format for lookup.
  /// Example: "0905 123 456", "0905.123.456", "+84 905123456", "84905123456"
  /// all resolve to "0905123456".
  static String? normalize(String? phone) {
    if (phone == null || phone.isEmpty) return null;

    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return null;

    // Handle Vietnam international format
    if (digits.startsWith('84') && digits.length == 11) {
      digits = '0${digits.substring(2)}';
    } else if (digits.startsWith('0084') && digits.length == 13) {
      digits = '0${digits.substring(4)}';
    }

    return digits;
  }
}
