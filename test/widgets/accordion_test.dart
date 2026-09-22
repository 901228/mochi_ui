import "package:flutter/widgets.dart";
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
      initiallyExpanded: open,
      onExpandedChanged: onExpandedChanged,
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
      app(MochiAccordion(expanded: const {}, onExpandedChanged: seen.add, items: items())),
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
}
