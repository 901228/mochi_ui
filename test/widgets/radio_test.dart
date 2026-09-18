import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Center(child: SizedBox(width: 500, child: child)),
  );

  Widget group({
    required String? value,
    ValueChanged<String?>? onChanged,
    MochiRadioAppearance appearance = MochiRadioAppearance.plain,
    Axis axis = Axis.vertical,
    bool disableB = false,
  }) => MochiRadioGroup<String>(
    value: value,
    onChanged: onChanged,
    appearance: appearance,
    axis: axis,
    children: [
      const MochiRadio(value: "a", label: Text("A"), description: Text("First")),
      MochiRadio(value: "b", label: const Text("B"), enabled: !disableB),
      const MochiRadio(value: "c", label: Text("C")),
    ],
  );

  testWidgets("a press chooses that option", (tester) async {
    String? chosen;
    await tester.pumpWidget(app(group(value: "a", onChanged: (value) => chosen = value)));

    await tester.tap(find.text("C"));
    expect(chosen, "c");
  });

  testWidgets("pressing the chosen option again keeps it", (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(group(value: "a", onChanged: (_) => calls++)));

    await tester.tap(find.text("A"));
    expect(calls, 0);
  });

  testWidgets("the arrow keys move the choice", (tester) async {
    String? value = "a";
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) =>
            app(group(value: value, onChanged: (next) => setState(() => value = next))),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(value, "b");
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(value, "c");
  });

  testWidgets("a disabled option can't be chosen", (tester) async {
    String? chosen;
    await tester.pumpWidget(app(group(value: "a", onChanged: (value) => chosen = value, disableB: true)));

    await tester.tap(find.text("B"), warnIfMissed: false);
    expect(chosen, isNull);
  });

  testWidgets("a group without onChanged is disabled throughout", (tester) async {
    await tester.pumpWidget(app(group(value: "a")));

    final opacities = tester
        .widgetList<Opacity>(
          find.descendant(of: find.byType(MochiRadio<String>), matching: find.byType(Opacity)),
        )
        .map((o) => o.opacity);
    expect(opacities, contains(0.4));
    expect(opacities.where((o) => o == 1), isEmpty);
  });

  testWidgets("cards: the whole card is the target, and the chosen one is outlined in the intent", (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      app(
        group(
          value: "a",
          onChanged: (value) => chosen = value,
          appearance: MochiRadioAppearance.card,
          axis: Axis.horizontal,
        ),
      ),
    );

    // Near a card's corner, well away from its dot and its words.
    final card = tester.getRect(find.byType(MochiRadio<String>).at(2));
    await tester.tapAt(card.bottomLeft + const Offset(6, -6));
    expect(chosen, "c");

    Color borderOf(int index) =>
        ((tester
                            .widget<Container>(
                              find
                                  .descendant(
                                    of: find.byType(MochiRadio<String>).at(index),
                                    matching: find.byType(Container),
                                  )
                                  .first,
                            )
                            .decoration!
                        as ShapeDecoration)
                    .shape
                as RoundedSuperellipseBorder)
            .side
            .color;
    expect(borderOf(0), MochiColors.light.primary.base);
    expect(borderOf(1), isNot(MochiColors.light.primary.base));
  });

  testWidgets("cards in a row share its width", (tester) async {
    await tester.pumpWidget(
      app(group(value: "a", onChanged: (_) {}, appearance: MochiRadioAppearance.card, axis: Axis.horizontal)),
    );
    final widths = [for (var i = 0; i < 3; i++) tester.getSize(find.byType(MochiRadio<String>).at(i)).width];
    expect(widths[0], widths[1]);
    expect(widths[1], widths[2]);
  });
}
