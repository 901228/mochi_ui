import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      home: Center(child: SizedBox(width: 200, child: child)),
    ),
  );

  group("circular", () {
    testWidgets("indeterminate keeps animating, determinate does not", (tester) async {
      await tester.pumpWidget(app(const MochiCircularProgress()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(app(const MochiCircularProgress(value: 0.4)));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("takes the surrounding text color", (tester) async {
      await tester.pumpWidget(
        app(
          const DefaultTextStyle(
            style: TextStyle(color: Color(0xFF00FF00)),
            child: MochiCircularProgress(value: 0.5),
          ),
        ),
      );

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!;
      expect(painter.toString(), contains("_RingPainter"));
      expect(find.byType(MochiCircularProgress), findsOneWidget);
    });
  });

  group("linear", () {
    testWidgets("determinate bar takes the given fraction of the track", (tester) async {
      await tester.pumpWidget(app(const MochiLinearProgress(value: 0.25)));
      await tester.pumpAndSettle();

      final track = tester.getSize(find.byType(MochiLinearProgress));
      final bar = tester.getSize(find.byType(FractionallySizedBox));
      expect(bar.width, moreOrLessEquals(track.width * 0.25, epsilon: 0.01));
    });

    testWidgets("fills a loose parent so the bar has room to slide", (tester) async {
      // Regression: under loose width constraints the track used to shrink to the bar, which
      // pinned the indeterminate bar to the left edge.
      await tester.pumpWidget(
        app(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [MochiLinearProgress()])),
      );

      expect(tester.getSize(find.byType(MochiLinearProgress)).width, 200);

      // The bar is the DecoratedBox inside the FractionallySizedBox; the track is the outer one.
      Rect bar() => tester.getRect(
        find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(DecoratedBox)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final first = bar();
      await tester.pump(const Duration(milliseconds: 300));
      expect(bar().left, isNot(first.left));
    });

    testWidgets("indeterminate animates unless motion is reduced", (tester) async {
      await tester.pumpWidget(app(const MochiLinearProgress()));
      // The FractionallySizedBox fills the track; the bar inside it is what moves.
      // The bar is the DecoratedBox inside the FractionallySizedBox; the track is the outer one.
      Rect bar() => tester.getRect(
        find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(DecoratedBox)),
      );

      await tester.pump(const Duration(milliseconds: 100));
      final moving = bar();
      await tester.pump(const Duration(milliseconds: 200));
      expect(bar(), isNot(moving));

      await tester.pumpWidget(app(const MochiLinearProgress(), disableAnimations: true));
      await tester.pump(const Duration(milliseconds: 100));
      final still = bar();
      await tester.pump(const Duration(milliseconds: 200));
      expect(bar(), still);
    });
  });
}
