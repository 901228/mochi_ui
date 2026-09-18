import "dart:ui" show CheckedState;

import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool touch = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: Center(child: child),
  );

  Finder box() => find.descendant(of: find.byType(MochiCheckbox), matching: find.byType(Container)).first;

  Color fillOf(WidgetTester tester) =>
      (tester.widget<Container>(box()).decoration! as ShapeDecoration).color!;

  testWidgets("a press asks for the other value", (tester) async {
    bool? next;
    await tester.pumpWidget(app(MochiCheckbox(value: false, onChanged: (value) => next = value)));
    await tester.tap(find.byType(MochiCheckbox));
    expect(next, isTrue);

    await tester.pumpWidget(app(MochiCheckbox(value: true, onChanged: (value) => next = value)));
    await tester.tap(find.byType(MochiCheckbox));
    expect(next, isFalse);
  });

  testWidgets("tristate goes unchecked, checked, partly, unchecked", (tester) async {
    final seen = <bool?>[];
    bool? value = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => app(
          MochiCheckbox(
            value: value,
            tristate: true,
            onChanged: (next) => setState(() {
              seen.add(next);
              value = next;
            }),
          ),
        ),
      ),
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(MochiCheckbox));
      await tester.pump();
    }
    expect(seen, [true, null, false]);
  });

  testWidgets("checked fills with the intent, partly shows a dash", (tester) async {
    await tester.pumpWidget(app(MochiCheckbox(value: false, onChanged: (_) {})));
    expect(fillOf(tester), isNot(MochiColors.light.primary.base));

    await tester.pumpWidget(app(MochiCheckbox(value: true, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(fillOf(tester), MochiColors.light.primary.base);
    expect(tester.widget<Icon>(find.byType(Icon)).icon, MochiIcons.standard.check);

    await tester.pumpWidget(app(MochiCheckbox(value: null, tristate: true, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(tester.widget<Icon>(find.byType(Icon)).icon, MochiIcons.standard.minus);
  });

  testWidgets("the label is part of the target", (tester) async {
    bool? next;
    await tester.pumpWidget(
      app(
        MochiCheckbox(
          value: false,
          label: const Text("Inspection"),
          description: const Text("Count down first."),
          onChanged: (value) => next = value,
        ),
      ),
    );
    expect(find.text("Count down first."), findsOneWidget);

    await tester.tap(find.text("Inspection"));
    expect(next, isTrue);
  });

  testWidgets("16px on desktop, 20 on touch", (tester) async {
    await tester.pumpWidget(app(MochiCheckbox(value: false, onChanged: (_) {})));
    expect(tester.getSize(box()), const Size.square(16));

    await tester.pumpWidget(app(MochiCheckbox(value: false, onChanged: (_) {}), touch: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(box()), const Size.square(20));
  });

  testWidgets("null onChanged disables it", (tester) async {
    await tester.pumpWidget(app(const MochiCheckbox(value: false, onChanged: null)));
    await tester.tap(find.byType(MochiCheckbox), warnIfMissed: false);
    final opacity = tester.widget<Opacity>(
      find.descendant(of: find.byType(MochiCheckbox), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.4);
  });

  testWidgets("Space toggles it from the keyboard", (tester) async {
    bool? next;
    await tester.pumpWidget(app(MochiCheckbox(value: false, onChanged: (value) => next = value)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(next, isTrue);
  });

  testWidgets("screen readers hear checked, unchecked or mixed", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(MochiCheckbox(value: true, onChanged: (_) {})));
    SemanticsNode node() => tester.getSemantics(find.byType(MochiCheckbox));
    expect(node().flagsCollection.isChecked, CheckedState.isTrue);

    await tester.pumpWidget(app(MochiCheckbox(value: null, tristate: true, onChanged: (_) {})));
    expect(node().flagsCollection.isChecked, CheckedState.mixed);
    handle.dispose();
  });

  test("only a tristate checkbox may be partly checked", () {
    expect(() => MochiCheckbox(value: null, onChanged: (_) {}), throwsAssertionError);
  });
}
