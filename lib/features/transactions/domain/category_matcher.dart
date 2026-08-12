import '../../../core/utils/text_normalizer.dart';
import 'entities/transaction.dart';

/// Keyword-based category suggestion, shared by the manual form, the voice
/// capture and the receipt OCR so the three routes always agree.
///
/// 100% local: no network, no paid API. Matching runs over accent-stripped
/// lowercase text, so "Café" and "cafe" behave the same.
class CategoryMatcher {
  const CategoryMatcher._();

  static const keywords = <TransactionCategory, List<String>>{
    TransactionCategory.food: [
      'almuerzo', 'comida', 'restaurante', 'cafe', 'pizza', 'burger',
      'sushi', 'desayuno', 'cena', 'mercado', 'supermercado', 'rappi', 'domicilio',
      'hamburguesa', 'pollo', 'sandwich', 'taco', 'ensalada', 'postre',
      'panaderia', 'helado', 'arepa', 'empanada', 'jugo', 'gaseosa',
    ],
    TransactionCategory.transport: [
      'uber', 'taxi', 'bus', 'metro', 'transporte', 'gasolina', 'combustible',
      'parqueadero', 'estacionamiento', 'peaje', 'tren', 'avion', 'vuelo',
      'didi', 'indriver', 'cabify', 'pasaje', 'recarga civica', 'terpel',
    ],
    TransactionCategory.entertainment: [
      'netflix', 'spotify', 'cine', 'pelicula', 'juego', 'concierto',
      'teatro', 'streaming', 'prime', 'disney', 'youtube', 'hbo', 'apple tv',
      'bar', 'discoteca', 'fiesta', 'cerveza', 'trago',
    ],
    TransactionCategory.health: [
      'farmacia', 'medico', 'doctor', 'hospital', 'clinica',
      'medicina', 'gym', 'gimnasio', 'dentista', 'psicologo', 'droga',
      'eps', 'cruz verde', 'locatel', 'examen',
    ],
    TransactionCategory.education: [
      'libro', 'curso', 'universidad', 'colegio', 'matricula',
      'udemy', 'coursera', 'tutoria', 'platzi', 'clase', 'semestre',
    ],
    TransactionCategory.home: [
      'alquiler', 'arriendo', 'luz', 'agua', 'gas', 'internet', 'cable',
      'mantenimiento', 'reparacion', 'mueble', 'hogar', 'limpieza',
      'administracion', 'epm', 'servicios publicos',
    ],
    TransactionCategory.clothing: [
      'ropa', 'zapatos', 'camisa', 'pantalon', 'vestido', 'moda',
      'tenis', 'zapatillas', 'chaqueta', 'abrigo', 'zara', 'koaj',
    ],
    TransactionCategory.shopping: [
      'temu', 'shein', 'amazon', 'aliexpress', 'mercado libre', 'mercadolibre',
      'linio', 'falabella', 'exito', 'jumbo', 'compra', 'pedido',
      'olimpica', 'd1', 'ara', 'ktronix', 'alkosto',
    ],
    TransactionCategory.technology: [
      'celular', 'laptop', 'computador', 'tablet', 'auriculares', 'teclado',
      'software', 'app', 'apple', 'samsung', 'mouse', 'cargador',
    ],
    TransactionCategory.services: [
      'telefono', 'plan', 'seguro', 'servicio', 'suscripcion',
      'mensualidad', 'factura', 'claro', 'movistar', 'tigo', 'wom',
    ],
    TransactionCategory.cleaning: [
      'aseo', 'jabon', 'detergente', 'shampoo', 'papel higienico',
      'crema dental', 'desodorante', 'peluqueria', 'lavanderia',
    ],
    TransactionCategory.salary: [
      'salario', 'sueldo', 'nomina', 'quincena', 'pago mensual',
    ],
    TransactionCategory.freelance: [
      'proyecto', 'freelance', 'consultoria', 'honorarios',
    ],
    TransactionCategory.investment: [
      'dividendo', 'interes', 'rendimiento', 'acciones', 'crypto',
      'bitcoin', 'bolsa', 'fondo', 'cdt',
    ],
    TransactionCategory.sale: [
      'venta', 'vendi', 'vendida', 'vendido',
    ],
    TransactionCategory.gift: [
      'regalo', 'obsequio', 'me regalaron',
    ],
    TransactionCategory.bonus: [
      'bono', 'bonificacion', 'prima', 'comision',
    ],
  };

  /// Returns the category whose keyword best matches [text], or `null` when
  /// nothing matches confidently.
  ///
  /// When [type] is given, only categories valid for that type are considered
  /// — otherwise a dictated income like "vendí la bici" could land on an
  /// expense-only category that the form cannot even display.
  static TransactionCategory? suggest(String text, {TransactionType? type}) {
    final normalized = TextNormalizer.normalizeWords(text);
    if (normalized.length < 3) return null;

    final allowed = type == null
        ? null
        : TransactionCategory.forType(type).toSet();

    TransactionCategory? best;
    var bestLength = 0;

    for (final entry in keywords.entries) {
      if (allowed != null && !allowed.contains(entry.key)) continue;
      for (final keyword in entry.value) {
        if (keyword.length <= bestLength) continue;
        if (_containsWord(normalized, keyword)) {
          best = entry.key;
          bestLength = keyword.length;
        }
      }
    }
    return best;
  }

  /// Whole-word (or whole-phrase) containment, so "app" does not match
  /// "apple" and "gas" does not match "gasolina".
  static bool _containsWord(String haystack, String needle) {
    var from = 0;
    while (true) {
      final index = haystack.indexOf(needle, from);
      if (index == -1) return false;
      final before = index == 0 ? ' ' : haystack[index - 1];
      final afterIndex = index + needle.length;
      final after = afterIndex >= haystack.length ? ' ' : haystack[afterIndex];
      if (!_isWordChar(before) && !_isWordChar(after)) return true;
      from = index + 1;
    }
  }

  static bool _isWordChar(String char) =>
      RegExp(r'[a-z0-9]').hasMatch(char);
}
