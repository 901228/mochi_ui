import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
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

  Widget wheel({
    MochiTime value = const MochiTime(hour: 9, minute: 30),
    required ValueChanged<MochiTime> onChanged,
    bool showSeconds = false,
    bool use24HourFormat = true,
    int minuteStep = 1,
  }) => app(
    MochiTimeWheel(
      value: value,
      onChanged: onChanged,
      showSeconds: showSeconds,
      use24HourFormat: use24HourFormat,
      minuteStep: minuteStep,
    ),
  );

  testWidgets("hours and minutes, and the seconds only when asked for", (tester) async {
    await tester.pumpWidget(wheel(onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsNWidgets(2));

    await tester.pumpWidget(wheel(onChanged: (_) {}, showSeconds: true));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsNWidgets(3));
  });

  testWidgets("scrolling a column reports the new time", (tester) async {
    MochiTime? picked;
    await tester.pumpWidget(wheel(onChanged: (time) => picked = time));
    await tester.pumpAndSettle();

    // The hours are the first column; a notch down is the next hour.
    await tester.drag(find.byType(ListWheelScrollView).first, const Offset(0, -32));
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 10, minute: 30));
  });

  testWidgets("a twelve-hour clock counts to twelve and says which half", (tester) async {
    MochiTime? picked;
    await tester.pumpWidget(
      wheel(
        value: const MochiTime(hour: 9, minute: 30),
        use24HourFormat: false,
        onChanged: (time) => picked = time,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("AM"), findsOneWidget);
    expect(find.text("PM"), findsOneWidget);

    // The halves are the last column: moving to PM keeps the hour but moves it past noon.
    await tester.drag(find.byType(ListWheelScrollView).last, const Offset(0, -32));
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 21, minute: 30));
  });

  testWidgets("the minutes can be worth more than one", (tester) async {
    MochiTime? picked;
    await tester.pumpWidget(
      wheel(value: const MochiTime(hour: 9), minuteStep: 15, onChanged: (time) => picked = time),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListWheelScrollView).at(1), const Offset(0, -32));
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 9, minute: 15));
  });

  testWidgets("a value set from outside doesn't answer itself back", (tester) async {
    // The gallery's shape: the wheel reports, the parent rebuilds with the new value, and the
    // wheel is then put where that value says — which must not report again, let alone from
    // inside the build that is happening.
    var value = const MochiTime(hour: 9, minute: 30);
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: StatefulBuilder(
          builder: (context, setState) => Center(
            child: SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MochiButton(
                    onPress: () => setState(() => value = const MochiTime(hour: 15)),
                    child: const Text("15:00"),
                  ),
                  MochiTimeWheel(value: value, onChanged: (time) => setState(() => value = time)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Setting the time elsewhere moves the wheel, and moving a wheel is a change it reports.
    await tester.tap(find.text("15:00"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(value, const MochiTime(hour: 15));

    await tester.drag(find.byType(ListWheelScrollView).first, const Offset(0, -64));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(value.hour, 17);
  });

  testWidgets("a mouse can drag the wheel, not only turn it", (tester) async {
    MochiTime? picked;
    await tester.pumpWidget(wheel(onChanged: (time) => picked = time));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, -32),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 10, minute: 30));
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets("one notch of the mouse wheel is one row, whatever the device sends", (tester) async {
    MochiTime? picked;
    await tester.pumpWidget(wheel(onChanged: (time) => picked = time));
    await tester.pumpAndSettle();

    final hours = tester.getCenter(find.byType(ListWheelScrollView).first);
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(hours));

    // A big notch and a small one: both are one row.
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 10, minute: 30));

    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 11, minute: 30));

    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -240)));
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 10, minute: 30), reason: "and one row back");
  });

  testWidgets("a column that doesn't wrap stops at its ends", (tester) async {
    MochiTime? picked;
    await tester.pumpWidget(
      wheel(
        value: const MochiTime(hour: 9, minute: 30),
        use24HourFormat: false,
        onChanged: (time) => picked = time,
      ),
    );
    await tester.pumpAndSettle();

    final halves = tester.getCenter(find.byType(ListWheelScrollView).last);
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(halves));

    // AM is the first of two: there is nothing above it to turn to.
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
    await tester.pumpAndSettle();
    expect(picked, isNull);

    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await tester.pumpAndSettle();
    expect(picked, const MochiTime(hour: 21, minute: 30));
  });

  group("the field", () {
    Future<void> click(WidgetTester tester, Finder finder) async {
      await tester.tap(finder, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
    }

    testWidgets("says the time, or asks for one", (tester) async {
      await tester.pumpWidget(app(MochiTimePicker(value: null, onChanged: (_) {})));
      await tester.pumpAndSettle();
      expect(find.text("Pick a time"), findsOneWidget);

      await tester.pumpWidget(
        app(MochiTimePicker(value: const MochiTime(hour: 13, minute: 5), onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.text("13:05"), findsOneWidget);
    });

    testWidgets("a twelve-hour clock, and the seconds when they are being picked", (tester) async {
      await tester.pumpWidget(
        app(
          MochiTimePicker(
            value: const MochiTime(hour: 13, minute: 5, second: 7),
            use24HourFormat: false,
            showSeconds: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("1:05:07 PM"), findsOneWidget);
    });

    testWidgets("opens the wheels in a popover, and in a sheet on a phone", (tester) async {
      await tester.pumpWidget(app(MochiTimePicker(value: const MochiTime(hour: 9), onChanged: (_) {})));
      await tester.pumpAndSettle();
      await click(tester, find.byIcon(MochiIcons.standard.clock));
      expect(find.byType(MochiTimeWheel), findsOneWidget);
      expect(find.byType(MochiSheet), findsNothing);

      await tester.pumpWidget(
        app(
          MochiTimePicker(value: const MochiTime(hour: 9), onChanged: (_) {}),
          size: const Size(420, 900),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(MochiIcons.standard.clock));
      await tester.pumpAndSettle();
      expect(find.byType(MochiSheet), findsOneWidget);
      expect(find.byType(MochiTimeWheel), findsOneWidget);
    });

    testWidgets("null onChanged disables it", (tester) async {
      await tester.pumpWidget(app(const MochiTimePicker(value: MochiTime(hour: 9), onChanged: null)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(MochiIcons.standard.clock), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(MochiTimeWheel), findsNothing);
    });

    testWidgets("as tall as a button of the same size", (tester) async {
      for (final size in MochiSize.values) {
        await tester.pumpWidget(
          app(
            Row(
              children: [
                Expanded(
                  child: MochiTimePicker(value: const MochiTime(hour: 9), size: size, onChanged: (_) {}),
                ),
                MochiButton(size: size, onPress: () {}, child: const Text("Go")),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(MochiTimePicker)).height,
          tester.getSize(find.byType(MochiButton)).height,
          reason: size.name,
        );
      }
    });
  });

  test("a time knows which half of the day it is in", () {
    expect(const MochiTime(hour: 0).hourOf12, 12);
    expect(const MochiTime(hour: 13).hourOf12, 1);
    expect(const MochiTime(hour: 12).isAfternoon, isTrue);
    expect(const MochiTime(hour: 11, minute: 59).isAfternoon, isFalse);
    expect(const MochiTime(hour: 9).compareTo(const MochiTime(hour: 9, minute: 1)), lessThan(0));
  });
}
