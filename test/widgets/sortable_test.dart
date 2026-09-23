import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  /// A list of words, rebuilt from whatever order the sortable reports.
  Widget app(List<String> words, {bool? wholeItemDrags, double spacing = 0, bool touch = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: touch,
    home: StatefulBuilder(
      builder: (context, setState) => SizedBox(
        height: 400,
        child: MochiSortable(
          itemCount: words.length,
          spacing: spacing,
          wholeItemDrags: wholeItemDrags,
          onReorder: (from, to) => setState(() => words.insert(to, words.removeAt(from))),
          itemBuilder: (context, index) => SizedBox(
            key: ValueKey(words[index]),
            height: 60,
            child: Row(
              children: [
                Expanded(child: Text(words[index])),
                MochiSortableHandle(index: index),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// Drags a row by [pixels], which at 60 per row is that many rows.
  Future<void> dragHandle(WidgetTester tester, int index, double pixels) async {
    final handle = find.byType(MochiSortableHandle).at(index);
    final gesture = await tester.startGesture(tester.getCenter(handle), kind: PointerDeviceKind.mouse);
    await tester.pump(kLongPressTimeout);
    // A step at a time, the way a pointer travels.
    for (var moved = 0.0; moved.abs() < pixels.abs(); moved += pixels.sign * 20) {
      await gesture.moveBy(Offset(0, pixels.sign * 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets("a row dragged down lands where it was dropped", (tester) async {
    final words = ["one", "two", "three", "four"];
    await tester.pumpWidget(app(words));
    await tester.pumpAndSettle();

    await dragHandle(tester, 0, 130);
    expect(words, ["two", "three", "one", "four"]);
  });

  testWidgets("a row dragged up lands where it was dropped", (tester) async {
    final words = ["one", "two", "three", "four"];
    await tester.pumpWidget(app(words));
    await tester.pumpAndSettle();

    await dragHandle(tester, 3, -130);
    expect(words, ["one", "four", "two", "three"]);
  });

  testWidgets("the indices are the list after the move, not before it", (tester) async {
    // The old callback handed out an index counted with the row still in place, which is the
    // off-by-one every app using it writes by hand.
    final moves = <String>[];
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: SizedBox(
          height: 400,
          child: MochiSortable(
            itemCount: 4,
            onReorder: (from, to) => moves.add("$from->$to"),
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey(index),
              height: 60,
              child: Row(
                children: [
                  Expanded(child: Text("row $index")),
                  MochiSortableHandle(index: index),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await dragHandle(tester, 0, 70);
    expect(moves, ["0->1"], reason: "one row down is one place down");
  });

  testWidgets("a handle drags, and the rest of the row does not", (tester) async {
    final words = ["one", "two", "three", "four"];
    await tester.pumpWidget(app(words));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text("one")),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(kLongPressTimeout);
    for (var i = 0; i < 7; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(words, ["one", "two", "three", "four"], reason: "a row is dragged by its grip");
  });

  testWidgets("on touch the whole row answers a long press", (tester) async {
    final words = ["one", "two", "three", "four"];
    await tester.pumpWidget(app(words, touch: true));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(find.text("one")));
    await tester.pump(kLongPressTimeout);
    for (var i = 0; i < 7; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(words.first, isNot("one"));
  });

  testWidgets("the gap between rows belongs to the rows", (tester) async {
    final words = ["one", "two", "three"];
    await tester.pumpWidget(app(words, spacing: 12));
    await tester.pumpAndSettle();

    final first = tester.getRect(find.text("one"));
    final second = tester.getRect(find.text("two"));
    expect(second.center.dy - first.center.dy, 72, reason: "60 of row and 12 of gap");
  });

  testWidgets("a row carried off the list is lifted, and its shadow fits the row", (tester) async {
    final words = ["one", "two", "three", "four"];
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: SizedBox(
          height: 400,
          child: MochiSortable(
            itemCount: words.length,
            spacing: 8,
            onReorder: (from, to) {},
            itemBuilder: (context, index) => MochiCard(
              key: ValueKey(words[index]),
              child: Row(
                children: [
                  Expanded(child: Text(words[index])),
                  MochiSortableHandle(index: index),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MochiSortableHandle).first),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(kLongPressTimeout);
    await gesture.moveBy(const Offset(0, 30));
    await tester.pumpAndSettle();

    // The lift is the one shadow with nothing filled in behind it; the cards have their own.
    final shadowed = find.byWidgetPredicate((widget) {
      final decoration = widget is DecoratedBox ? widget.decoration : null;
      return decoration is ShapeDecoration &&
          decoration.color == null &&
          decoration.shadows?.isNotEmpty == true;
    });
    expect(shadowed, findsOneWidget, reason: "the row being carried casts a shadow");
    expect(
      tester.widget<DecoratedBox>(shadowed).decoration,
      isA<ShapeDecoration>().having((d) => d.shape, "shape", isA<RoundedSuperellipseBorder>()),
      reason: "a square shadow under a rounded row is a grey box nobody drew",
    );
    // And it keeps out of the gap between rows: cast around the padded row it would stand proud
    // of the row on every side, which reads as a shadow hanging over nothing.
    final carried = find.descendant(
      of: find.ancestor(of: shadowed, matching: find.byType(Stack)).first,
      matching: find.byType(MochiCard),
    );
    expect(tester.getRect(shadowed), tester.getRect(carried));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
