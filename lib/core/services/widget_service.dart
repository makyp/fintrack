import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../utils/currency_formatter.dart';

class WidgetService {
  static const _widgetName = 'FimakypWidgetProvider';

  static Future<void> update(String userId) async {
    if (kIsWeb) return;
    try {

      final db = FirebaseFirestore.instance;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snap = await db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      double expenses = 0;
      double income = 0;
      final categoryTotals = <String, double>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = data['type'] as String? ?? '';
        final category = data['category'] as String? ?? '';

        if (type == 'expense') {
          expenses += amount;
          categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
        } else if (type == 'income') {
          income += amount;
        }
      }

      // Find top expense category
      String topCat = 'Sin movimientos hoy';
      if (categoryTotals.isNotEmpty) {
        final top = categoryTotals.entries
            .reduce((a, b) => a.value >= b.value ? a : b);
        topCat = 'Mayor gasto: ${_categoryLabel(top.key)} '
            '(${CurrencyFormatter.format(top.value)})';
      }

      final dateStr =
          DateFormat('d MMM', 'es').format(now);

      await Future.wait([
        HomeWidget.saveWidgetData('widget_expenses',
            CurrencyFormatter.format(expenses)),
        HomeWidget.saveWidgetData('widget_income',
            CurrencyFormatter.format(income)),
        HomeWidget.saveWidgetData('widget_date', dateStr),
        HomeWidget.saveWidgetData('widget_top_category', topCat),
      ]);

      await HomeWidget.updateWidget(
        androidName: _widgetName,
        qualifiedAndroidName: 'com.example.fintrack.$_widgetName',
      );
    } catch (_) {
      // Widget update is best-effort; never crash the app
    }
  }

  static String _categoryLabel(String key) {
    const labels = {
      'food': 'Alimentación',
      'transport': 'Transporte',
      'entertainment': 'Entretenimiento',
      'health': 'Salud',
      'education': 'Educación',
      'home': 'Hogar',
      'clothing': 'Ropa',
      'shopping': 'Compras',
      'technology': 'Tecnología',
      'services': 'Servicios',
      'cleaning': 'Aseo',
      'other': 'Otro',
    };
    return labels[key] ?? key;
  }
}
