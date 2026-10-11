import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Center(child: child),
  );

  // A stepper that keeps its own value, and records every change.
  Widget live(
    List<int> seen, {
    int start = 5,
    int? min,
    int? max,
    int step = 1,
    String Function(int value)? format,
  }) {
    var value = start;
    return StatefulBuilder(
      builder: (context, setState) => app(
        MochiStepper(
          value: value,
          min: min,
          max: max,
          step: step,
          format: format,
          onChanged: (next) => setState(() {
            seen.add(next);
            value = next;
          }),
        ),
      ),
    );
  }

  Finder minus() =>
      find.ancestor(of: find.byIcon(MochiIcons.standard.minus), matching: find.byType(MochiButton));
  Finder plus() =>
      find.ancestor(of: find.byIcon(MochiIcons.standard.plus), matching: find.byType(MochiButton));

  testWidgets("the buttons step by step", (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(live(seen, step: 5));

    await tester.tap(plus());
    await tester.pump();
    expect(seen, [10]);
    expect(find.text("10"), findsOneWidget);

    await tester.tap(minus());
    await tester.pump();
    expect(seen, [10, 5]);
  });

  testWidgets("stops at min and max, and greys out that button", (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(live(seen, start: 9, max: 10));

    await tester.tap(plus());
    await tester.pump();
    expect(seen, [10]);
    expect(tester.widget<MochiButton>(plus()).enabled, isFalse);

    await tester.tap(plus(), warnIfMissed: false);
    await tester.pump();
    expect(seen, [10]);
    expect(tester.widget<MochiButton>(minus()).enabled, isTrue);
  });

  testWidgets("a step past a bound lands on it", (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(live(seen, start: 8, max: 10, step: 5));

    await tester.tap(plus());
    await tester.pump();
    expect(seen, [10]);
  });

  testWidgets("holding a button repeats it, and its release adds nothing more", (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(live(seen, start: 0));

    final gesture = await tester.startGesture(tester.getCenter(plus()));
    await tester.pump(const Duration(milliseconds: 399));
    expect(seen, isEmpty, reason: "still a press, not yet a hold");
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pump();

    expect(seen.length, greaterThan(3));
    final held = seen.length;
    await tester.pump(const Duration(seconds: 1));
    expect(seen.length, held, reason: "stops when released");
    expect(seen, List.generate(held, (i) => i + 1));
  });

  testWidgets("the keyboard: one tab stop, arrows step, Home and End jump", (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(live(seen, start: 5, min: 0, max: 60));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(seen, [6, 7, 6, 60, 0]);

    // The buttons are not tab stops of their own.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<MochiButton>(), isNull);
  });

  testWidgets("format and the width it keeps", (tester) async {
    await tester.pumpWidget(app(MochiStepper(value: 5, max: 100, format: (v) => "${v}s", onChanged: (_) {})));
    expect(find.text("5s"), findsOneWidget);
    final narrow = tester.getSize(find.byType(MochiStepper)).width;

    await tester.pumpWidget(
      app(MochiStepper(value: 100, max: 100, format: (v) => "${v}s", onChanged: (_) {})),
    );
    expect(tester.getSize(find.byType(MochiStepper)).width, narrow, reason: "sized for the widest value");
  });

  testWidgets("as tall as a button of the same size", (tester) async {
    for (final size in MochiSize.values) {
      await tester.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MochiStepper(value: 1, size: size, onChanged: (_) {}),
              MochiButton(size: size, onPress: () {}, child: const Text("Go")),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(MochiStepper)).height,
        tester.getSize(find.byType(MochiButton).last).height,
        reason: size.name,
      );
    }
  });

  testWidgets("null onChanged disables both buttons", (tester) async {
    await tester.pumpWidget(app(const MochiStepper(value: 5, onChanged: null)));
    expect(tester.widget<MochiButton>(plus()).enabled, isFalse);
    expect(tester.widget<MochiButton>(minus()).enabled, isFalse);
  });

  testWidgets("screen readers can step it", (tester) async {
    final handle = tester.ensureSemantics();
    final seen = <int>[];
    await tester.pumpWidget(live(seen, start: 5, min: 0, max: 10));

    final node = tester.getSemantics(find.byType(MochiStepper));
    expect(node.value, "5");
    expect(node.increasedValue, "6");
    expect(node.decreasedValue, "4");
    handle.dispose();
  });

  group("typing the value", () {
    Future<void> openField(WidgetTester tester) async {
      await tester.tap(find.text("5"));
      await tester.pump();
    }

    testWidgets("pressing the number opens a field with the plain value, selected", (tester) async {
      await tester.pumpWidget(live([], format: (value) => "${value}s"));
      expect(find.text("5s"), findsOneWidget);

      await tester.tap(find.text("5s"));
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, "5", reason: "only the number is typed");
      expect(find.text("s"), findsOneWidget, reason: "the unit stays beside the field");
      expect(editable.controller.selection.textInside("5"), "5");
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets("Enter takes what was typed and gives the stepper back the keyboard", (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(live(seen));
      await openField(tester);

      tester.testTextInput.enterText("42");
      await tester.pump();
      expect(seen, isEmpty, reason: "not until it is finished");

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(seen, [42]);
      expect(find.byType(EditableText), findsNothing);

      // The arrows work again straight away.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(seen, [42, 43]);
    });

    testWidgets("leaving the field takes what was typed", (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(live(seen));
      await openField(tester);

      tester.testTextInput.enterText("9");
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(seen, [9]);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets("out of range is pulled back, nonsense is put back", (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(live(seen, min: 0, max: 10));

      await openField(tester);
      tester.testTextInput.enterText("99");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(seen, [10]);

      await tester.tap(find.text("10"));
      await tester.pump();
      tester.testTextInput.enterText("");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(seen, [10], reason: "nothing typed, nothing changed");
      expect(find.text("10"), findsOneWidget);
    });

    testWidgets("Escape drops what was typed", (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(live(seen));
      await openField(tester);

      tester.testTextInput.enterText("42");
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(seen, isEmpty);
      expect(find.text("5"), findsOneWidget);
    });

    testWidgets("the arrows still step while typing", (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(live(seen, step: 5));
      await openField(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(seen, [10]);
      expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, "10");

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(seen, [10, 5]);
    });

    testWidgets("editable: false leaves the number alone, and so does a disabled stepper", (tester) async {
      await tester.pumpWidget(app(const MochiStepper(value: 5, editable: false, onChanged: null)));
      await tester.tap(find.text("5"));
      await tester.pump();
      expect(find.byType(EditableText), findsNothing);

      await tester.pumpWidget(app(const MochiStepper(value: 5, onChanged: null)));
      await tester.tap(find.text("5"));
      await tester.pump();
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets("opening one field puts another one away, taking what it held", (tester) async {
      final seen = <int>[];
      var first = 5;
      var second = 8;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => app(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MochiStepper(
                  value: first,
                  onChanged: (value) => setState(() {
                    seen.add(value);
                    first = value;
                  }),
                ),
                MochiStepper(value: second, onChanged: (value) => setState(() => second = value)),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text("5"));
      await tester.pump();
      tester.testTextInput.enterText("12");
      await tester.pump();

      await tester.tap(find.text("8"));
      await tester.pump();
      await tester.pump();
      expect(seen, [12], reason: "the field it left took what was in it");
      expect(find.byType(EditableText), findsOneWidget, reason: "only the one just pressed");
      expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, "8");
    });

    testWidgets("a format that rewrites the digits leaves the field on its own", (tester) async {
      await tester.pumpWidget(
        live([], start: 65, format: (value) => "${(value ~/ 60)}:${(value % 60).toString().padLeft(2, "0")}"),
      );
      await tester.tap(find.text("1:05"));
      await tester.pump();

      expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, "65");
      expect(find.byType(Text), findsNothing, reason: "nothing to put around it");
    });
  });
}
