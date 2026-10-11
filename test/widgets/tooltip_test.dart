import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  late List<String> events;

  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    home: Center(child: child),
  );

  Widget button({VoidCallback? onLongPress, String label = "Save"}) => MochiButton(
    tooltip: "Tip $label",
    onPress: () => events.add("press $label"),
    onLongPress: onLongPress,
    child: Text(label),
  );

  setUp(() => events = []);

  testWidgets("shows after the hover delay and hides on exit", (tester) async {
    await tester.pumpWidget(app(button()));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text("Save")));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Tip Save"), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text("Tip Save"), findsOneWidget);
    // Positioned above the button, not over it.
    expect(tester.getBottomLeft(find.text("Tip Save")).dy, lessThan(tester.getTopLeft(find.text("Save")).dy));

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text("Tip Save"), findsNothing);
    await mouse.removePointer();
  });

  testWidgets("touch long press shows the tooltip without pressing the button", (tester) async {
    await tester.pumpWidget(app(button()));
    await tester.longPress(find.text("Save"));
    await tester.pump();
    expect(find.text("Tip Save"), findsOneWidget);
    expect(events, isEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets("button onLongPress wins over the tooltip on touch", (tester) async {
    await tester.pumpWidget(app(button(onLongPress: () => events.add("long"))));
    await tester.longPress(find.text("Save"));
    await tester.pumpAndSettle();
    expect(events, ["long"]);
    expect(find.text("Tip Save"), findsNothing);
  });

  testWidgets("keyboard focus shows the tooltip and moving focus swaps it", (tester) async {
    await tester.pumpWidget(
      app(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(),
            button(label: "Open"),
          ],
        ),
      ),
    );
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text("Tip Save"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text("Tip Save"), findsNothing);
    expect(find.text("Tip Open"), findsOneWidget);

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });
}
