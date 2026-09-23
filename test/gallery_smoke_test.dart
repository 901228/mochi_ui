import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";
import "package:mochi_ui/main.dart";

void main() {
  // The gallery is the one place every component is built at once, so opening each page is the
  // cheapest check that none of them throws. It never settles — a skeleton shimmers forever — so
  // these pump by hand.
  testWidgets("every page of the gallery opens", (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PreviewApp());
    await tester.pump(const Duration(milliseconds: 400));

    for (final page in ["buttons", "inputs", "navigation", "content", "dates", "overlays", "foundations"]) {
      await tester.tap(find.text(page).first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: page);
      expect(find.text(page), findsWidgets);
    }
  });

  testWidgets("the knob bar reaches the samples that answer to it", (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PreviewApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text("buttons").first);
    await tester.pump(const Duration(milliseconds: 400));

    final solid = find.widgetWithText(MochiButton, "solid");
    final before = tester.getSize(solid).height;

    // The size knob in the bar, not a sample's own: the bar's choices are the xs ghosts.
    final lgKnob = find.byWidgetPredicate(
      (widget) =>
          widget is MochiButton &&
          widget.size == MochiSize.xs &&
          widget.child is Text &&
          (widget.child as Text).data == "lg",
    );
    expect(lgKnob, findsOneWidget);
    await tester.tap(lgKnob);
    // Twice: the first frame starts the size transition's ticker, the second finds it finished.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getSize(solid).height, greaterThan(before));
  });

  testWidgets("a narrow viewport puts the pickers in a sheet", (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PreviewApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text("dates").first);
    await tester.pump(const Duration(milliseconds: 400));

    final mobile = find.byWidgetPredicate(
      (widget) =>
          widget is MochiButton &&
          widget.size == MochiSize.xs &&
          widget.child is Text &&
          (widget.child as Text).data == "mobile",
    );
    await tester.tap(mobile);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(MochiIcons.standard.calendar).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MochiSheet), findsOneWidget, reason: "the tier is what decides, not the window");
  });
}
