import "package:flutter/gestures.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  /// The surface itself, not a MediaQuery over it: a sheet is as tall as its contents, and a
  /// screen that only says it is 900 tall has nowhere to put them.
  void screen(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget child) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    strings: MochiStrings.en,
    home: Builder(
      builder: (context) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: 280, child: child),
        ),
      ),
    ),
  );

  /// The first column of the wheel: the middle of the wheel itself is the colon between two
  /// columns, which scrolls nothing.
  Finder hours() =>
      find.descendant(of: find.byType(MochiTimeWheel), matching: find.byType(ListWheelScrollView)).first;

  Future<void> click(WidgetTester tester, Finder finder) async {
    await tester.tap(finder, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  Widget picker(DateTime? value, ValueChanged<DateTime> onChanged, {bool seconds = false}) => StatefulBuilder(
    builder: (context, setState) => MochiDateTimePicker(
      value: value,
      showSeconds: seconds,
      onChanged: (at) => setState(() {
        value = at;
        onChanged(at);
      }),
    ),
  );

  testWidgets("the day keeps the time it already had", (tester) async {
    DateTime? picked = DateTime(2026, 7, 3, 14, 45);
    await tester.pumpWidget(app(picker(picked, (at) => picked = at)));
    await tester.pumpAndSettle();
    expect(find.text("3 July 2026 14:45"), findsOneWidget);

    await click(tester, find.byIcon(MochiIcons.standard.calendar));
    await click(tester, find.text("15").first);

    expect(picked!.day, 15);
    expect(picked!.hour, 14, reason: "a new day is not a new time");
    expect(picked!.minute, 45);
    expect(find.byType(MochiCalendar), findsOneWidget, reason: "the time is still to be picked");
  });

  testWidgets("the time keeps the day it already had", (tester) async {
    DateTime? picked = DateTime(2026, 7, 3, 14, 45);
    await tester.pumpWidget(app(picker(picked, (at) => picked = at)));
    await tester.pumpAndSettle();

    await click(tester, find.byIcon(MochiIcons.standard.calendar));
    expect(find.byType(MochiTimeWheel), findsOneWidget);

    await tester.drag(hours(), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(picked!.year, 2026);
    expect(picked!.month, 7);
    expect(picked!.day, 3, reason: "turning a wheel does not move the day");
  });

  testWidgets("it stays open until the button says the answer is done", (tester) async {
    DateTime? picked;
    await tester.pumpWidget(app(picker(picked, (at) => picked = at)));
    await tester.pumpAndSettle();

    await click(tester, find.byIcon(MochiIcons.standard.calendar));
    await click(tester, find.text("15").first);
    expect(find.byType(MochiCalendar), findsOneWidget);

    await click(tester, find.text("OK"));
    expect(find.byType(MochiCalendar), findsNothing);
    expect(picked!.day, 15);
  });

  testWidgets("a time picked before a day lands on today", (tester) async {
    DateTime? picked;
    await tester.pumpWidget(app(picker(picked, (at) => picked = at)));
    await tester.pumpAndSettle();

    await click(tester, find.byIcon(MochiIcons.standard.calendar));
    await tester.drag(hours(), const Offset(0, -200));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    expect(picked, isNotNull);
    expect(picked!.day, today.day);
    expect(picked!.month, today.month);
  });

  testWidgets("on a phone it comes up as a sheet instead", (tester) async {
    DateTime? picked;
    screen(tester, const Size(420, 900));
    await tester.pumpWidget(app(picker(picked, (at) => picked = at)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(MochiIcons.standard.calendar));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsOneWidget);
    expect(find.byType(MochiCalendar), findsOneWidget);
    expect(find.byType(MochiTimeWheel), findsOneWidget);

    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    expect(find.byType(MochiSheet), findsNothing);
  });

  testWidgets("the seconds are written only when they are being picked", (tester) async {
    final at = DateTime(2026, 7, 3, 14, 45, 30);
    await tester.pumpWidget(app(MochiDateTimePicker(value: at, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text("3 July 2026 14:45"), findsOneWidget);

    await tester.pumpWidget(app(MochiDateTimePicker(value: at, showSeconds: true, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text("3 July 2026 14:45:30"), findsOneWidget);
  });

  testWidgets("a twelve-hour clock says which half of the day it is", (tester) async {
    await tester.pumpWidget(
      app(
        MochiDateTimePicker(value: DateTime(2026, 7, 3, 14, 45), use24HourFormat: false, onChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("3 July 2026 2:45 PM"), findsOneWidget);
  });

  testWidgets("the hint until something is picked, and a format of the app's own wins", (tester) async {
    await tester.pumpWidget(app(MochiDateTimePicker(value: null, onChanged: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text("Pick a date"), findsOneWidget);

    await tester.pumpWidget(
      app(
        MochiDateTimePicker(
          value: DateTime(2026, 7, 3, 14, 45),
          format: (at) => "${at.year}/${at.month}/${at.day} ${at.hour}h",
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("2026/7/3 14h"), findsOneWidget);
  });

  testWidgets("disabled doesn't open", (tester) async {
    await tester.pumpWidget(app(const MochiDateTimePicker(value: null, onChanged: null)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(MochiIcons.standard.calendar), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MochiCalendar), findsNothing);
  });
}
