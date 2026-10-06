import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app({required bool touch, MochiDefaults? defaults, required Widget child}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    lightTheme: defaults == null ? MochiTheme.light : MochiTheme.light.copyWith(defaults: defaults),
    home: Center(child: child),
  );

  ShapeDecoration cardDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(of: find.byType(MochiCard), matching: find.byType(DecoratedBox)),
      )
      .map((b) => b.decoration)
      .whereType<ShapeDecoration>()
      .first;

  Widget card({bool selected = false}) => app(
    touch: true,
    child: MochiCard(selected: selected, child: const SizedBox(width: 20, height: 20)),
  );

  testWidgets("layering follows touch unless the theme says otherwise", (tester) async {
    late MochiTheme seen;
    Widget probe() => Builder(
      builder: (context) {
        seen = context.theme;
        return const SizedBox();
      },
    );
    await tester.pumpWidget(app(touch: false, child: probe()));
    expect(seen.layering, MochiLayering.outlined);
    await tester.pumpWidget(app(touch: true, child: probe()));
    await tester.pumpAndSettle();
    expect(seen.layering, MochiLayering.raised);
    await tester.pumpWidget(
      app(
        touch: true,
        defaults: const MochiDefaults(layering: MochiLayering.outlined),
        child: probe(),
      ),
    );
    await tester.pumpAndSettle();
    expect(seen.layering, MochiLayering.outlined);
  });

  testWidgets("a raised card is lighter than the page, loses its line and casts a deeper shadow", (
    tester,
  ) async {
    await tester.pumpWidget(card());
    await tester.pumpAndSettle();
    final raised = cardDecoration(tester);
    expect(raised.color, MochiColors.light.overlay);
    expect(raised.color!.computeLuminance(), greaterThan(MochiColors.light.background.computeLuminance()));
    expect((raised.shape as RoundedSuperellipseBorder).side.color.a, 0);

    await tester.pumpWidget(
      app(
        touch: true,
        defaults: const MochiDefaults(layering: MochiLayering.outlined),
        child: const MochiCard(child: SizedBox(width: 20, height: 20)),
      ),
    );
    await tester.pumpAndSettle();
    final flat = cardDecoration(tester);
    expect(raised.shadows!.first.blurRadius, greaterThan(flat.shadows!.first.blurRadius));
  });

  testWidgets("a raised card that is chosen is tinted, with no line", (tester) async {
    await tester.pumpWidget(card(selected: true));
    await tester.pumpAndSettle();
    final d = cardDecoration(tester);
    expect((d.shape as RoundedSuperellipseBorder).side.color.a, 0);
    final c = MochiColors.light;
    expect(d.color, isNot(c.softOn(c.primary, c.overlay)));
    // Stronger than a soft fill, still dark enough text on it to read.
    expect(d.color!.computeLuminance(), lessThan(c.softOn(c.primary, c.overlay).computeLuminance()));
  });

  testWidgets("a soft card is rounder, casts no shadow, and is chosen without a line", (tester) async {
    Widget soft({required bool touch, bool selected = false}) => app(
      touch: touch,
      child: MochiCard(
        appearance: .soft,
        intent: MochiIntent.info,
        selected: selected,
        child: const SizedBox(width: 20, height: 20),
      ),
    );
    RoundedSuperellipseBorder shape() => cardDecoration(tester).shape as RoundedSuperellipseBorder;

    await tester.pumpWidget(soft(touch: false));
    await tester.pumpAndSettle();
    final flatRadius = shape().borderRadius;

    await tester.pumpWidget(soft(touch: true));
    await tester.pumpAndSettle();
    expect(shape().borderRadius, isNot(flatRadius));
    expect(cardDecoration(tester).shadows, isNull);
    expect(shape().side.color.a, 0);

    await tester.pumpWidget(soft(touch: true, selected: true));
    await tester.pumpAndSettle();
    expect(shape().side.color.a, 0);
  });

  testWidgets("a raised card in the dark theme is lit by a pale halo, and in the light one is not", (
    tester,
  ) async {
    Widget themed(MochiThemeMode mode) => MochiApp(
      themeMode: mode,
      touch: true,
      home: const Center(child: MochiCard(child: SizedBox(width: 20, height: 20))),
    );
    bool hasHalo() => cardDecoration(tester).shadows!.any((s) => s.color.computeLuminance() > 0.9);

    await tester.pumpWidget(themed(MochiThemeMode.dark));
    await tester.pumpAndSettle();
    expect(hasHalo(), isTrue);

    await tester.pumpWidget(themed(MochiThemeMode.light));
    await tester.pumpAndSettle();
    expect(hasHalo(), isFalse);
  });
}
