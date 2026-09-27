import "package:flutter/gestures.dart";
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

  group("one panel at a time", () {
    Widget two({bool touch = false}) => MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: MochiApp(
        themeMode: MochiThemeMode.light,
        touch: touch,
        home: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final name in ["first", "second"])
                MochiPopover(
                  popoverBuilder: (context) => Text("$name panel"),
                  builder: (context, anchor, _) =>
                      MochiButton(focusNode: anchor.focusNode, onPress: anchor.toggle, child: Text(name)),
                ),
            ],
          ),
        ),
      ),
    );

    testWidgets("a right click on a row whose menu is open leaves one panel, not two", (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MochiApp(
            themeMode: MochiThemeMode.light,
            touch: false,
            home: Center(
              child: MochiContextMenu(
                menuBuilder: (context) => [const MochiMenuItem(title: Text("from the row"))],
                child: MochiTile(
                  title: const Text("row"),
                  onPress: () {},
                  suffix: MochiPopoverMenu(
                    menuBuilder: (context) => [const MochiMenuItem(title: Text("from the button"))],
                    builder: (context, anchor, _) => MochiButton.icon(
                      focusNode: anchor.focusNode,
                      onPress: anchor.toggle,
                      icon: Icon(MochiIcons.standard.more),
                      semanticLabel: "more",
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel("more"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(find.text("from the button"), findsOneWidget);

      // A secondary tap is not an outside tap, so nothing else puts the first panel away: this is
      // the row with both a context menu and a ⋮ that had one of each standing.
      final mouse = await tester.startGesture(
        tester.getCenter(find.text("row")),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await mouse.up();
      await tester.pumpAndSettle();

      expect(find.text("from the row"), findsOneWidget);
      expect(find.text("from the button"), findsNothing);
    });

    testWidgets("the press that puts a panel away does nothing else", (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MochiApp(
            themeMode: MochiThemeMode.light,
            touch: false,
            home: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MochiPopover(
                  popoverBuilder: (context) => const Text("panel"),
                  builder: (context, anchor, _) => MochiButton(
                    focusNode: anchor.focusNode,
                    onPress: anchor.toggle,
                    child: const Text("open"),
                  ),
                ),
                MochiButton(onPress: () => pressed++, child: const Text("elsewhere")),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text("open"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(find.text("panel"), findsOneWidget);

      await tester.tap(find.text("elsewhere"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      // Aimed at "away", and that is all it did: the button under it was not pressed as well.
      expect(find.text("panel"), findsNothing);
      expect(pressed, 0);

      await tester.tap(find.text("elsewhere"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });

    testWidgets("a submenu leaves the menu it came out of standing", (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MochiApp(
            themeMode: MochiThemeMode.light,
            touch: false,
            home: Center(
              child: MochiPopoverMenu(
                menuBuilder: (context) => [
                  const MochiMenuItem(title: Text("Rename")),
                  MochiSubmenu(
                    title: const Text("Move to"),
                    menuBuilder: (context) => [const MochiMenuItem(title: Text("Archive"))],
                  ),
                ],
                builder: (context, anchor, _) => MochiButton(
                  focusNode: anchor.focusNode,
                  onPress: anchor.toggle,
                  child: const Text("open"),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text("open"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Move to"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      // The child is opened from inside the parent's panel, so the parent is not "another menu".
      expect(find.text("Archive"), findsOneWidget);
      expect(find.text("Rename"), findsOneWidget);
    });

    testWidgets("a phone dims the page behind the panel, a pointer's screen does not", (tester) async {
      Finder scrim() => find.descendant(of: find.byType(FadeTransition), matching: find.byType(ColoredBox));

      await tester.pumpWidget(two());
      await tester.tap(find.text("first"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(scrim(), findsNothing);

      // Closed before the scale changes: the tree is the same one, so a panel left open would
      // still be open and the press below would be the one that shuts it.
      await tester.tapAt(const Offset(20, 20), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      await tester.pumpWidget(two(touch: true));
      await tester.tap(find.text("first"));
      await tester.pumpAndSettle();
      expect(find.text("first panel"), findsOneWidget);
      expect(scrim(), findsOneWidget);

      // The dimming is what the dismissing tap lands on, so it puts the panel away.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text("first panel"), findsNothing);
    });
  });
}
