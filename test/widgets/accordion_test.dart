import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 320, child: child),
    ),
  );

  List<MochiAccordionItem> items({bool disableThird = false}) => [
    const MochiAccordionItem(title: Text("Inspection"), child: Text("Count down first.")),
    const MochiAccordionItem(title: Text("Display"), child: Text("What the timer shows.")),
    MochiAccordionItem(
      title: const Text("Advanced"),
      enabled: !disableThird,
      child: const Text("Here be dragons."),
    ),
  ];

  Widget accordion({
    bool multiple = false,
    Set<int> open = const {},
    ValueChanged<Set<int>>? onExpandedChanged,
    bool disableThird = false,
    bool divider = true,
  }) => app(
    MochiAccordion(
      multiple: multiple,
      expanded: .managed(initial: open, onChanged: onExpandedChanged),
      divider: divider,
      items: items(disableThird: disableThird),
    ),
  );

  testWidgets("a header opens its own row", (tester) async {
    await tester.pumpWidget(accordion());
    await tester.pumpAndSettle();
    expect(find.text("Count down first."), findsNothing);

    await tester.tap(find.text("Inspection"));
    await tester.pumpAndSettle();
    expect(find.text("Count down first."), findsOneWidget);

    await tester.tap(find.text("Inspection"));
    await tester.pumpAndSettle();
    expect(find.text("Count down first."), findsNothing);
  });

  testWidgets("one at a time by default: opening a row closes the last", (tester) async {
    await tester.pumpWidget(accordion(open: {0}));
    await tester.pumpAndSettle();
    expect(find.text("Count down first."), findsOneWidget);

    await tester.tap(find.text("Display"));
    await tester.pumpAndSettle();
    expect(find.text("What the timer shows."), findsOneWidget);
    expect(find.text("Count down first."), findsNothing);
  });

  testWidgets("multiple lets them stand together", (tester) async {
    await tester.pumpWidget(accordion(multiple: true, open: {0}));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Display"));
    await tester.pumpAndSettle();
    expect(find.text("Count down first."), findsOneWidget);
    expect(find.text("What the timer shows."), findsOneWidget);
  });

  testWidgets("spacing goes between the rows only, not above the first or below the last", (tester) async {
    Future<(double, double, double)> measure(double spacing) async {
      await tester.pumpWidget(
        app(MochiAccordion(spacing: spacing, expanded: const .managed(), items: items())),
      );
      await tester.pumpAndSettle();
      final all = tester.getRect(find.byType(MochiAccordion));
      Rect header(String t) =>
          tester.getRect(find.ancestor(of: find.text(t), matching: find.byType(MochiTappable)).first);
      final first = header("Inspection");
      final last = header("Advanced");
      // Each header carries its own padding, so what is left over is the accordion's margin.
      return (
        first.top - all.top,
        all.bottom - last.bottom,
        tester.getRect(find.byType(MochiDivider).first).top - first.bottom,
      );
    }

    final (topSmall, bottomSmall, gapSmall) = await measure(0);
    final (topBig, bottomBig, gapBig) = await measure(20);
    expect(topBig, topSmall, reason: "nothing added above the first row");
    expect(bottomBig, bottomSmall, reason: "nothing added below the last row");
    expect(gapBig - gapSmall, 10, reason: "half the spacing each side of a divider");
  });

  testWidgets("contentSpacing sets the gap between a header and its body", (tester) async {
    Future<double> gap(double contentSpacing) async {
      await tester.pumpWidget(
        app(
          MochiAccordion(
            contentSpacing: contentSpacing,
            expanded: const .managed(initial: {0}),
            items: items(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final header = tester.getRect(
        find.ancestor(of: find.text("Inspection"), matching: find.byType(MochiTappable)).first,
      );
      return tester.getRect(find.text("Count down first.")).top - header.bottom;
    }

    expect(await gap(16) - await gap(0), 16);
  });

  testWidgets("it reports the whole set", (tester) async {
    final seen = <Set<int>>[];
    await tester.pumpWidget(accordion(multiple: true, open: {0}, onExpandedChanged: seen.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Display"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Inspection"));
    await tester.pumpAndSettle();
    expect(seen, [
      {0, 1},
      {1},
    ]);
  });

  testWidgets("a controlled accordion only reports, and follows what it is given", (tester) async {
    final seen = <Set<int>>[];
    await tester.pumpWidget(
      app(
        MochiAccordion(
          expanded: .lifted(value: const {}, onChanged: seen.add),
          items: items(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Inspection"));
    await tester.pumpAndSettle();
    expect(seen, [
      {0},
    ]);
    expect(find.text("Count down first."), findsNothing, reason: "the app hasn't said yes");
  });

  testWidgets("a disabled row doesn't open", (tester) async {
    await tester.pumpWidget(accordion(disableThird: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Advanced"), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text("Here be dragons."), findsNothing);
  });

  testWidgets("lines between the rows, unless they are turned off", (tester) async {
    await tester.pumpWidget(accordion());
    await tester.pumpAndSettle();
    expect(find.byType(MochiDivider), findsNWidgets(2));

    await tester.pumpWidget(accordion(divider: false));
    await tester.pumpAndSettle();
    expect(find.byType(MochiDivider), findsNothing);
  });

  testWidgets("a heading reads as one: bigger and heavier than the answer under it", (tester) async {
    await tester.pumpWidget(accordion(open: {0}));
    await tester.pumpAndSettle();

    TextStyle styleOf(String text) => tester.widget<Text>(find.text(text)).style ?? const TextStyle();
    final title = DefaultTextStyle.of(tester.element(find.text("Inspection"))).style
        .merge(styleOf("Inspection"));
    final body = DefaultTextStyle.of(tester.element(find.text("Count down first."))).style
        .merge(styleOf("Count down first."));

    expect(title.fontWeight, FontWeight.w700);
    // The weight that counts for a variable font is the axis, not the enum beside it.
    expect(title.fontVariations, contains(const FontVariation("wght", 700)));
    expect(body.fontVariations, contains(const FontVariation("wght", 400)));
    expect(title.fontSize, greaterThan(body.fontSize!));
  });

  testWidgets("the header's fill stops short of the line between rows", (tester) async {
    await tester.pumpWidget(accordion());
    await tester.pumpAndSettle();

    final header = tester.getRect(
      find.ancestor(of: find.text("Display"), matching: find.byType(MochiTappable)).first,
    );
    final lines = tester.widgetList<MochiDivider>(find.byType(MochiDivider)).length;
    expect(lines, 2);

    final above = tester.getRect(find.byType(MochiDivider).first);
    expect(header.top, greaterThan(above.bottom), reason: "a gap, not a seam");
  });
}
