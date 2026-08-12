import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/core/widgets/expandable_text.dart';

void main() {
  /// Wraps the widget in a box of a known width so overflow is deterministic.
  Widget host(String text, double width) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ExpandableText(
              text: text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  const long =
      'Exito poblado: Arroz diana, Leche colanta, Pan bimbo, Aceite girasol';

  testWidgets('no eye button when the text fits on one line', (tester) async {
    await tester.pumpWidget(host('Almuerzo', 300));

    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(find.text('Almuerzo'), findsOneWidget);
  });

  testWidgets('shows the eye when the text overflows', (tester) async {
    await tester.pumpWidget(host(long, 150));

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('tapping the eye unfolds the full text', (tester) async {
    await tester.pumpWidget(host(long, 150));

    Text renderedText() => tester.widget<Text>(find.text(long));
    expect(renderedText().maxLines, 1);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    // Unfolded: no line cap, and the icon offers to fold it back.
    expect(renderedText().maxLines, isNull);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('collapses again when the row is recycled with new text',
      (tester) async {
    await tester.pumpWidget(host(long, 150));
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    const other = 'Otra compra larga con muchos productos adentro del recibo';
    await tester.pumpWidget(host(other, 150));
    await tester.pump();

    expect(tester.widget<Text>(find.text(other)).maxLines, 1);
  });
}
