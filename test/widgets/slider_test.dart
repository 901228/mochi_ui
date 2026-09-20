import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  const width = 300.0;

  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: Center(
      child: SizedBox(width: width, child: child),
    ),
  );

  // A slider that keeps its own value, and records every change.
  Widget live(
    List<double> seen, {
    double start = 0.5,
    double min = 0,
    double max = 1,
    int? divisions,
    List<String>? edges,
  }) {
    var value = start;
    return StatefulBuilder(
      builder: (context, setState) => app(
        MochiSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChangeStart: (v) => edges?.add("start $v"),
          onChangeEnd: (v) => edges?.add("end $v"),
          onChanged: (next) => setState(() {
            seen.add(next);
            value = next;
          }),
        ),
      ),
    );
  }

  testWidgets("pressing the track sends the thumb there", (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(live(seen));

    final bar = tester.getRect(find.byType(MochiSlider));
    await tester.tapAt(Offset(bar.left + bar.width / 4, bar.center.dy));
    await tester.pump();
    expect(seen.single, closeTo(0.25, 0.03));
  });

  testWidgets("dragging follows the pointer and reports the ends of the gesture", (tester) async {
    final seen = <double>[];
    final edges = <String>[];
    await tester.pumpWidget(live(seen, start: 0, edges: edges));

    final bar = tester.getRect(find.byType(MochiSlider));
    final gesture = await tester.startGesture(Offset(bar.left + 4, bar.center.dy));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(seen.length, greaterThan(1));
    expect(seen.last, closeTo(0.55, 0.06));
    expect(edges.first, startsWith("start"));
    expect(edges.last, "end ${seen.last}");
  });

  testWidgets("it stops at the ends", (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(live(seen, min: 10, max: 20));

    final bar = tester.getRect(find.byType(MochiSlider));
    await tester.tapAt(Offset(bar.right - 2, bar.center.dy));
    await tester.pump();
    expect(seen.last, 20);

    await tester.tapAt(Offset(bar.left + 1, bar.center.dy));
    await tester.pump();
    expect(seen.last, 10);
  });

  testWidgets("divisions snap it", (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(live(seen, start: 0, min: 0, max: 10, divisions: 5));

    final bar = tester.getRect(find.byType(MochiSlider));
    await tester.tapAt(Offset(bar.left + bar.width * 0.31, bar.center.dy));
    await tester.pump();
    expect(seen.single % 2, 0, reason: "lands on a division, whatever was pressed");
  });

  testWidgets("the keyboard: one tab stop, arrows step, Home and End jump", (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(live(seen, start: 5, min: 0, max: 10, divisions: 10));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(seen, [6, 7, 6, 10, 0]);
  });

  testWidgets("without divisions an arrow moves a tenth of the range", (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(live(seen, start: 0, min: 0, max: 50));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seen.single, 5);
  });

  testWidgets("the fill shows how far along it is", (tester) async {
    await tester.pumpWidget(app(MochiSlider(value: 0.25, onChanged: (_) {})));
    await tester.pumpAndSettle();

    double widthFactor(WidgetTester tester) =>
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor!;
    expect(widthFactor(tester), closeTo(0.25, 0.001));

    await tester.pumpWidget(app(MochiSlider(value: 8, max: 10, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(widthFactor(tester), closeTo(0.8, 0.001));
  });

  testWidgets("null onChanged disables it", (tester) async {
    await tester.pumpWidget(app(const MochiSlider(value: 0.5, onChanged: null)));
    final bar = tester.getRect(find.byType(MochiSlider));
    await tester.tapAt(Offset(bar.left + 10, bar.center.dy));
    await tester.pump();

    final opacity = tester.widget<Opacity>(
      find.descendant(of: find.byType(MochiSlider), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.4);
  });

  testWidgets("the label line carries the value", (tester) async {
    await tester.pumpWidget(
      app(
        MochiSlider(
          value: 0.4,
          label: const Text("Volume"),
          valueLabel: (value) => "${(value * 100).round()}%",
          description: const Text("How loud the alert is."),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text("Volume"), findsOneWidget);
    expect(find.text("40%"), findsOneWidget);
    expect(find.text("How loud the alert is."), findsOneWidget);
  });

  testWidgets("right-to-left runs the other way", (tester) async {
    final seen = <double>[];
    var value = 0.5;
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: width,
              child: StatefulBuilder(
                builder: (context, setState) => MochiSlider(
                  value: value,
                  onChanged: (next) => setState(() {
                    seen.add(next);
                    value = next;
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(find.byType(MochiSlider));
    await tester.tapAt(Offset(bar.left + 4, bar.center.dy));
    await tester.pump();
    expect(seen.single, closeTo(1, 0.05), reason: "the start of the track is on the right");

    // The arrows move the thumb the way they point, so here right is less.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seen.last, closeTo(0.9, 0.05));
  });

  testWidgets("screen readers hear a slider", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(MochiSlider(value: 0.5, valueLabel: (v) => "${(v * 100).round()}%", onChanged: (_) {})),
    );

    final node = tester.getSemantics(
      find.descendant(of: find.byType(MochiSlider), matching: find.byType(FocusableActionDetector)),
    );
    expect(node.value, "50%");
    expect(node.increasedValue, "60%");
    expect(node.decreasedValue, "40%");
    handle.dispose();
  });
}
