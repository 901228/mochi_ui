import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

import "../support/surface.dart";

void main() {
  Widget app(Widget child, {EdgeInsets padding = EdgeInsets.zero, bool touch = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: MediaQuery(
      data: MediaQueryData(padding: padding),
      child: Column(
        children: [
          const Expanded(child: SizedBox.shrink()),
          child,
        ],
      ),
    ),
  );

  List<MochiBottomNavItem<String>> items({bool disableSettings = false}) => [
    MochiBottomNavItem(value: "timer", icon: Icon(MochiIcons.standard.check), label: const Text("Timer")),
    MochiBottomNavItem(
      value: "stats",
      icon: Icon(MochiIcons.standard.info),
      label: const Text("Statistics"),
      badge: const MochiBadge(child: Text("3")),
    ),
    MochiBottomNavItem(
      value: "settings",
      icon: Icon(MochiIcons.standard.close),
      label: const Text("Settings"),
      enabled: !disableSettings,
    ),
  ];

  Widget nav({
    String value = "timer",
    ValueChanged<String>? onChanged,
    bool showLabels = true,
    bool disableSettings = false,
    EdgeInsets padding = EdgeInsets.zero,
    bool touch = false,
    MochiBottomNavVariant? variant,
  }) => app(
    MochiBottomNav<String>(
      value: value,
      onChanged: onChanged,
      showLabels: showLabels,
      variant: variant,
      items: items(disableSettings: disableSettings),
    ),
    padding: padding,
    touch: touch,
  );

  testWidgets("pressing a destination reports it; the one it is on does nothing", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(nav(onChanged: seen.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Statistics"));
    expect(seen, ["stats"]);

    await tester.tap(find.text("Timer"), warnIfMissed: false);
    expect(seen, ["stats"]);
  });

  testWidgets("destinations share the width equally", (tester) async {
    await tester.pumpWidget(nav(onChanged: (_) {}));
    await tester.pumpAndSettle();
    final widths = [
      for (final label in ["Timer", "Statistics", "Settings"])
        tester.getSize(find.ancestor(of: find.text(label), matching: find.byType(MochiTappable))).width,
    ];
    expect(widths[0], widths[1]);
    expect(widths[1], widths[2]);
  });

  testWidgets("the chosen one is tinted and the others are muted", (tester) async {
    await tester.pumpWidget(nav(onChanged: (_) {}));
    await tester.pumpAndSettle();

    Color pillOf(String label) => tester
        .widgetList<Container>(
          find.descendant(
            of: find.ancestor(of: find.text(label), matching: find.byType(MochiTappable)),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<ShapeDecoration>()
        .first
        .color!;
    expect(pillOf("Timer"), MochiColors.light.softOn(MochiColors.light.primary, MochiColors.light.surface));
    expect(pillOf("Statistics"), MochiColors.light.surface);
  });

  testWidgets("without labels, only the chosen one says what it is", (tester) async {
    await tester.pumpWidget(nav(onChanged: (_) {}, showLabels: false));
    await tester.pumpAndSettle();
    expect(find.text("Timer"), findsOneWidget);
    expect(find.text("Statistics"), findsNothing);
    expect(find.text("Settings"), findsNothing);
  });

  testWidgets("a badge rides the icon", (tester) async {
    await tester.pumpWidget(nav(onChanged: (_) {}));
    await tester.pumpAndSettle();
    final badge = tester.getRect(find.byType(MochiBadge));
    final icon = tester.getRect(find.byIcon(MochiIcons.standard.info));
    expect(badge.center.dx, greaterThan(icon.center.dx));
    expect(badge.center.dy, lessThan(icon.center.dy));
  });

  testWidgets("a disabled destination can't be pressed, and neither can a disabled bar", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(nav(onChanged: seen.add, disableSettings: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Settings"), warnIfMissed: false);
    expect(seen, isEmpty);

    await tester.pumpWidget(nav(onChanged: null));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Statistics"), warnIfMissed: false);
    expect(seen, isEmpty);
  });

  testWidgets("it clears the system's bottom inset itself", (tester) async {
    await tester.pumpWidget(nav(onChanged: (_) {}));
    await tester.pumpAndSettle();
    final plain = tester.getSize(find.byType(MochiBottomNav<String>)).height;

    await tester.pumpWidget(nav(onChanged: (_) {}, padding: const EdgeInsets.only(bottom: 34)));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiBottomNav<String>)).height, plain + 34);
  });

  testWidgets("taller on touch", (tester) async {
    await tester.pumpWidget(nav(onChanged: (_) {}));
    await tester.pumpAndSettle();
    final desktop = tester.getSize(find.byType(MochiBottomNav<String>)).height;

    await tester.pumpWidget(nav(onChanged: (_) {}, touch: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MochiBottomNav<String>)).height, greaterThan(desktop));
  });

  group("raised", () {
    BoxDecoration barDecoration(WidgetTester tester) =>
        tester
                .widget<Container>(
                  find
                      .descendant(of: find.byType(MochiBottomNav<String>), matching: find.byType(Container))
                      .first,
                )
                .decoration!
            as BoxDecoration;

    testWidgets("docked, has no line along its top, is the overlay colour, and is lit from below", (
      tester,
    ) async {
      await tester.pumpWidget(nav(touch: true, variant: MochiBottomNavVariant.docked));
      await tester.pumpAndSettle();
      final d = barDecoration(tester);
      expect(d.border, isNull);
      expect(d.color, MochiColors.light.overlay);
      // The shadow is cast upwards: it is a bar at the bottom edge.
      expect(d.boxShadow!.first.offset.dy, lessThan(0));
    });

    testWidgets("outlined keeps its line and its surface colour", (tester) async {
      await tester.pumpWidget(nav());
      await tester.pumpAndSettle();
      final d = barDecoration(tester);
      expect(d.border, isNotNull);
      expect(d.color, MochiColors.light.surface);
      expect(d.boxShadow, isNull);
    });
  });

  testWidgets("destinations stand a little apart, and a docked block is not a pill", (tester) async {
    await tester.pumpWidget(nav(onChanged: (_) {}));
    await tester.pumpAndSettle();
    final g = MochiTheme.light.geometry;
    Rect cell(String label) =>
        tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(MochiTappable)));
    expect(cell("Statistics").left - cell("Timer").right, g.space.xs2);

    final block = tester
        .widgetList<Container>(
          find.descendant(
            of: find.ancestor(of: find.text("Timer"), matching: find.byType(MochiTappable)),
            matching: find.byType(Container),
          ),
        )
        .where((c) => c.decoration is ShapeDecoration)
        .first;
    final radius = ((block.decoration! as ShapeDecoration).shape as RoundedSuperellipseBorder).borderRadius;
    final height = tester.getSize(find.byWidget(block)).height;
    expect((radius as BorderRadius).topLeft.x, lessThan(height / 2));
  });

  group("floating", () {
    ShapeDecoration barShape(WidgetTester tester) => surfaceOf(tester, find.byType(MochiBottomNav<String>));

    Finder barBox() =>
        find.descendant(of: find.byType(MochiBottomNav<String>), matching: find.byType(DecoratedBox)).first;

    testWidgets("is what a raised theme gets: clear of the edges, rounded, no line", (tester) async {
      await tester.pumpWidget(nav(touch: true, onChanged: (_) {}));
      await tester.pumpAndSettle();

      final bar = tester.getRect(barBox());
      final page = tester.getRect(find.byType(MochiBottomNav<String>));
      final g = MochiTheme.light.geometry;
      expect(bar.left, greaterThanOrEqualTo(page.left + g.space.md));
      expect(bar.center.dx, page.center.dx);
      expect(bar.bottom, page.bottom - g.space.md);

      final shape = barShape(tester).shape as RoundedSuperellipseBorder;
      expect(shape.borderRadius, g.radius.xl);
      expect(shape.side.color.a, 0);
      expect(shadowsOf(tester, find.byType(MochiBottomNav<String>)), isNotEmpty);
    });

    testWidgets("the chosen destination is a block inside it, its corner following the bar's", (
      tester,
    ) async {
      await tester.pumpWidget(nav(touch: true, onChanged: (_) {}));
      await tester.pumpAndSettle();
      final g = MochiTheme.light.geometry;

      final cell = tester
          .widgetList<Container>(
            find.descendant(
              of: find.ancestor(of: find.text("Timer"), matching: find.byType(MochiTappable)),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<ShapeDecoration>()
          .first;
      expect((cell.shape as RoundedSuperellipseBorder).borderRadius, g.radius.lg);

      // In by the difference between the two corners.
      final bar = tester.getRect(barBox());
      final timer = tester.getRect(
        find.ancestor(of: find.text("Timer"), matching: find.byType(MochiTappable)),
      );
      expect(timer.left - bar.left, g.radius.xl.topLeft.x - g.radius.lg.topLeft.x);
    });

    testWidgets("stands over the home indicator rather than on it", (tester) async {
      await tester.pumpWidget(nav(touch: true, padding: const EdgeInsets.only(bottom: 34)));
      await tester.pumpAndSettle();
      final bar = tester.getRect(barBox());
      final page = tester.getRect(find.byType(MochiBottomNav<String>));
      expect(bar.bottom, page.bottom - 34 - MochiTheme.light.geometry.space.xs);
    });

    testWidgets("keeps to a phone's width on a wide screen", (tester) async {
      await tester.pumpWidget(nav(touch: true));
      await tester.pumpAndSettle();
      expect(tester.getSize(barBox()).width, MochiBottomNav.maxFloatingWidth);
    });

    testWidgets("can be asked for on an outlined theme, and docked on a raised one", (tester) async {
      await tester.pumpWidget(nav(variant: MochiBottomNavVariant.floating));
      await tester.pumpAndSettle();
      expect(shadowsOf(tester, find.byType(MochiBottomNav<String>)), isNull);
      expect((barShape(tester).shape as RoundedSuperellipseBorder).side.color, MochiColors.light.border);

      await tester.pumpWidget(nav(touch: true, variant: MochiBottomNavVariant.docked));
      await tester.pumpAndSettle();
      // Docked: the destinations run from the screen's very edge.
      expect(
        tester.getRect(find.ancestor(of: find.text("Timer"), matching: find.byType(MochiTappable))).left,
        0,
      );
    });
  });
}
