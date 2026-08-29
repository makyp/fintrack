/// The currencies the app can hold money in.
///
/// Deliberately a short, hand-picked list instead of the full ISO 4217 table:
/// these are the ones our users actually keep accounts in, and a picker with
/// 180 entries is worse than one with 15.
class Currency {
  final String code;
  final String symbol;
  final String name;

  /// How many decimals this currency is quoted with. Zero for the ones where
  /// cents stopped meaning anything (COP, CLP, PYG) — printing "$ 1.250,00"
  /// there reads as noise.
  final int decimals;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimals = 2,
  });

  /// "COP · Peso colombiano" — for pickers and lists.
  String get label => '$code · $name';

  static const cop = Currency(
      code: 'COP', symbol: r'$', name: 'Peso colombiano', decimals: 0);

  static const catalog = <Currency>[
    cop,
    Currency(code: 'USD', symbol: r'US$', name: 'Dólar estadounidense'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'MXN', symbol: r'MX$', name: 'Peso mexicano'),
    Currency(code: 'ARS', symbol: r'AR$', name: 'Peso argentino'),
    Currency(code: 'BRL', symbol: r'R$', name: 'Real brasileño'),
    Currency(code: 'PEN', symbol: 'S/', name: 'Sol peruano'),
    Currency(
        code: 'CLP', symbol: r'CL$', name: 'Peso chileno', decimals: 0),
    Currency(code: 'UYU', symbol: r'$U', name: 'Peso uruguayo'),
    Currency(code: 'BOB', symbol: 'Bs', name: 'Boliviano'),
    Currency(
        code: 'PYG', symbol: '₲', name: 'Guaraní paraguayo', decimals: 0),
    Currency(code: 'GTQ', symbol: 'Q', name: 'Quetzal guatemalteco'),
    Currency(code: 'CRC', symbol: '₡', name: 'Colón costarricense'),
    Currency(code: 'DOP', symbol: r'RD$', name: 'Peso dominicano'),
    Currency(code: 'VES', symbol: 'Bs.S', name: 'Bolívar venezolano'),
  ];

  static final Map<String, Currency> _byCode = {
    for (final c in catalog) c.code: c,
  };

  /// Never throws: a code we don't ship (an old document, a manual edit) comes
  /// back as itself, so the amount still renders labelled instead of blowing up.
  static Currency byCode(String code) {
    final normalized = code.trim().toUpperCase();
    return _byCode[normalized] ??
        Currency(code: normalized, symbol: normalized, name: normalized);
  }

  static bool isKnown(String code) =>
      _byCode.containsKey(code.trim().toUpperCase());

  @override
  String toString() => code;
}
