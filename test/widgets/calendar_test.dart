import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {MochiStrings? strings}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    strings: strings ?? MochiStrings.en,
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 320, child: child),
    ),
  );

  // July 2026 starts on a Wednesday and has 31 days, so it fills five weeks.
  final july = DateTime(2026, 7);

  // Six weeks are always drawn, so a number can appear twice — 3 July and 3 August. The first is
  // the one in the month on show, since the days before it belong to the end of the last month.
  Finder day(String text) => find.ancestor(of: find.text(text), matching: find.byType(MochiTappable)).first;

  testWidgets("a month of days, with the ones either side greyed", (tester) async {
    await tester.pumpWidget(app(MochiCalendar.single(month: july, onChanged: (_) {})));
    await tester.pumpAndSettle();

    expect(find.text("July 2026"), findsOneWidget);
    expect(find.text("31"), findsOneWidget);
    // Six weeks whatever the month needs, so the grid never changes height.
    expect(find.text("8"), findsNWidgets(2), reason: "8 July and 8 August");
    // The days of June and August that fill the first and last weeks: the month runs Wed 1 July
    // to Fri 31 July, so 29 June leads and 1-2 August trail.
    expect(find.text("29"), findsNWidgets(2), reason: "29 June leads, 29 July is its own");
    expect(find.text("1"), findsNWidgets(2), reason: "1 July and 1 August");
    expect(find.text("2"), findsNWidgets(2), reason: "2 July and 2 August");
  });

  testWidgets("weekdays run from the day the week starts on", (tester) async {
    await tester.pumpWidget(app(MochiCalendar.single(month: july, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text("Mon"), findsOneWidget);

    await tester.pumpWidget(
      app(MochiCalendar.single(month: july, firstDayOfWeek: DateTime.sunday, onChanged: (_) {})),
    );
    await tester.pumpAndSettle();
    final labels = tester
        .widgetList<Text>(find.descendant(of: find.byType(MochiCalendar), matching: find.byType(Text)))
        .map((t) => t.data)
        .toList();
    expect(labels.take(4), containsAllInOrder(["July 2026", "Sun", "Mon"]));
  });

  testWidgets("the strings come from the theme", (tester) async {
    await tester.pumpWidget(
      app(
        MochiCalendar.single(month: july, onChanged: (_) {}),
        strings: MochiStrings.zhHant,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("2026 年 7 月"), findsOneWidget);
    expect(find.text("一"), findsOneWidget);
  });

  testWidgets("pressing a day picks it", (tester) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(app(MochiCalendar.single(month: july, onChanged: picked.add)));
    await tester.pumpAndSettle();

    await tester.tap(day("15"));
    expect(picked, [DateTime(2026, 7, 15)]);
  });

  testWidgets("multiple gathers days and lets them go again", (tester) async {
    var days = <DateTime>{};
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => MochiCalendar.multiple(
            month: july,
            values: days,
            onChanged: (next) => setState(() => days = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(day("3"));
    await tester.pumpAndSettle();
    await tester.tap(day("5"));
    await tester.pumpAndSettle();
    expect(days, {DateTime(2026, 7, 3), DateTime(2026, 7, 5)});

    await tester.tap(day("3"));
    await tester.pumpAndSettle();
    expect(days, {DateTime(2026, 7, 5)}, reason: "pressing it again takes it back");
  });

  testWidgets("range takes two ends, and a third press starts again", (tester) async {
    MochiDateRange? range;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => MochiCalendar.range(
            month: july,
            value: range,
            onChanged: (next) => setState(() => range = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(day("10"));
    await tester.pumpAndSettle();
    expect(range, MochiDateRange(DateTime(2026, 7, 10)));
    expect(range!.complete, isFalse);

    await tester.tap(day("14"));
    await tester.pumpAndSettle();
    expect(range, MochiDateRange(DateTime(2026, 7, 10), DateTime(2026, 7, 14)));

    await tester.tap(day("20"));
    await tester.pumpAndSettle();
    expect(range, MochiDateRange(DateTime(2026, 7, 20)), reason: "a finished range starts over");
  });

  testWidgets("a second end before the first turns the range round", (tester) async {
    MochiDateRange? range;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => MochiCalendar.range(
            month: july,
            value: range,
            onChanged: (next) => setState(() => range = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(day("14"));
    await tester.pumpAndSettle();
    await tester.tap(day("10"));
    await tester.pumpAndSettle();
    expect(range, MochiDateRange(DateTime(2026, 7, 10), DateTime(2026, 7, 14)));
  });

  testWidgets("the arrows change the month, and stop at the ends", (tester) async {
    await tester.pumpWidget(
      app(
        // Uncontrolled: the arrows are the calendar's own to follow.
        MochiCalendar.single(
          value: DateTime(2026, 7, 15),
          first: DateTime(2026, 6, 1),
          last: DateTime(2026, 8, 31),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder arrow(IconData icon) => find.ancestor(of: find.byIcon(icon), matching: find.byType(MochiButton));

    await tester.tap(arrow(MochiIcons.standard.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.text("June 2026"), findsOneWidget);
    expect(tester.widget<MochiButton>(arrow(MochiIcons.standard.chevronLeft)).enabled, isFalse);

    await tester.tap(arrow(MochiIcons.standard.chevronRight));
    await tester.pumpAndSettle();
    await tester.tap(arrow(MochiIcons.standard.chevronRight));
    await tester.pumpAndSettle();
    expect(find.text("August 2026"), findsOneWidget);
    expect(tester.widget<MochiButton>(arrow(MochiIcons.standard.chevronRight)).enabled, isFalse);
  });

  testWidgets("days outside the bounds, and days ruled out, can't be picked", (tester) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(
      app(
        MochiCalendar.single(
          month: july,
          first: DateTime(2026, 7, 10),
          enabledDay: (d) => d.day != 12,
          onChanged: picked.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(day("5"), warnIfMissed: false);
    await tester.tap(day("12"), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(picked, isEmpty);

    await tester.tap(day("11"));
    expect(picked, [DateTime(2026, 7, 11)]);
  });

  testWidgets("the keyboard walks the grid and takes a day", (tester) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(app(MochiCalendar.single(value: DateTime(2026, 7, 15), onChanged: picked.add)));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, [DateTime(2026, 7, 23)], reason: "a day right, a week down");

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(find.text("August 2026"), findsOneWidget);
  });

  testWidgets("walking off the end of a month brings the next one into view", (tester) async {
    await tester.pumpWidget(app(MochiCalendar.single(value: DateTime(2026, 7, 31), onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text("July 2026"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text("August 2026"), findsOneWidget);
  });

  testWidgets("a month given from outside is the month shown", (tester) async {
    final asked = <DateTime>[];
    await tester.pumpWidget(
      app(MochiCalendar.single(month: july, onMonthChanged: asked.add, onChanged: (_) {})),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(of: find.byIcon(MochiIcons.standard.chevronRight), matching: find.byType(MochiButton)),
    );
    await tester.pumpAndSettle();
    expect(asked, [DateTime(2026, 8)]);
    expect(find.text("July 2026"), findsOneWidget, reason: "the app owns it and hasn't moved");
  });

  testWidgets("a day picked on its own keeps all four corners", (tester) async {
    await tester.pumpWidget(
      app(MochiCalendar.single(month: july, value: DateTime(2026, 7, 15), onChanged: (_) {})),
    );
    await tester.pumpAndSettle();

    BorderRadiusGeometry cornersOf(String text) =>
        ((tester
                            .widget<Container>(
                              find.descendant(of: day(text), matching: find.byType(Container)).first,
                            )
                            .decoration!
                        as ShapeDecoration)
                    .shape
                as RoundedSuperellipseBorder)
            .borderRadius;

    expect(cornersOf("15"), MochiGeometry.standard.radius.sm);
  });

  testWidgets("a run keeps its corners at the ends and squares off in between", (tester) async {
    await tester.pumpWidget(
      app(
        MochiCalendar.range(
          month: july,
          value: MochiDateRange(DateTime(2026, 7, 10), DateTime(2026, 7, 14)),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    BorderRadius cornersOf(String text) =>
        (((tester
                                .widget<Container>(
                                  find.descendant(of: day(text), matching: find.byType(Container)).first,
                                )
                                .decoration!
                            as ShapeDecoration)
                        .shape
                    as RoundedSuperellipseBorder)
                .borderRadius
            as BorderRadius);

    expect(cornersOf("12"), BorderRadius.zero, reason: "in the middle of the band");
    expect(cornersOf("10").topLeft, isNot(Radius.zero));
    expect(cornersOf("10").topRight, Radius.zero);
    expect(cornersOf("14").topRight, isNot(Radius.zero));
  });

  testWidgets("the calendar is the same size whatever month it is on", (tester) async {
    final heights = <double>{};
    // February 2026 needs five weeks; August 2026 needs six.
    for (final month in [DateTime(2026, 2), DateTime(2026, 8), DateTime(2026, 11)]) {
      await tester.pumpWidget(app(MochiCalendar.single(month: month, onChanged: (_) {})));
      await tester.pumpAndSettle();
      heights.add(tester.getSize(find.byType(MochiCalendar)).height);
    }
    expect(heights.length, 1, reason: "heights: $heights");
  });

  testWidgets("a range can be drawn in one drag", (tester) async {
    MochiDateRange? range;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => MochiCalendar.range(
            month: july,
            value: range,
            onChanged: (next) => setState(() => range = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(day("6")));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(day("9")));
    await tester.pumpAndSettle();
    await gesture.moveTo(tester.getCenter(day("16")));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(range, MochiDateRange(DateTime(2026, 7, 6), DateTime(2026, 7, 16)));
  });

  testWidgets("a range drawn backwards grows the same way", (tester) async {
    // Dragging towards earlier days makes the moving end the range's *start*, so anything that
    // reads the anchor back out of the range follows the finger and the run never grows.
    MochiDateRange? range;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => MochiCalendar.range(
            month: july,
            value: range,
            onChanged: (next) => setState(() => range = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(day("23")));
    await tester.pump();
    // Day by day, the way a finger actually travels: a drag that lands in one jump asks the
    // question only once and any anchor at all would answer it.
    for (final over in ["22", "21", "20", "16", "11"]) {
      await gesture.moveTo(tester.getCenter(day(over)));
      await tester.pumpAndSettle();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(range, MochiDateRange(DateTime(2026, 7, 11), DateTime(2026, 7, 23)));
  });

  testWidgets("gathering days offers to let go of all of them", (tester) async {
    var days = <DateTime>{};
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => MochiCalendar.multiple(
            month: july,
            values: days,
            onChanged: (next) => setState(() => days = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Clear"), findsNothing, reason: "nothing to clear yet");

    await tester.tap(day("3"));
    await tester.pumpAndSettle();
    await tester.tap(day("8"));
    await tester.pumpAndSettle();
    expect(find.text("Clear"), findsOneWidget);

    await tester.tap(find.text("Clear"));
    await tester.pumpAndSettle();
    expect(days, isEmpty);
    expect(find.text("Clear"), findsNothing);
  });
}
