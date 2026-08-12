/// Text normalization helpers shared by the capture parsers.
///
/// Voice dictation and OCR both return text with unpredictable casing and
/// accents ("Almuerzo", "almuerzo", "ALMUERZO"), so every keyword comparison
/// runs over the normalized form.
class TextNormalizer {
  const TextNormalizer._();

  static const _accents = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  static const _plain = 'aaaaaeeeeiiiiooooouuuunc';

  /// Lowercases and strips accents. Leaves everything else untouched.
  static String normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      final index = _accents.indexOf(char);
      buffer.write(index == -1 ? char : _plain[index]);
    }
    return buffer.toString();
  }

  /// Normalizes and removes anything that is not a letter, digit or space,
  /// collapsing runs of whitespace. Useful for keyword matching.
  static String normalizeWords(String input) {
    return normalize(input)
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Capitalizes the first letter, leaving the rest as dictated.
  static String capitalize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
