import '../../../core/utils/text_normalizer.dart';
import '../../categories/domain/category_registry.dart';
import 'entities/transaction.dart';

/// Keyword-based category suggestion, shared by the manual form, the voice
/// capture and the receipt OCR so the three routes always agree.
///
/// 100% local: no network, no paid API. Matching runs over accent-stripped
/// lowercase text, so "Café" and "cafe" behave the same.
///
/// Keys are default category ids. Categories the user created are matched by
/// their own name instead — there are no keywords to ship for those.
class CategoryMatcher {
  const CategoryMatcher._();

  static const keywords = <String, List<String>>{
    'food': [
      'almuerzo', 'comida', 'restaurante', 'cafe', 'pizza', 'burger',
      'sushi', 'desayuno', 'cena', 'mercado', 'supermercado', 'rappi', 'domicilio',
      'hamburguesa', 'pollo', 'sandwich', 'taco', 'ensalada', 'postre',
      'panaderia', 'helado', 'arepa', 'empanada', 'jugo', 'gaseosa',
    ],
    'transport': [
      'uber', 'taxi', 'bus', 'metro', 'transporte', 'gasolina', 'combustible',
      'parqueadero', 'estacionamiento', 'peaje', 'tren', 'avion', 'vuelo',
      'didi', 'indriver', 'cabify', 'pasaje', 'recarga civica', 'terpel',
    ],
    'entertainment': [
      'netflix', 'spotify', 'cine', 'pelicula', 'juego', 'concierto',
      'teatro', 'streaming', 'prime', 'disney', 'youtube', 'hbo', 'apple tv',
      'bar', 'discoteca', 'fiesta', 'cerveza', 'trago',
    ],
    'health': [
      'farmacia', 'medico', 'doctor', 'hospital', 'clinica',
      'medicina', 'gym', 'gimnasio', 'dentista', 'psicologo', 'droga',
      'eps', 'cruz verde', 'locatel', 'examen',
    ],
    'education': [
      'libro', 'curso', 'universidad', 'colegio', 'matricula',
      'udemy', 'coursera', 'tutoria', 'platzi', 'clase', 'semestre',
    ],
    'home': [
      'alquiler', 'arriendo', 'luz', 'agua', 'gas', 'internet', 'cable',
      'mantenimiento', 'reparacion', 'mueble', 'hogar', 'limpieza',
      'administracion', 'epm', 'servicios publicos',
    ],
    'clothing': [
      'ropa', 'zapatos', 'camisa', 'pantalon', 'vestido', 'moda',
      'tenis', 'zapatillas', 'chaqueta', 'abrigo', 'zara', 'koaj',
    ],
    'shopping': [
      'temu', 'shein', 'amazon', 'aliexpress', 'mercado libre', 'mercadolibre',
      'linio', 'falabella', 'exito', 'jumbo', 'compra', 'pedido',
      'olimpica', 'd1', 'ara', 'ktronix', 'alkosto',
    ],
    'technology': [
      'celular', 'laptop', 'computador', 'tablet', 'auriculares', 'teclado',
      'software', 'app', 'apple', 'samsung', 'mouse', 'cargador',
    ],
    'services': [
      'telefono', 'plan', 'seguro', 'servicio', 'suscripcion',
      'mensualidad', 'factura', 'claro', 'movistar', 'tigo', 'wom',
    ],
    'cleaning': [
      'aseo', 'jabon', 'detergente', 'shampoo', 'papel higienico',
      'crema dental', 'desodorante', 'peluqueria', 'lavanderia',
    ],
    'salary': [
      'salario', 'sueldo', 'nomina', 'quincena', 'pago mensual',
    ],
    'freelance': [
      'proyecto', 'freelance', 'consultoria', 'honorarios',
    ],
    'investment': [
      'dividendo', 'interes', 'rendimiento', 'acciones', 'crypto',
      'bitcoin', 'bolsa', 'fondo', 'cdt',
    ],
    'sale': [
      'venta', 'vendi', 'vendida', 'vendido',
    ],
    'gift': [
      'regalo', 'obsequio', 'me regalaron',
    ],
    'bonus': [
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

    // Only ever suggest something the user can actually pick: active, and
    // valid for the movement type.
    final candidates = type == null
        ? CategoryRegistry.active
        : CategoryRegistry.forType(type);
    final byId = {for (final c in candidates) c.id: c};

    TransactionCategory? best;
    var bestLength = 0;

    for (final entry in keywords.entries) {
      final category = byId[entry.key];
      if (category == null) continue;
      for (final keyword in entry.value) {
        if (keyword.length <= bestLength) continue;
        if (_containsWord(normalized, keyword)) {
          best = category;
          bestLength = keyword.length;
        }
      }
    }

    // A category the user created has no shipped keywords, so match it by its
    // own name: "gasté 40 mil en mascotas" should land on "Mascotas".
    for (final category in candidates) {
      if (category.isDefault) continue;
      final name = TextNormalizer.normalizeWords(category.label);
      if (name.length <= bestLength || name.length < 3) continue;
      if (_containsWord(normalized, name)) {
        best = category;
        bestLength = name.length;
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
