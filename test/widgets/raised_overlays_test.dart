import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {required bool touch, MochiThemeMode mode = MochiThemeMode.light}) => MochiApp(
    themeMode: mode,
    touch: touch,
    home: Center(child: child),
  );

  ShapeDecoration surface(WidgetTester tester, Finder within) => tester
      .widgetList<Widget>(find.descendant(of: within, matching: find.byWidgetPredicate((_) => true)))
      .map((w) => w is DecoratedBox ? w.decoration : (w is Container ? w.decoration : null))
      .whereType<ShapeDecoration>()
      .first;

  double lineAlpha(ShapeDecoration d) => (d.shape as RoundedSuperellipseBorder).side.color.a;

  final surfaces = <String, (Widget Function(), Finder)>{
    "dialog": (() => const MochiDialog(title: Text("T"), body: Text("B")), find.byType(MochiDialog)),
    "sheet": (() => const MochiSheet(title: Text("T"), child: Text("B")), find.byType(MochiSheet)),
    "popover": (() => const MochiPopoverSurface(child: Text("B")), find.byType(MochiPopoverSurface)),
    "toast": (() => const MochiToast(title: Text("T")), find.byType(MochiToast)),
  };

  for (final MapEntry(key: key, value: (value, within)) in surfaces.entries) {
    testWidgets("a raised $key has no line, and keeps its line when outlined", (tester) async {
      await tester.pumpWidget(app(value(), touch: false));
      await tester.pumpAndSettle();
      final flat = surface(tester, within);
      expect(lineAlpha(flat), 1);

      await tester.pumpWidget(app(value(), touch: true));
      await tester.pumpAndSettle();
      expect(lineAlpha(surface(tester, within)), 0);
    });

    testWidgets("a $key is lit by a halo in the dark theme only when raised", (tester) async {
      bool halo() => surface(tester, within).shadows!.any((s) => s.color.computeLuminance() > 0.9);

      await tester.pumpWidget(app(value(), touch: true, mode: MochiThemeMode.dark));
      await tester.pumpAndSettle();
      expect(halo(), isTrue);

      await tester.pumpWidget(app(value(), touch: false, mode: MochiThemeMode.dark));
      await tester.pumpAndSettle();
      expect(halo(), isFalse);
    });
  }

  testWidgets("a raised toast with an intent keeps it on its edge", (tester) async {
    await tester.pumpWidget(app(const MochiToast(title: Text("T"), intent: MochiIntent.danger), touch: true));
    await tester.pumpAndSettle();
    expect(
      (surface(tester, find.byType(MochiToast)).shape as RoundedSuperellipseBorder).side.color,
      MochiColors.light.danger.base,
    );
  });
}
