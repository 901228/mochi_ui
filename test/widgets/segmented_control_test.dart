import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {double width = 400}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Center(
      child: SizedBox(width: width, child: child),
    ),
  );

  const segments = [
    MochiSegment(value: "ao5", label: Text("ao5")),
    MochiSegment(value: "ao12", label: Text("ao12")),
    MochiSegment(value: "chart", label: Text("Chart")),
  ];

  Widget live(
    List<String> seen, {
    String start = "ao5",
    MochiSegmentedAppearance appearance = MochiSegmentedAppearance.segmented,
    bool expanded = true,
    List<MochiSegment<String>> children = segments,
  }) {
    var value = start;
    return StatefulBuilder(
      builder: (context, setState) => app(
        MochiSegmentedControl<String>(
          value: value,
          appearance: appearance,
          expanded: expanded,
          children: children,
          onChanged: (next) => setState(() {
            seen.add(next);
            value = next;
          }),
        ),
      ),
    );
  }

  Finder segmentOf(String label) => find.ancestor(of: find.text(label), matching: find.byType(MochiTappable));

  testWidgets("pressing a segment chooses it, and pressing it again changes nothing", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(live(seen));

    await tester.tap(find.text("Chart"));
    await tester.pumpAndSettle();
    expect(seen, ["chart"]);

    await tester.tap(find.text("Chart"));
    await tester.pump();
    expect(seen, ["chart"]);
  });

  testWidgets("segments share the width equally", (tester) async {
    await tester.pumpWidget(live([]));
    final widths = [
      for (final label in ["ao5", "ao12", "Chart"]) tester.getSize(segmentOf(label)).width,
    ];
    expect(widths[0], widths[1]);
    expect(widths[1], widths[2]);
  });

  testWidgets("the indicator slides to the chosen segment", (tester) async {
    await tester.pumpWidget(live([]));
    Rect indicator() => tester.getRect(find.byType(FractionallySizedBox));
    final first = indicator();
    expect(first.left, closeTo(tester.getRect(segmentOf("ao5")).left, 4));

    await tester.tap(find.text("Chart"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final midway = indicator();
    expect(midway.left, greaterThan(first.left));
    expect(midway.left, lessThan(tester.getRect(segmentOf("Chart")).left - 4), reason: "still travelling");

    await tester.pumpAndSettle();
    expect(indicator().left, closeTo(tester.getRect(segmentOf("Chart")).left, 4));
  });

  testWidgets("the keyboard: one tab stop, arrows move the choice and stop at the ends", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(live(seen));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(seen, ["ao12", "chart"]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(seen.last, "ao12");

    // The segments are not tab stops of their own.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<MochiTappable>(),
      isNull,
    );
  });

  testWidgets("a disabled segment can't be chosen, and the arrows walk past it", (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      live(
        seen,
        children: const [
          MochiSegment(value: "ao5", label: Text("ao5")),
          MochiSegment(value: "ao12", label: Text("ao12"), enabled: false),
          MochiSegment(value: "chart", label: Text("Chart")),
        ],
      ),
    );

    await tester.tap(find.text("ao12"), warnIfMissed: false);
    await tester.pump();
    expect(seen, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(seen, ["chart"]);
  });

  testWidgets("null onChanged disables the whole control", (tester) async {
    await tester.pumpWidget(
      app(const MochiSegmentedControl<String>(value: "ao5", onChanged: null, children: segments)),
    );
    await tester.tap(find.text("Chart"), warnIfMissed: false);
    await tester.pump();

    final opacities = tester
        .widgetList<Opacity>(
          find.descendant(of: find.byType(MochiSegmentedControl<String>), matching: find.byType(Opacity)),
        )
        .map((o) => o.opacity);
    expect(opacities, everyElement(0.4));
  });

  testWidgets("not expanded, it is as wide as its widest segment needs", (tester) async {
    // Loose constraints: with a width forced on it there is nothing to shrink out of.
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Center(
          child: SizedBox(
            width: 400,
            child: Align(
              alignment: Alignment.centerLeft,
              child: MochiSegmentedControl<String>(
                value: "ao5",
                expanded: false,
                onChanged: (_) {},
                children: segments,
              ),
            ),
          ),
        ),
      ),
    );
    final control = tester.getSize(find.byType(MochiSegmentedControl<String>));
    expect(control.width, lessThan(400));

    final widths = [
      for (final label in ["ao5", "ao12", "Chart"]) tester.getSize(segmentOf(label)).width,
    ];
    expect(widths[0], widths[1]);
    expect(widths[1], widths[2]);
  });

  testWidgets("underline has no track and draws a line under the chosen one", (tester) async {
    await tester.pumpWidget(live([], appearance: MochiSegmentedAppearance.underline));
    await tester.pumpAndSettle();

    final line = tester.getRect(
      find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(Container)),
    );
    final control = tester.getRect(find.byType(MochiSegmentedControl<String>));
    expect(line.height, 2);
    expect(line.bottom, closeTo(control.bottom, 0.01));
    expect(line.width, closeTo(control.width / 3, 0.01));
  });

  testWidgets("as tall as a button of the same size", (tester) async {
    for (final size in MochiSize.values) {
      await tester.pumpWidget(
        app(
          Row(
            children: [
              Expanded(
                child: MochiSegmentedControl<String>(
                  value: "ao5",
                  size: size,
                  onChanged: (_) {},
                  children: segments,
                ),
              ),
              MochiButton(size: size, onPress: () {}, child: const Text("Go")),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(MochiSegmentedControl<String>)).height,
        tester.getSize(find.byType(MochiButton)).height,
        reason: size.name,
      );
    }
  });
}
