import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  );

  Widget menubar(List<String> chosen, {bool disableView = false}) => app(
    MochiMenubar(
      menus: [
        MochiMenubarMenu(
          title: const Text("File"),
          menuBuilder: (context) => [
            MochiMenuItem(title: const Text("New session"), onPress: () => chosen.add("new")),
            MochiMenuItem(title: const Text("Import"), onPress: () => chosen.add("import")),
          ],
        ),
        MochiMenubarMenu(
          title: const Text("Session"),
          menuBuilder: (context) => [
            MochiMenuItem(title: const Text("Rename"), onPress: () => chosen.add("rename")),
          ],
        ),
        MochiMenubarMenu(
          title: const Text("View"),
          enabled: !disableView,
          menuBuilder: (context) => [
            MochiMenuItem(title: const Text("Zoom in"), onPress: () => chosen.add("zoom")),
          ],
        ),
      ],
    ),
  );

  Future<void> click(WidgetTester tester, Finder finder) async {
    await tester.tap(finder, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  testWidgets("a menu opens on a press and its rows work", (tester) async {
    final chosen = <String>[];
    await tester.pumpWidget(menubar(chosen));
    await tester.pumpAndSettle();
    expect(find.byType(MochiMenu), findsNothing);

    await click(tester, find.text("File"));
    expect(find.text("New session"), findsOneWidget);

    await click(tester, find.text("New session"));
    expect(chosen, ["new"]);
    expect(find.byType(MochiMenu), findsNothing, reason: "choosing closes it");
  });

  testWidgets("pressing the open one puts it away", (tester) async {
    await tester.pumpWidget(menubar([]));
    await tester.pumpAndSettle();

    await click(tester, find.text("File"));
    expect(find.byType(MochiMenu), findsOneWidget);
    await click(tester, find.text("File"));
    expect(find.byType(MochiMenu), findsNothing);
  });

  testWidgets("with one open, pointing at its neighbour switches over at once", (tester) async {
    await tester.pumpWidget(menubar([]));
    await tester.pumpAndSettle();
    // One mouse for the whole test: a second pointer for the same device leaves the hover
    // highlights off, and hovering is the thing being tested.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(400, 400));

    // Hovering on its own opens nothing.
    await mouse.moveTo(tester.getCenter(find.text("Session")));
    await tester.pumpAndSettle();
    expect(find.byType(MochiMenu), findsNothing);

    await mouse.moveTo(tester.getCenter(find.text("File")));
    await mouse.down(tester.getCenter(find.text("File")));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.text("New session"), findsOneWidget);

    await mouse.moveTo(tester.getCenter(find.text("Session")));
    await tester.pumpAndSettle();
    expect(find.text("Rename"), findsOneWidget);
    expect(find.text("New session"), findsNothing, reason: "one at a time");
    // Desktop chrome on a desktop platform: the default test platform is a touch one, where
    // hover highlights — and so the hover callbacks a menubar switches on — never happen.
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("the arrows walk along the bar, stepping over a disabled menu", (tester) async {
    await tester.pumpWidget(menubar([], disableView: true));
    await tester.pumpAndSettle();

    await click(tester, find.text("File"));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text("Rename"), findsOneWidget);

    // View is disabled, so the next step round lands back on File.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text("New session"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text("Rename"), findsOneWidget);
  });

  testWidgets("Escape puts the bar away", (tester) async {
    await tester.pumpWidget(menubar([]));
    await tester.pumpAndSettle();

    await click(tester, find.text("File"));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MochiMenu), findsNothing);
  });

  testWidgets("the open menu's word stays lit", (tester) async {
    await tester.pumpWidget(menubar([]));
    await tester.pumpAndSettle();

    MochiButton wordFor(String label) =>
        tester.widget<MochiButton>(find.ancestor(of: find.text(label), matching: find.byType(MochiButton)));
    expect(wordFor("File").selected, isFalse);

    await click(tester, find.text("File"));
    expect(wordFor("File").selected, isTrue);
    expect(wordFor("Session").selected, isFalse);
  });

  testWidgets("a disabled menu doesn't open", (tester) async {
    await tester.pumpWidget(menubar([], disableView: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text("View"), kind: PointerDeviceKind.mouse, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MochiMenu), findsNothing);
  });
}
