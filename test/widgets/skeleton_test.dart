import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  /// [loose] leaves the skeleton to size itself; without it the 200-wide box is a tight width,
  /// which any width of its own would be measured against rather than kept.
  Widget app(Widget child, {bool animations = true, bool loose = false}) => MochiApp(
    themeMode: MochiThemeMode.light,
    touch: false,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: !animations),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 200,
            child: loose ? Align(alignment: AlignmentDirectional.topStart, child: child) : child,
          ),
        ),
      ),
    ),
  );

  /// The app's own route brings a FadeTransition of its own, so every finder here is scoped.
  Finder inSkeleton(Finder matching) => find.descendant(of: find.byType(MochiSkeleton), matching: matching);

  // A skeleton repeats forever, so pumpAndSettle would never return: every test here pumps a
  // frame at a time.

  testWidgets("a block stands at the size it is given", (tester) async {
    await tester.pumpWidget(app(const MochiSkeleton(width: 120, height: 80), loose: true));
    await tester.pump();
    expect(tester.getSize(find.byType(MochiSkeleton)), const Size(120, 80));
  });

  testWidgets("no width fills what it is given", (tester) async {
    await tester.pumpWidget(app(const MochiSkeleton(height: 12)));
    await tester.pump();
    expect(tester.getSize(find.byType(MochiSkeleton)), const Size(200, 12));
  });

  testWidgets("a circle is as wide as it is tall", (tester) async {
    await tester.pumpWidget(app(const MochiSkeleton.circle(size: 40), loose: true));
    await tester.pump();
    expect(tester.getSize(find.byType(MochiSkeleton)), const Size(40, 40));
  });

  testWidgets("a paragraph is one bar per line, and the last one is short", (tester) async {
    await tester.pumpWidget(app(const MochiSkeleton.text(lines: 3)));
    await tester.pump();

    final bars = find.descendant(of: find.byType(MochiSkeleton), matching: find.byType(DecoratedBox));
    expect(bars, findsNWidgets(3));

    final widths = [for (var i = 0; i < 3; i++) tester.getSize(bars.at(i)).width];
    expect(widths[0], widths[1], reason: "the lines in the middle run the full width");
    expect(widths.last, lessThan(widths.first), reason: "a last line is a part of one");
  });

  testWidgets("one line is a full line", (tester) async {
    await tester.pumpWidget(app(const MochiSkeleton.text(lines: 1)));
    await tester.pump();

    final bar = find.descendant(of: find.byType(MochiSkeleton), matching: find.byType(DecoratedBox));
    expect(tester.getSize(bar).width, 200, reason: "nothing came before it to be a part of");
  });

  testWidgets("skeletons built a frame apart are at the same point in the cycle", (tester) async {
    // Read through a pulse, whose opacity is on the widget: the phase itself is private, and a
    // column of skeletons that were each started when they happened to be built is exactly what
    // this is here to prevent.
    const one = MochiSkeleton(width: 100, height: 20, effect: MochiSkeletonEffect.pulse);
    // The first one keeps its place in the column, and so its state and its running clock; the
    // second arrives 137ms into the first one's cycle.
    await tester.pumpWidget(app(const Column(children: [one])));
    await tester.pump(const Duration(milliseconds: 137));

    await tester.pumpWidget(
      app(
        const Column(
          children: [
            one,
            MochiSkeleton(width: 100, height: 20, effect: .pulse),
          ],
        ),
      ),
    );
    await tester.pump();

    final fades = tester.widgetList<FadeTransition>(inSkeleton(find.byType(FadeTransition))).toList();
    expect(fades.length, 2);
    expect(fades.first.opacity.value, moreOrLessEquals(fades.last.opacity.value, epsilon: 0.02));
  });

  testWidgets("nothing moves when animations are off", (tester) async {
    await tester.pumpWidget(app(const MochiSkeleton(width: 100, height: 20), animations: false));
    // It settles at all, which a repeating animation never would.
    await tester.pumpAndSettle();
    expect(find.byType(MochiSkeleton), findsOneWidget);
  });

  testWidgets("an effect of none is still a block", (tester) async {
    await tester.pumpWidget(
      app(const MochiSkeleton(width: 100, height: 20, effect: MochiSkeletonEffect.none)),
    );
    await tester.pumpAndSettle();
    expect(inSkeleton(find.byType(ShaderMask)), findsNothing);
  });

  testWidgets("a pulse fades the block rather than sliding a highlight over it", (tester) async {
    await tester.pumpWidget(
      app(const MochiSkeleton(width: 100, height: 20, effect: MochiSkeletonEffect.pulse)),
    );
    await tester.pump();
    expect(inSkeleton(find.byType(FadeTransition)), findsOneWidget);
    expect(inSkeleton(find.byType(ShaderMask)), findsNothing);
  });
}
