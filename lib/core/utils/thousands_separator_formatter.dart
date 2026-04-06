import 'package:flutter/services.dart';

/// Formats integers with '.' as thousands separator (Colombian convention).
/// Strips non-digit characters. Does NOT support decimals.
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Strip all dots to get the raw digits
    final clean = newValue.text.replaceAll('.', '');
    if (!RegExp(r'^\d+$').hasMatch(clean)) return oldValue;

    final formatted = _addSeparators(clean);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addSeparators(String value) {
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i != 0 && (value.length - i) % 3 == 0) buffer.write('.');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  /// Parses a formatted string (with dots) back to a double.
  static double parse(String formatted) {
    return double.tryParse(formatted.replaceAll('.', '')) ?? 0;
  }
}
