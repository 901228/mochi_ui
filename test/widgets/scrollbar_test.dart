import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  RawScrollbar bar(WidgetTester tester) => tester.widget<RawScrollbar>(find.byType(RawScrollbar));

  Widget app() => MochiApp(
    themeMode: MochiThemeMode.light,
    home: Center(
      child: SizedBox(
        height: 200,
        width: 200,
        child: MochiScrollbar(
          child: ListView(children: [for (var i = 0; i < 20; i++) const SizedBox(height: 40)]),
        ),
      ),
    ),
  );

  testWidgets("thumb is fully rounded and visible at rest", (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final scrollbar = bar(tester);
    expect(scrollbar.thumbVisibility, isTrue);
    expect(scrollbar.radius, Radius.circular(scrollbar.thickness! / 2));
  });

  testWidgets("thickens near the scrollbar, not over the rest of the content", (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final resting = bar(tester).thickness!;

    final area = tester.getRect(find.byType(MochiScrollbar));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(area.center);
    await tester.pumpAndSettle();
    expect(bar(tester).thickness, resting, reason: "middle of the content");

    await mouse.moveTo(Offset(area.right - 6, area.center.dy));
    await tester.pumpAndSettle();
    final hovered = bar(tester);
    expect(hovered.thickness, greaterThan(resting));
    expect(hovered.radius, Radius.circular(hovered.thickness! / 2));

    await mouse.moveTo(area.center);
    await tester.pumpAndSettle();
    expect(bar(tester).thickness, resting);
  });

  testWidgets("stays thick for a drag that wanders off the scrollbar", (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final resting = bar(tester).thickness!;

    final area = tester.getRect(find.byType(MochiScrollbar));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(Offset(area.right - 6, area.top + 20));
    await tester.pumpAndSettle();
    await mouse.down(Offset(area.right - 6, area.top + 20));
    await mouse.moveTo(Offset(area.left + 10, area.center.dy));
    await tester.pumpAndSettle();
    expect(bar(tester).thickness, greaterThan(resting), reason: "still dragging");

    await mouse.up();
    await tester.pumpAndSettle();
    expect(bar(tester).thickness, resting);
  });
}
