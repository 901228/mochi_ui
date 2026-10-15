import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Center(child: child),
  );

  MochiAnimatedNumber number(double? value) =>
      MochiAnimatedNumber(value: value, format: (v) => v.toStringAsFixed(2));

  testWidgets("counts from initial to the value, and ends on the value", (tester) async {
    await tester.pumpWidget(app(number(12.5)));
    expect(find.text("0.00"), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    final midway = (tester.widget(find.byType(Text).first) as Text).data;
    expect(midway, isNot("0.00"));
    expect(midway, isNot("12.50"));

    await tester.pumpAndSettle();
    expect(find.text("12.50"), findsOneWidget);
  });

  testWidgets("a change eases on from the number on screen, not from zero", (tester) async {
    await tester.pumpWidget(app(number(10)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(number(20)));
    await tester.pump(const Duration(milliseconds: 300));
    final midway = double.parse((tester.widget(find.byType(Text).first) as Text).data!);
    expect(midway, greaterThan(10));
    expect(midway, lessThan(20));

    await tester.pumpAndSettle();
    expect(find.text("20.00"), findsOneWidget);
  });

  testWidgets("null shows the fallback, and a number after it counts up from zero", (tester) async {
    await tester.pumpWidget(app(number(null)));
    await tester.pumpAndSettle();
    expect(find.text("--"), findsOneWidget);

    await tester.pumpWidget(app(number(3)));
    await tester.pumpAndSettle();
    expect(find.text("--"), findsNothing);
    expect(find.text("3.00"), findsOneWidget);
  });

  testWidgets("a non-finite value shows the fallback", (tester) async {
    await tester.pumpWidget(app(number(double.infinity)));
    await tester.pumpAndSettle();
    expect(find.text("--"), findsOneWidget);
  });

  testWidgets("a screen reader hears the final value, not the count", (tester) async {
    await tester.pumpWidget(app(number(12.5)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel("12.50"), findsOneWidget);
  });

  testWidgets("one fallback cross-fades into another", (tester) async {
    Widget fallback(String text) =>
        app(MochiAnimatedNumber(value: null, fallback: text, format: (v) => v.toString()));
    await tester.pumpWidget(fallback("--"));
    await tester.pumpAndSettle();

    await tester.pumpWidget(fallback("DNF"));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("--"), findsOneWidget);
    expect(find.text("DNF"), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text("--"), findsNothing);
  });
}
