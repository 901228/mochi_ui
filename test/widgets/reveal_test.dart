import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      touch: false,
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 300, child: child),
      ),
    ),
  );

  const body = SizedBox(height: 100, child: Text("Body"));
  double height(WidgetTester tester) => tester.getSize(find.byType(MochiReveal)).height;

  testWidgets("follows expanded, growing over time rather than jumping", (tester) async {
    await tester.pumpWidget(app(const MochiReveal(expanded: false, child: body)));
    expect(find.text("Body"), findsNothing);
    expect(height(tester), 0);

    await tester.pumpWidget(app(const MochiReveal(expanded: true, child: body)));
    await tester.pump(const Duration(milliseconds: 60));
    expect(height(tester), inExclusiveRange(0, 100));

    await tester.pumpAndSettle();
    expect(height(tester), 100);

    await tester.pumpWidget(app(const MochiReveal(expanded: false, child: body)));
    await tester.pumpAndSettle();
    expect(find.text("Body"), findsNothing);
  });

  testWidgets("jumps under disableAnimations", (tester) async {
    await tester.pumpWidget(app(const MochiReveal(expanded: false, child: body), disableAnimations: true));
    await tester.pumpWidget(app(const MochiReveal(expanded: true, child: body), disableAnimations: true));
    await tester.pump();
    expect(height(tester), 100);
  });

  testWidgets("maintainState keeps a hidden child's state, and it can't be tabbed into", (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Widget reveal(bool expanded) => app(
      MochiReveal(
        expanded: expanded,
        maintainState: true,
        child: MochiTextField(controller: controller),
      ),
    );

    await tester.pumpWidget(reveal(true));
    final state = tester.state(find.byType(EditableText));
    await tester.pumpWidget(reveal(false));
    await tester.pumpAndSettle();

    expect(find.byType(EditableText, skipOffstage: false), findsOneWidget);
    expect(tester.state(find.byType(EditableText, skipOffstage: false)), same(state));
    expect(
      find.descendant(
        of: find.byType(MochiReveal),
        matching: find.byWidgetPredicate((w) => w is ExcludeFocus && w.excluding, skipOffstage: false),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}
