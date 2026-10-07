import "package:flutter/rendering.dart";
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

  testWidgets("no surface casts its shadow off a superellipse", (tester) async {
    // A blur along an arbitrary path is redrawn whole on every frame on the web, and a raised page
    // full of them scrolled at 18 frames a second; shadows go on a `ShapeShadow` instead. Every
    // page, both layerings, so one put back on a ShapeDecoration anywhere turns up here.
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PreviewApp());
    await tester.pump(const Duration(milliseconds: 400));

    for (final layering in ["outlined", "raised"]) {
      await tester.tap(find.widgetWithText(MochiButton, layering).first);
      await tester.pump(const Duration(milliseconds: 400));
      for (final page in ["foundations", "buttons", "inputs", "navigation", "content", "dates", "overlays"]) {
        await tester.tap(find.text(page).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final offenders = [
          for (final element in find.byType(DecoratedBox, skipOffstage: false).evaluate())
            if ((element.widget as DecoratedBox).decoration case final ShapeDecoration d
                when d.shadows?.isNotEmpty ?? false)
              element.widget,
        ];
        expect(offenders, isEmpty, reason: "$layering / $page");
      }
    }
  });

  testWidgets("no page overflows at any viewport", (tester) async {
    // The gallery is where every component is laid out at once, so this is the cheapest check
    // that none of them runs off a narrow page — which is what a phone is.
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PreviewApp());
    await tester.pump(const Duration(milliseconds: 400));

    Finder knob(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is MochiButton &&
          widget.size == MochiSize.xs &&
          widget.child is Text &&
          (widget.child as Text).data == label,
    );

    for (final viewport in ["mobile", "tablet", "full"]) {
      await tester.tap(knob(viewport));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      for (final page in ["foundations", "buttons", "inputs", "navigation", "content", "dates", "overlays"]) {
        await tester.tap(find.text(page).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final over = <String>[];
        for (final element in find.byElementPredicate((e) => e.renderObject is RenderFlex).evaluate()) {
          final box = element.renderObject! as RenderFlex;
          if (!box.hasSize) continue;

          var along = 0.0;
          box.visitChildren((child) {
            if (child is! RenderBox || !child.hasSize) return;
            along += box.direction == Axis.horizontal ? child.size.width : child.size.height;
          });
          final room = box.direction == Axis.horizontal
              ? box.constraints.maxWidth
              : box.constraints.maxHeight;
          if (along > room + 0.5) {
            over.add("${element.widget.runtimeType} over by ${(along - room).toStringAsFixed(0)}");
          }
        }

        expect(over, isEmpty, reason: "$viewport · $page");
      }
    }
  });

  testWidgets("the layering knob in the look bar changes how a card is drawn", (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PreviewApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text("foundations").first);
    await tester.pump(const Duration(milliseconds: 400));

    MochiLayering? layering() => tester.element(find.byType(MochiCard).first).theme.layering;
    final before = layering();

    final other = before == MochiLayering.raised ? "outlined" : "raised";
    await tester.tap(find.widgetWithText(MochiButton, other).first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(layering(), isNot(before));
  });
}
