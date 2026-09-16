import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(size: const Size(800, 600), disableAnimations: disableAnimations),
    child: MochiApp(themeMode: MochiThemeMode.light, home: child),
  );

  Widget popover({
    MochiPopoverSide side = MochiPopoverSide.bottom,
    MochiPopoverAlign align = MochiPopoverAlign.center,
    Alignment at = Alignment.center,
    MenuController? controller,
  }) => Align(
    alignment: at,
    child: MochiPopover(
      controller: controller,
      side: side,
      align: align,
      popoverBuilder: (context) => const SizedBox(width: 200, height: 120, child: Text("panel")),
      builder: (context, anchor, _) =>
          MochiButton(focusNode: anchor.focusNode, onPress: anchor.toggle, child: const Text("open")),
    ),
  );

  testWidgets("opens on press and closes on an outside tap", (tester) async {
    await tester.pumpWidget(app(popover()));
    expect(find.text("panel"), findsNothing);

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.text("panel"), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text("panel"), findsNothing);
  });

  testWidgets("closes on escape", (tester) async {
    await tester.pumpWidget(app(popover()));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("panel"), findsNothing);
  });

  testWidgets("stays mounted while the exit animation runs", (tester) async {
    await tester.pumpWidget(app(popover()));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text("panel"), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text("panel"), findsNothing);
  });

  testWidgets("sits on the side it was given", (tester) async {
    await tester.pumpWidget(app(popover()));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text("panel")).dy, greaterThan(tester.getBottomLeft(find.text("open")).dy));
  });

  testWidgets("flips to the other side when there is no room", (tester) async {
    await tester.pumpWidget(app(popover(at: Alignment.bottomCenter)));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text("panel")).dy, lessThan(tester.getTopLeft(find.text("open")).dy));
  });

  testWidgets("aligns to the anchor's leading edge", (tester) async {
    await tester.pumpWidget(app(popover(align: MochiPopoverAlign.start)));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    // The surface pads the text, so the two left edges line up only within that padding.
    expect(tester.getTopLeft(find.text("panel")).dx, closeTo(tester.getTopLeft(find.text("open")).dx, 12));
  });

  testWidgets("stays inside the overlay when the anchor is at an edge", (tester) async {
    await tester.pumpWidget(app(popover(at: Alignment.centerRight, align: MochiPopoverAlign.start)));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(tester.getBottomRight(find.text("panel")).dx, lessThanOrEqualTo(800));
  });

  testWidgets("shows at once under reduced motion", (tester) async {
    await tester.pumpWidget(app(popover(), disableAnimations: true));
    await tester.tap(find.text("open"));
    await tester.pump();
    expect(find.text("panel"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text("panel"), findsNothing);
  });

  testWidgets("opens and closes from an external controller", (tester) async {
    final controller = MenuController();
    await tester.pumpWidget(app(popover(controller: controller)));

    controller.open();
    await tester.pumpAndSettle();
    expect(find.text("panel"), findsOneWidget);

    controller.close();
    await tester.pumpAndSettle();
    expect(find.text("panel"), findsNothing);
  });
}
