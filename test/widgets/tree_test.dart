import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 300, child: child),
    ),
  );

  const nodes = [
    MochiTreeNode(
      value: "sessions",
      label: Text("Sessions"),
      children: [
        MochiTreeNode(
          value: "3x3",
          label: Text("3x3"),
          children: [
            MochiTreeNode(value: "main", label: Text("main")),
            MochiTreeNode(value: "oh", label: Text("OH")),
          ],
        ),
        MochiTreeNode(value: "mega", label: Text("Megaminx")),
      ],
    ),
    MochiTreeNode(value: "archive", label: Text("Archive")),
  ];

  Widget tree({
    Set<String> open = const {},
    String? selected,
    ValueChanged<String>? onSelected,
    ValueChanged<Set<String>>? onExpandedChanged,
    double indent = 16,
  }) => app(
    MochiTree<String>(
      // A fresh tree per configuration: a managed control's `initial` is read once, as its name says.
      key: ValueKey(open.join()),
      nodes: nodes,
      expanded: .managed(initial: open, onChanged: onExpandedChanged),
      selected: selected,
      onSelected: onSelected,
      indent: indent,
    ),
  );

  testWidgets("only the open branches are drawn", (tester) async {
    await tester.pumpWidget(tree());
    await tester.pumpAndSettle();
    expect(find.text("Sessions"), findsOneWidget);
    expect(find.text("Archive"), findsOneWidget);
    expect(find.text("3x3"), findsNothing);

    await tester.pumpWidget(tree(open: {"sessions"}));
    await tester.pumpAndSettle();
    expect(find.text("3x3"), findsOneWidget);
    expect(find.text("main"), findsNothing, reason: "its own branch is still shut");
  });

  testWidgets("the chevron opens a node, and the row does too", (tester) async {
    final opened = <Set<String>>[];
    await tester.pumpWidget(tree(onExpandedChanged: opened.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MochiTappable).first);
    await tester.pumpAndSettle();
    expect(find.text("3x3"), findsOneWidget);
    expect(opened, [
      {"sessions"},
    ]);

    await tester.tap(find.text("Sessions"));
    await tester.pumpAndSettle();
    expect(find.text("3x3"), findsNothing);
    expect(opened, [
      {"sessions"},
      <String>{},
    ]);
  });

  testWidgets("pressing a row reports it", (tester) async {
    final chosen = <String>[];
    await tester.pumpWidget(tree(open: {"sessions"}, onSelected: chosen.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Megaminx"));
    expect(chosen, ["mega"]);
  });

  testWidgets("the chosen row is tinted", (tester) async {
    await tester.pumpWidget(tree(open: {"sessions"}, selected: "mega", onSelected: (_) {}));
    await tester.pumpAndSettle();

    Color fillOf(String label) =>
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
    expect(
      fillOf("Megaminx"),
      MochiColors.light.softOn(MochiColors.light.primary, MochiColors.light.surface),
    );
    expect(fillOf("Sessions").a, 0, reason: "an unchosen row has no fill of its own");
  });

  testWidgets("each level is indented, and children sit under their parent", (tester) async {
    await tester.pumpWidget(tree(open: {"sessions", "3x3"}, indent: 20));
    await tester.pumpAndSettle();

    final root = tester.getTopLeft(find.text("Sessions")).dx;
    final child = tester.getTopLeft(find.text("3x3")).dx;
    final grandchild = tester.getTopLeft(find.text("main")).dx;
    expect(child - root, 20);
    expect(grandchild - child, 20);
  });

  testWidgets("the arrows walk the rows that are showing", (tester) async {
    await tester.pumpWidget(tree(open: {"sessions"}, onSelected: (_) {}));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusedLabel(tester), "Sessions");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focusedLabel(tester), "3x3");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focusedLabel(tester), "Sessions");

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(focusedLabel(tester), "Archive");

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(focusedLabel(tester), "Sessions");
  });

  testWidgets("right opens a node then steps into it; left closes it then steps back out", (tester) async {
    await tester.pumpWidget(tree(onSelected: (_) {}));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusedLabel(tester), "Sessions");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text("3x3"), findsOneWidget, reason: "opened, not stepped into");
    expect(focusedLabel(tester), "Sessions");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel(tester), "3x3", reason: "already open, so it steps in");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(focusedLabel(tester), "Sessions", reason: "a shut node hands back to its parent");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text("3x3"), findsNothing, reason: "an open node closes");
  });

  testWidgets("a branch grows open and folds shut, rather than appearing at once", (tester) async {
    await tester.pumpWidget(tree());
    await tester.pumpAndSettle();
    double height() => tester.getSize(find.byType(MochiTree<String>)).height;
    final shut = height();

    await tester.tap(find.text("Sessions"));
    await tester.pumpAndSettle();
    final open = height();
    expect(open, greaterThan(shut));

    await tester.tap(find.text("Sessions"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(height(), allOf(greaterThan(shut), lessThan(open)), reason: "halfway shut");
    // Still drawn while it folds, but no longer somewhere the keyboard can go.
    expect(find.text("3x3"), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text("3x3"),
        matching: find.byWidgetPredicate((w) => w is ExcludeFocus && w.excluding),
      ),
      findsWidgets,
    );

    await tester.pumpAndSettle();
    expect(height(), shut);
    expect(find.text("3x3"), findsNothing);
  });

  testWidgets("handed back from the app, it keeps the branches the app left open", (tester) async {
    await tester.pumpWidget(
      app(
        MochiTree<String>(
          nodes: nodes,
          expanded: .lifted(value: const {"sessions"}, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpWidget(app(const MochiTree<String>(nodes: nodes)));
    await tester.pumpAndSettle();
    expect(find.text("3x3"), findsOneWidget);
  });

  testWidgets("a controlled tree only reports, and follows what it is given", (tester) async {
    final asked = <Set<String>>[];
    await tester.pumpWidget(
      app(
        MochiTree<String>(
          nodes: nodes,
          expanded: .lifted(value: const {}, onChanged: asked.add),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Sessions"));
    await tester.pumpAndSettle();
    expect(asked, [
      {"sessions"},
    ]);
    expect(find.text("3x3"), findsNothing, reason: "the app owns it and hasn't said yes");
  });
}

/// The label of the row the keyboard is on, found through the focus node each row was given.
String? focusedLabel(WidgetTester tester) {
  for (final element in find.byType(MochiTappable).evaluate()) {
    final tappable = element.widget as MochiTappable;
    if (tappable.focusNode?.hasFocus ?? false) {
      return tester
          .widgetList<Text>(find.descendant(of: find.byWidget(tappable), matching: find.byType(Text)))
          .firstOrNull
          ?.data;
    }
  }

  return null;
}
