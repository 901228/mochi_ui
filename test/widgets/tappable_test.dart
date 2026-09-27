import "package:flutter/services.dart";
import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  late List<String> events;
  late Set<WidgetState> lastStates;

  Widget tappable({
    bool enabled = true,
    bool selected = false,
    bool withDouble = false,
    bool withSecondary = true,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: MochiTappable(
        enabled: enabled,
        selected: selected,
        onPress: () => events.add("press"),
        onLongPress: () => events.add("long"),
        onDoublePress: withDouble ? () => events.add("double") : null,
        onSecondaryPress: withSecondary ? () => events.add("secondary") : null,
        onSecondaryLongPress: withSecondary ? () => events.add("secondaryLong") : null,
        builder: (context, states, _) {
          lastStates = {...states};
          return const SizedBox(width: 100, height: 40);
        },
      ),
    ),
  );

  setUp(() {
    events = [];
    lastStates = {};
  });

  testWidgets("press fires immediately without a double-press callback", (tester) async {
    await tester.pumpWidget(tappable());
    await tester.tap(find.byType(MochiTappable));
    expect(events, ["press"]);
  });

  testWidgets("double press is recognized and suppresses press", (tester) async {
    await tester.pumpWidget(tappable(withDouble: true));
    await tester.tap(find.byType(MochiTappable));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(MochiTappable));
    await tester.pumpAndSettle();
    expect(events, ["double"]);
  });

  testWidgets("pressed state is kept during a long press", (tester) async {
    await tester.pumpWidget(tappable());
    final gesture = await tester.startGesture(tester.getCenter(find.byType(MochiTappable)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(events, ["long"]);
    expect(lastStates, contains(WidgetState.pressed));
    await gesture.up();
    await tester.pump();
    expect(lastStates, isNot(contains(WidgetState.pressed)));
  });

  testWidgets("secondary press", (tester) async {
    await tester.pumpWidget(tappable());
    await tester.tap(find.byType(MochiTappable), buttons: kSecondaryButton);
    expect(events, ["secondary"]);
  });

  testWidgets("enabled: false disables despite callbacks", (tester) async {
    await tester.pumpWidget(tappable(enabled: false));
    await tester.tap(find.byType(MochiTappable));
    expect(events, isEmpty);
    expect(lastStates, contains(WidgetState.disabled));
  });

  testWidgets("selected is reflected in states", (tester) async {
    await tester.pumpWidget(tappable(selected: true));
    expect(lastStates, contains(WidgetState.selected));
    await tester.pumpWidget(tappable());
    expect(lastStates, isNot(contains(WidgetState.selected)));
  });

  group("the ring is for the keyboard", () {
    /// How many rings are lit anywhere on screen.
    int rings(WidgetTester tester) =>
        tester.widgetList<MochiFocusRing>(find.byType(MochiFocusRing)).where((ring) => ring.visible).length;

    testWidgets("a row wears none because something inside it is focused", (tester) async {
      final inner = FocusNode();
      addTearDown(inner.dispose);
      var outer = <WidgetState>{};

      await tester.pumpWidget(
        MochiApp(
          themeMode: MochiThemeMode.light,
          touch: false,
          home: Center(
            child: MochiTappable(
              onPress: () {},
              builder: (context, states, child) {
                outer = states;
                return child!;
              },
              child: MochiButton(focusNode: inner, onPress: () {}, child: const Text("inside")),
            ),
          ),
        ),
      );

      inner.requestFocus();
      await tester.pumpAndSettle();

      // The button has the focus, so the button has the ring — one ring, not the row's as well.
      expect(inner.hasPrimaryFocus, isTrue);
      expect(rings(tester), 1);
      expect(outer.contains(WidgetState.focused), isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets("focus a mouse brought back asks for no ring, a key does", (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        MochiApp(
          themeMode: MochiThemeMode.light,
          touch: false,
          home: Center(
            child: MochiButton(focusNode: node, onPress: () {}, child: const Text("open")),
          ),
        ),
      );

      // What a popover does when it closes: it gives the focus back to the anchor. After a mouse
      // press that is a ring nobody asked for, and Flutter cannot tell the two apart on a desktop
      // — a mouse and a keyboard are both FocusHighlightMode.traditional.
      await tester.tap(find.byType(MochiButton), kind: PointerDeviceKind.mouse);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasPrimaryFocus, isTrue);
      expect(rings(tester), 0);

      // A key says the keyboard is driving, and the ring turns up on what is already focused.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(rings(tester), 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  });
}
