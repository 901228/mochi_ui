import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {Size size = const Size(1200, 800), MochiStrings? strings}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    strings: strings ?? MochiStrings.en,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: 260, child: child),
        ),
      ),
    ),
  );

  /// The surface itself, not a MediaQuery over it: a sheet is as tall as its contents, and a
  /// screen that only says it is 900 tall has nowhere to put them.
  void screen(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> click(WidgetTester tester, Finder finder) async {
    await tester.tap(finder, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  testWidgets("the hint until a day is picked, then the day", (tester) async {
    DateTime? value;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) =>
              MochiDatePicker.single(value: value, onChanged: (day) => setState(() => value = day)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Pick a date"), findsOneWidget);

    await click(tester, find.byIcon(MochiIcons.standard.calendar));
    expect(find.byType(MochiCalendar), findsOneWidget);

    await click(tester, find.text("15").first);
    expect(value!.day, 15);
    expect(find.byType(MochiCalendar), findsNothing, reason: "picking a day is the whole errand");
    expect(find.textContaining("15"), findsOneWidget);
  });

  testWidgets("the day is written the way the strings write it", (tester) async {
    final day = DateTime(2026, 7, 12);
    await tester.pumpWidget(app(MochiDatePicker.single(value: day, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text("12 July 2026"), findsOneWidget);

    await tester.pumpWidget(
      app(
        MochiDatePicker.single(value: day, onChanged: (_) {}),
        strings: MochiStrings.zhHant,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("2026 年 7 月 12 日"), findsOneWidget);
  });

  testWidgets("a format of the app's own wins", (tester) async {
    await tester.pumpWidget(
      app(
        MochiDatePicker.single(
          value: DateTime(2026, 7, 12),
          format: (day) => "${day.year}/${day.month}/${day.day}",
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("2026/7/12"), findsOneWidget);
  });

  testWidgets("a range stays open for its second end", (tester) async {
    MochiDateRange? range;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) =>
              MochiDatePicker.range(value: range, onChanged: (next) => setState(() => range = next)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await click(tester, find.byIcon(MochiIcons.standard.calendar));
    await click(tester, find.text("10").first);
    expect(find.byType(MochiCalendar), findsOneWidget, reason: "half a range is not an answer");

    await click(tester, find.text("14").first);
    expect(find.byType(MochiCalendar), findsNothing);
    expect(range!.complete, isTrue);
    // Written once: the two ends share their month and year.
    expect(find.textContaining("–"), findsOneWidget);
    expect(find.textContaining("10 – 14"), findsOneWidget);
  });

  testWidgets("on a phone it comes up as a sheet, which is answered and then confirmed", (tester) async {
    DateTime? value;
    screen(tester, const Size(420, 900));
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) =>
              MochiDatePicker.single(value: value, onChanged: (day) => setState(() => value = day)),
        ),
        size: const Size(420, 900),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(MochiIcons.standard.calendar));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);
    expect(find.byType(MochiCalendar), findsOneWidget);

    await tester.tap(find.text("15").first);
    await tester.pumpAndSettle();
    expect(value, isNull, reason: "a sheet keeps its draft until the button says otherwise");
    expect(find.byType(MochiSheet), findsOneWidget);

    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    expect(value!.day, 15);
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("a range in a sheet is given its second end", (tester) async {
    // The sheet is a route, so nothing the picker rebuilds reaches inside it: the draft the
    // calendar is drawn from has to be the sheet's own, or a range could never be finished.
    MochiDateRange? range;
    screen(tester, const Size(420, 900));
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) =>
              MochiDatePicker.range(value: range, onChanged: (next) => setState(() => range = next)),
        ),
        size: const Size(420, 900),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(MochiIcons.standard.calendar));
    await tester.pumpAndSettle();

    await tester.tap(find.text("10").first);
    await tester.pumpAndSettle();
    await tester.tap(find.text("OK"), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget, reason: "half a range is not an answer");

    await tester.tap(find.text("14").first);
    await tester.pumpAndSettle();
    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();

    expect(find.byType(MochiSheet), findsNothing);
    expect(range!.complete, isTrue);
    expect(range!.start.day, 10);
    expect(range!.end!.day, 14);
  });

  testWidgets("the label, description and error go where a field's do", (tester) async {
    await tester.pumpWidget(
      app(
        MochiDatePicker.single(
          label: const Text("Session started"),
          description: const Text("The day of the first solve."),
          error: "Pick a day.",
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Session started"), findsOneWidget);
    expect(find.text("Pick a day."), findsOneWidget);
    expect(find.text("The day of the first solve."), findsNothing, reason: "the error replaces it");
  });

  testWidgets("disabled doesn't open", (tester) async {
    await tester.pumpWidget(app(MochiDatePicker.single(enabled: false, onChanged: (_) {})));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(MochiIcons.standard.calendar), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MochiCalendar), findsNothing);
  });

  testWidgets("as tall as a button of the same size", (tester) async {
    for (final size in MochiSize.values) {
      await tester.pumpWidget(
        app(
          Row(
            children: [
              Expanded(
                child: MochiDatePicker.single(size: size, onChanged: (_) {}),
              ),
              MochiButton(size: size, onPress: () {}, child: const Text("Go")),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(MochiDatePicker)).height,
        tester.getSize(find.byType(MochiButton)).height,
        reason: size.name,
      );
    }
  });

  testWidgets("a range writes what its ends share only once", (tester) async {
    // Relative to now, since the year is left out when it is this one.
    final year = DateTime.now().year;

    Future<void> show(MochiDateRange range, {MochiStrings? strings}) async {
      await tester.pumpWidget(
        app(
          MochiDatePicker.range(value: range, onChanged: (_) {}),
          strings: strings,
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(MochiDateRange(DateTime(year, 7, 12), DateTime(year, 7, 18)));
    expect(find.text("12 – 18 Jul"), findsOneWidget, reason: "one month, one year, this year");

    await show(MochiDateRange(DateTime(year, 7, 12), DateTime(year, 8, 18)));
    expect(find.text("12 Jul – 18 Aug"), findsOneWidget);

    await show(MochiDateRange(DateTime(year + 1, 7, 12), DateTime(year + 1, 8, 18)));
    expect(find.text("12 Jul – 18 Aug ${year + 1}"), findsOneWidget, reason: "not this year");

    await show(MochiDateRange(DateTime(year, 7, 12), DateTime(year + 1, 8, 18)));
    expect(find.text("12 Jul $year – 18 Aug ${year + 1}"), findsOneWidget);

    await show(MochiDateRange(DateTime(year, 7, 12), DateTime(year, 7, 18)), strings: MochiStrings.zhHant);
    expect(find.text("7 月 12 – 18 日"), findsOneWidget);
  });

  testWidgets("a range too long for the line wraps rather than trailing off", (tester) async {
    final year = DateTime.now().year;
    await tester.pumpWidget(
      app(
        MochiDatePicker.range(
          value: MochiDateRange(DateTime(year, 9, 28), DateTime(year + 1, 12, 30)),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.textContaining("–"));
    expect(text.maxLines, 2);

    final painter = TextPainter(
      text: TextSpan(text: text.data, style: text.style),
      textDirection: TextDirection.ltr,
      maxLines: text.maxLines,
    )..layout(maxWidth: tester.getSize(find.textContaining("–")).width);
    expect(painter.didExceedMaxLines, isFalse, reason: "a date cut in half says nothing");
    painter.dispose();
  });
}
