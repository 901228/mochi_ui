import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  late List<String> events;

  setUp(() => events = []);

  Widget app(Widget child) => MediaQuery(
    data: const MediaQueryData(size: Size(800, 600)),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      home: Center(child: child),
    ),
  );

  List<Widget> items(BuildContext context) => [
    const MochiMenuLabel(child: Text("Record")),
    MochiMenuItem(title: const Text("Rename"), onPress: () => events.add("rename")),
    MochiMenuItem(title: const Text("Archive"), onPress: () => events.add("archive")),
    const MochiMenuDivider(),
    MochiMenuItem(
      intent: MochiIntent.danger,
      title: const Text("Delete"),
      onPress: () => events.add("delete"),
    ),
    const MochiMenuItem(title: Text("Unavailable")),
  ];

  Widget menu() => MochiPopoverMenu(
    menuBuilder: items,
    builder: (context, anchor, _) =>
        MochiButton(focusNode: anchor.focusNode, onPress: anchor.toggle, child: const Text("open")),
  );

  testWidgets("opens, runs an item and closes itself", (tester) async {
    await tester.pumpWidget(app(menu()));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.text("Rename"), findsOneWidget);

    await tester.tap(find.text("Archive"));
    await tester.pumpAndSettle();
    expect(events, ["archive"]);
    expect(find.text("Archive"), findsNothing);
  });

  testWidgets("a row without a handler is disabled", (tester) async {
    await tester.pumpWidget(app(menu()));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Unavailable"));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
    // Still open: a dead row is not an outside tap.
    expect(find.text("Unavailable"), findsOneWidget);
  });

  testWidgets("closeOnPress: false keeps the menu open", (tester) async {
    await tester.pumpWidget(
      app(
        MochiPopoverMenu(
          menuBuilder: (context) => [
            MochiMenuItem(
              title: const Text("Toggle"),
              closeOnPress: false,
              onPress: () => events.add("toggle"),
            ),
          ],
          builder: (context, anchor, _) =>
              MochiButton(focusNode: anchor.focusNode, onPress: anchor.toggle, child: const Text("open")),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Toggle"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Toggle"));
    await tester.pumpAndSettle();
    expect(events, ["toggle", "toggle"]);
  });

  testWidgets("arrow keys move between rows", (tester) async {
    await tester.pumpWidget(app(menu()));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(events, ["rename"]);
  });

  group("submenu", () {
    Widget nested() => MochiPopoverMenu(
      menuBuilder: (context) => [
        MochiMenuItem(title: const Text("Rename"), onPress: () => events.add("rename")),
        MochiSubmenu(
          title: const Text("Penalty"),
          menuBuilder: (context) => [
            MochiMenuItem(title: const Text("DNF"), onPress: () => events.add("dnf")),
            MochiMenuItem(title: const Text("+2"), onPress: () => events.add("+2")),
          ],
        ),
      ],
      builder: (context, anchor, _) =>
          MochiButton(focusNode: anchor.focusNode, onPress: anchor.toggle, child: const Text("open")),
    );

    testWidgets("opens beside its row and closes the whole menu when a row is chosen", (tester) async {
      await tester.pumpWidget(app(nested()));
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Penalty"));
      await tester.pumpAndSettle();
      expect(find.text("DNF"), findsOneWidget);
      expect(
        tester.getTopLeft(find.text("DNF")).dx,
        greaterThan(tester.getTopRight(find.text("Penalty")).dx),
      );

      await tester.tap(find.text("DNF"));
      await tester.pumpAndSettle();
      expect(events, ["dnf"]);
      // Both panels: an item in a submenu closes the menu it was opened from.
      expect(find.text("DNF"), findsNothing);
      expect(find.text("Penalty"), findsNothing);
    });

    testWidgets("opens on hover and closes when another row is pointed at", (tester) async {
      await tester.pumpWidget(app(nested()));

      // Opened with the mouse: a touch tap leaves the focus system in touch mode, where hover
      // highlights, and so hover callbacks, are suppressed.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.down(tester.getCenter(find.text("open")));
      await mouse.up();
      await tester.pumpAndSettle();

      await mouse.moveTo(tester.getCenter(find.text("Penalty")));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text("DNF"), findsNothing, reason: "not until the pointer has rested");

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text("DNF"), findsOneWidget);

      await mouse.moveTo(tester.getCenter(find.text("Rename")));
      await tester.pumpAndSettle();
      expect(find.text("DNF"), findsNothing);
    });

    testWidgets("the arrow keys open and close it", (tester) async {
      await tester.pumpWidget(app(nested()));
      await tester.tap(find.text("open"), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text("DNF"), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text("DNF"), findsNothing);
      expect(find.text("Penalty"), findsOneWidget);
    });
  });

  testWidgets("a context menu opens at the pointer on a right click", (tester) async {
    await tester.pumpWidget(
      app(
        MochiContextMenu(
          menuBuilder: items,
          child: const SizedBox(width: 200, height: 100, child: Text("row")),
        ),
      ),
    );

    final target = tester.getCenter(find.text("row"));
    final mouse = await tester.startGesture(target, kind: PointerDeviceKind.mouse, buttons: kSecondaryButton);
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.text("Rename"), findsOneWidget);
    // The panel's top left corner sits where the pointer was.
    final panel = tester.getTopLeft(find.byType(MochiMenu));
    expect(panel.dx, closeTo(target.dx, 8));
    expect(panel.dy, closeTo(target.dy, 8));
  });

  testWidgets("a context menu opens on a long press", (tester) async {
    await tester.pumpWidget(
      app(
        MochiContextMenu(
          menuBuilder: items,
          child: const SizedBox(width: 200, height: 100, child: Text("row")),
        ),
      ),
    );

    await tester.longPress(find.text("row"));
    await tester.pumpAndSettle();
    expect(find.text("Rename"), findsOneWidget);
  });

  testWidgets("a long press on the child wins over the context menu", (tester) async {
    await tester.pumpWidget(
      app(
        MochiContextMenu(
          menuBuilder: items,
          child: MochiTile(title: const Text("row"), onPress: () {}, onLongPress: () => events.add("select")),
        ),
      ),
    );

    await tester.longPress(find.text("row"));
    await tester.pumpAndSettle();
    expect(events, ["select"]);
    expect(find.text("Rename"), findsNothing);
  });
}
