import "package:flutter/services.dart";
import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {Size size = const Size(600, 400)}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: size.width, height: size.height, child: child),
    ),
  );

  Widget pane(String name) => ColoredBox(
    color: const Color(0xFF000000),
    child: Align(alignment: Alignment.topLeft, child: Text(name)),
  );

  double widthOf(WidgetTester tester, String name) =>
      tester.getSize(find.ancestor(of: find.text(name), matching: find.byType(ColoredBox)).first).width;

  double heightOf(WidgetTester tester, String name) =>
      tester.getSize(find.ancestor(of: find.text(name), matching: find.byType(ColoredBox)).first).height;

  Future<void> dragHandle(WidgetTester tester, Offset by, {int index = 0}) async {
    final handle = find
        .descendant(of: find.byType(MochiResizable), matching: find.byType(MochiFocusRing))
        .at(index);
    final gesture = await tester.startGesture(tester.getCenter(handle), kind: PointerDeviceKind.mouse);
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(by / 5);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets("panes start at the fractions they asked for", (tester) async {
    await tester.pumpWidget(
      app(
        MochiResizable(
          panes: [
            MochiResizablePane(initialFraction: 0.25, child: pane("left")),
            MochiResizablePane(child: pane("right")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 600 wide less the 8 the handle takes.
    expect(widthOf(tester, "left"), 148);
    expect(widthOf(tester, "right"), 444);
  });

  testWidgets("panes with nothing to say share what is left", (tester) async {
    await tester.pumpWidget(
      app(
        MochiResizable(
          panes: [
            MochiResizablePane(initialFraction: 0.5, child: pane("left")),
            MochiResizablePane(child: pane("middle")),
            MochiResizablePane(child: pane("right")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(widthOf(tester, "middle"), widthOf(tester, "right"));
    expect(widthOf(tester, "left"), widthOf(tester, "middle") * 2);
  });

  testWidgets("dragging the line gives one pane what the other gives up", (tester) async {
    await tester.pumpWidget(
      app(
        MochiResizable(
          panes: [
            MochiResizablePane(initialFraction: 0.5, child: pane("left")),
            MochiResizablePane(child: pane("right")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = widthOf(tester, "left");
    final total = before + widthOf(tester, "right");

    await dragHandle(tester, const Offset(60, 0));
    expect(widthOf(tester, "left"), moreOrLessEquals(before + 60, epsilon: 0.5));
    expect(widthOf(tester, "left") + widthOf(tester, "right"), moreOrLessEquals(total, epsilon: 0.5));
  });

  testWidgets("a pane is not dragged below its minimum", (tester) async {
    await tester.pumpWidget(
      app(
        MochiResizable(
          panes: [
            MochiResizablePane(initialFraction: 0.5, minSize: 200, child: pane("left")),
            MochiResizablePane(minSize: 100, child: pane("right")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await dragHandle(tester, const Offset(-400, 0));
    expect(widthOf(tester, "left"), 200);

    await dragHandle(tester, const Offset(400, 0));
    expect(widthOf(tester, "right"), 100, reason: "the other side has a floor too");
  });

  testWidgets("the arrows move a handle that has the keyboard", (tester) async {
    await tester.pumpWidget(
      app(
        MochiResizable(
          keyboardStep: 20,
          panes: [
            MochiResizablePane(initialFraction: 0.5, child: pane("left")),
            MochiResizablePane(child: pane("right")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = widthOf(tester, "left");

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(widthOf(tester, "left"), moreOrLessEquals(before + 20, epsilon: 0.5));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(widthOf(tester, "left"), moreOrLessEquals(before - 20, epsilon: 0.5));
  });

  testWidgets("a column splits the same way", (tester) async {
    await tester.pumpWidget(
      app(
        MochiResizable(
          axis: Axis.vertical,
          panes: [
            MochiResizablePane(initialFraction: 0.5, child: pane("top")),
            MochiResizablePane(child: pane("bottom")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = heightOf(tester, "top");

    await dragHandle(tester, const Offset(0, 40));
    expect(heightOf(tester, "top"), moreOrLessEquals(before + 40, epsilon: 0.5));
  });

  testWidgets("a narrower window keeps the split rather than giving it all to one side", (tester) async {
    Widget build(Size size) => app(
      MochiResizable(
        panes: [
          MochiResizablePane(initialFraction: 0.25, child: pane("left")),
          MochiResizablePane(child: pane("right")),
        ],
      ),
      size: size,
    );

    await tester.pumpWidget(build(const Size(600, 400)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build(const Size(300, 400)));
    await tester.pumpAndSettle();

    expect(widthOf(tester, "left"), 73, reason: "a quarter of 300 less the handle");
  });

  testWidgets("every change is reported", (tester) async {
    List<double>? reported;
    await tester.pumpWidget(
      app(
        MochiResizable(
          onChanged: (fractions) => reported = fractions,
          panes: [
            MochiResizablePane(initialFraction: 0.5, child: pane("left")),
            MochiResizablePane(child: pane("right")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await dragHandle(tester, const Offset(60, 0));
    expect(reported, isNotNull);
    expect(reported!.first, greaterThan(0.5));
    expect(reported!.reduce((a, b) => a + b), moreOrLessEquals(1, epsilon: 0.001));
  });
}
