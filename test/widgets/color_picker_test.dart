import "dart:ui" as ui;

import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  const violet = Color(0xFF7C3AED);
  const width = 260.0;

  // A Semantics label is how a test gets hold of one of the picker's parts: the square and the
  // two bars are private.
  Finder labelled(String label) =>
      find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == label);

  Finder shade() => labelled(MochiStrings.en.shade);
  Finder hue() => labelled(MochiStrings.en.hue);
  Finder opacity() => labelled(MochiStrings.en.opacity);

  /// A picker that keeps the colour it reports, the way a form holds it.
  Widget live(List<Color> seen, {Color start = violet, bool alpha = false, bool enabled = true}) {
    var color = start;

    return MochiApp(
      themeMode: MochiThemeMode.light,
      touch: false,
      home: Center(
        child: SizedBox(
          width: width,
          child: StatefulBuilder(
            builder: (context, setState) => MochiColorPicker(
              value: color,
              alpha: alpha,
              enabled: enabled,
              onChanged: (next) => setState(() {
                seen.add(next);
                color = next;
              }),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("pressing the square picks the shade under the pointer", (tester) async {
    final seen = <Color>[];
    await tester.pumpWidget(live(seen));

    final box = tester.getRect(shade());
    // Three quarters along, a quarter down: mostly saturated, nearly bright.
    await tester.tapAt(Offset(box.left + box.width * 0.75, box.top + box.height * 0.25));
    await tester.pump();

    final picked = HSVColor.fromColor(seen.single);
    expect(picked.saturation, closeTo(0.75, 0.02));
    expect(picked.value, closeTo(0.75, 0.02));
    // The hue is the bar's business, not the square's.
    expect(picked.hue, closeTo(HSVColor.fromColor(violet).hue, 1));
  });

  testWidgets("dragging the square keeps picking, even where a scroll view would take the drag", (
    tester,
  ) async {
    // A screen short enough that the dialog's body really does scroll: a scroll view whose
    // content fits refuses drags outright, and the gesture would never be contested.
    tester.view.physicalSize = const Size(420, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Color? picked;
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () async =>
                  picked = await showMochiColorPicker(context, initial: violet, form: MochiModalForm.dialog),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    final before = tester.getRect(shade());
    // Downwards, which is the direction a modal's scroll view would otherwise claim. In small
    // steps on purpose: a finger crosses the drag slop (18) several moves before the pan slop
    // (36), which is exactly when the scroll view would take the gesture away from a pan.
    final gesture = await tester.startGesture(before.center);
    for (var move = 0; move < 5; move++) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.getRect(shade()), before, reason: "the dialog scrolled instead of picking");
    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    // Darker than it started, and the same hue.
    final after = HSVColor.fromColor(picked!);
    expect(after.value, lessThan(HSVColor.fromColor(violet).value));
    expect(after.hue, closeTo(HSVColor.fromColor(violet).hue, 1));
  });

  testWidgets("the hue bar turns the hue and leaves the rest alone", (tester) async {
    final seen = <Color>[];
    await tester.pumpWidget(live(seen));

    final start = HSVColor.fromColor(violet);
    final bar = tester.getRect(hue());
    // A third along the bar: 120°, which is green.
    await tester.tapAt(Offset(bar.left + bar.width / 3, bar.center.dy));
    await tester.pump();

    final picked = HSVColor.fromColor(seen.single);
    expect(picked.hue, closeTo(120, 12));
    expect(picked.saturation, closeTo(start.saturation, 0.01));
    expect(picked.value, closeTo(start.value, 0.01));
  });

  testWidgets("a colour dragged down to black remembers which hue it was", (tester) async {
    final seen = <Color>[];
    await tester.pumpWidget(live(seen));

    final box = tester.getRect(shade());
    // Off the bottom right corner: fully saturated and no brightness at all, which is black. A
    // drag rather than a press, so it lands past the edge and the clamp gives exactly black — a
    // colour a pixel short of it still has its hue written down in its own channels, and this
    // test is about the hue that no longer is.
    await tester.dragFrom(box.center, Offset(box.width, box.height));
    await tester.pump();
    expect(seen.last.toARGB32(), const Color(0xFF000000).toARGB32());

    // Back up with the keyboard, which the press left focused.
    for (var press = 0; press < 10; press++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
    }

    final back = HSVColor.fromColor(seen.last);
    expect(back.value, closeTo(0.2, 0.02));
    // Black is every hue at once: a picker holding only the Color would have come back red.
    expect(back.hue, closeTo(HSVColor.fromColor(violet).hue, 1));
  });

  testWidgets("the hex field reads the colour and takes one", (tester) async {
    final seen = <Color>[];
    await tester.pumpWidget(live(seen));

    expect(find.text("7C3AED"), findsOneWidget);

    await tester.enterText(find.text("7C3AED"), "16A34A");
    await tester.pump();
    expect(seen.single.toARGB32(), const Color(0xFF16A34A).toARGB32());

    // Half a hex is not a colour: nothing happens until it is one.
    await tester.enterText(find.byType(MochiTextField), "16A3");
    await tester.pump();
    expect(seen, hasLength(1));
  });

  testWidgets("eight digits and the opacity bar only appear with alpha on", (tester) async {
    final seen = <Color>[];
    await tester.pumpWidget(live(seen, alpha: false));

    expect(opacity(), findsNothing);

    await tester.pumpWidget(live(seen, alpha: true, start: const Color(0x807C3AED)));
    expect(opacity(), findsOneWidget);
    expect(find.text("807C3AED"), findsOneWidget);

    final bar = tester.getRect(opacity());
    await tester.tapAt(Offset(bar.right - 1, bar.center.dy));
    await tester.pump();

    expect(seen.last.a, closeTo(1, 0.01));
    // The colour under it is untouched: only its opacity was being asked about.
    expect(seen.last.toARGB32(), violet.toARGB32());
  });

  testWidgets("a swatch is one press, and the chosen one is ticked", (tester) async {
    final seen = <Color>[];
    await tester.pumpWidget(live(seen));

    final swatch = MochiColors.light.of(MochiIntent.success).base;
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is ShapeDecoration &&
            (widget.decoration as ShapeDecoration).color?.toARGB32() == swatch.toARGB32(),
      ),
    );
    await tester.pumpAndSettle();

    expect(seen.single.toARGB32(), swatch.toARGB32());
  });

  testWidgets("the default colour is one press away, and only while it is not the colour", (tester) async {
    const fallback = Color(0xFF16A34A);
    Color? picked;
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () async => picked = await showMochiColorPicker(
                context,
                initial: violet,
                defaultColor: fallback,
                form: MochiModalForm.dialog,
              ),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    final reset = find.widgetWithText(MochiButton, MochiStrings.en.reset);
    expect(tester.widget<MochiButton>(reset).enabled, isTrue);

    await tester.tap(reset);
    await tester.pumpAndSettle();

    // Pressing it puts the draft back rather than answering the modal, so the colour still has to
    // leave through the button.
    expect(find.text("16A34A"), findsOneWidget);
    expect(picked, isNull);
    expect(tester.widget<MochiButton>(reset).enabled, isFalse, reason: "nothing left to go back to");

    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    expect(picked?.toARGB32(), fallback.toARGB32());
  });

  testWidgets("without a default colour there is nothing to press", (tester) async {
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () => showMochiColorPicker(context, initial: violet, form: MochiModalForm.dialog),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(find.text(MochiStrings.en.reset), findsNothing);
  });

  testWidgets("on a phone the sheet is tall enough that nothing scrolls", (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: true,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () => showMochiColorPicker(context, initial: violet, form: MochiModalForm.sheet),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    // The sheet's own cap is half the screen; a picker asks for nine tenths, and the modal's body
    // then has nothing left to scroll through.
    // The outermost scrollable in the sheet is the modal's own body; the field inside the picker
    // brings one of its own.
    final body = tester.state<ScrollableState>(
      find.descendant(of: find.byType(MochiSheet), matching: find.byType(Scrollable)).first,
    );
    expect(body.position.maxScrollExtent, 0);
    expect(tester.getSize(find.byType(MochiSheet)).height, greaterThan(450));
    expect(find.text("OK"), findsOneWidget);
  });

  testWidgets("dismissing the modal keeps nothing", (tester) async {
    Color? picked;
    var called = false;
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: Builder(
          builder: (context) => Center(
            child: MochiButton(
              onPress: () async {
                picked = await showMochiColorPicker(context, initial: violet, form: MochiModalForm.dialog);
                called = true;
              },
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    final box = tester.getRect(shade());
    await tester.tapAt(Offset(box.left + 4, box.top + 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(picked, isNull, reason: "a modal is answered, and the draft leaves through the button");
  });

  testWidgets("a bar's track is drawn across the whole bar", (tester) async {
    await tester.pumpWidget(live([]));

    final bar = tester.getRect(hue());
    final painted = tester
        .renderObjectList<RenderBox>(find.descendant(of: hue(), matching: find.byType(CustomPaint)))
        .map((box) => box.size.width);

    // A CustomPaint with no child of its own asks for Size.zero, and a loose width gives it
    // exactly that: the knob would be standing on a bar nobody could see.
    expect(painted, contains(closeTo(bar.width, 1)));
  });

  testWidgets("a wide hue bar is one unbroken run of colour", (tester) async {
    // The painter draws a long ramp in slices, because on the Flutter master this project pins a
    // gradient longer than 256 device pixels arrives at its last colour after 65536 / length
    // pixels and is flat from there. The test harness renders with Skia, which has no such limit,
    // so what this holds is the arithmetic of the slicing: the picture has to come out the same
    // as the one gradient it replaced, with the right colour at every point and no seam where two
    // slices meet.
    const shot = Key("shot");
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        touch: false,
        home: RepaintBoundary(
          key: shot,
          child: Center(
            child: SizedBox(
              width: 600,
              child: MochiColorPicker(value: violet, onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(hue());
    // The image's own width, not the view's: `toImage` renders at a pixel ratio of 1, so it is
    // in logical pixels while `tester.view.physicalSize` is not.
    final shotData = await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(shot));
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = image.width;
      image.dispose();

      return (data!, width);
    });

    final (pixels, width) = shotData!;
    final row = bar.center.dy.round();
    Color at(int x) {
      final start = (row * width + x) * 4;
      return Color.fromARGB(
        255,
        pixels.getUint8(start),
        pixels.getUint8(start + 1),
        pixels.getUint8(start + 2),
      );
    }

    // The track is painted across the whole bar, so a point in it is that fraction of the wheel —
    // the knob's shorter travel is about where the knob sits, not about the colours underneath.
    for (final fraction in [0.1, 0.25, 0.75, 0.9]) {
      final x = (bar.left + fraction * bar.width).round();
      final wanted = HSVColor.fromAHSV(1, fraction * 360, 1, 1).toColor();
      final found = HSVColor.fromColor(at(x));
      expect(
        found.hue,
        closeTo(fraction * 360, 6),
        reason: "at ${fraction * 100}% the bar should be ${wanted.toARGB32().toRadixString(16)}",
      );
    }

    // No seam: two neighbouring pixels of a 600-wide wheel are at most a couple of steps apart.
    // Only up to the knob, which is a circle in the way rather than part of the run.
    for (var x = (bar.left + 2).round(); x < bar.left + 0.6 * bar.width; x++) {
      final step = [
        (at(x).r - at(x + 1).r).abs(),
        (at(x).g - at(x + 1).g).abs(),
        (at(x).b - at(x + 1).b).abs(),
      ].reduce((a, b) => a > b ? a : b);
      expect(step, lessThan(0.05), reason: "a slice boundary shows as a jump at x=$x");
    }
  });

  testWidgets("disabled picks nothing", (tester) async {
    final seen = <Color>[];
    await tester.pumpWidget(live(seen, enabled: false));

    final box = tester.getRect(shade());
    await tester.tapAt(box.center);
    await tester.pump();

    expect(seen, isEmpty);
  });
}
