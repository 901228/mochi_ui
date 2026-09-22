import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

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
  }) => app(
    MochiBottomNav<String>(
      value: value,
      onChanged: onChanged,
      showLabels: showLabels,
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

    Color pillOf(String label) =>
        (tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.ancestor(of: find.text(label), matching: find.byType(MochiTappable)),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as ShapeDecoration)
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
}
