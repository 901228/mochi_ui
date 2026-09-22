import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );

  List<MochiBreadcrumbItem> trail(List<String> pressed, {int steps = 3}) => [
    for (var i = 0; i < steps; i++)
      MochiBreadcrumbItem(
        label: Text("Step $i"),
        onPress: i == steps - 1 ? null : () => pressed.add("Step $i"),
      ),
  ];

  testWidgets("every step but the last is somewhere to go", (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(app(MochiBreadcrumb(items: trail(pressed))));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Step 0"));
    expect(pressed, ["Step 0"]);

    // The last one is plain text: no tappable wraps it.
    expect(find.ancestor(of: find.text("Step 2"), matching: find.byType(MochiTappable)), findsNothing);
  });

  testWidgets("a separator between the steps, pointing the way the text runs", (tester) async {
    await tester.pumpWidget(app(MochiBreadcrumb(items: trail([]))));
    await tester.pumpAndSettle();
    expect(find.byIcon(MochiIcons.standard.chevronRight), findsNWidgets(2));
  });

  testWidgets("a long trail folds its middle into a menu", (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(app(MochiBreadcrumb(items: trail(pressed, steps: 6), maxItems: 3)));
    await tester.pumpAndSettle();

    expect(find.text("Step 0"), findsOneWidget, reason: "where it started");
    expect(find.text("Step 4"), findsOneWidget);
    expect(find.text("Step 5"), findsOneWidget, reason: "where it is");
    expect(find.text("Step 2"), findsNothing, reason: "folded away");

    await tester.tap(find.byIcon(MochiIcons.standard.more), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(find.text("Step 1"), findsOneWidget);
    expect(find.text("Step 3"), findsOneWidget);

    await tester.tap(find.text("Step 3"), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(pressed, ["Step 3"]);
  });

  testWidgets("a trail that fits keeps all of its steps", (tester) async {
    await tester.pumpWidget(app(MochiBreadcrumb(items: trail([], steps: 3), maxItems: 3)));
    await tester.pumpAndSettle();
    expect(find.byIcon(MochiIcons.standard.more), findsNothing);
    expect(find.text("Step 1"), findsOneWidget);
  });

  testWidgets("the place you are is marked as the heading", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(MochiBreadcrumb(items: trail([]))));
    await tester.pumpAndSettle();

    expect(tester.getSemantics(find.text("Step 2")).flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets("right-to-left turns the separator round", (tester) async {
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topRight,
            child: MochiBreadcrumb(items: trail([])),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(MochiIcons.standard.chevronLeft), findsNWidgets(2));
  });
}
