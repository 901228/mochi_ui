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
}
