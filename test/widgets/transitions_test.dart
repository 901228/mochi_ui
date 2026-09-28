import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  // Each page is wrapped twice (its own entry animation, plus the one that moves it aside when
  // another page covers it), so the transitions are found from the page's content outwards.
  T nearest<T extends Widget>(WidgetTester tester, String text) =>
      tester.widget<T>(find.ancestor(of: find.text(text), matching: find.byType(T)).first);

  double opacity(WidgetTester tester) => nearest<FadeTransition>(tester, "pushed").opacity.value;

  double scale(WidgetTester tester) => nearest<ScaleTransition>(tester, "pushed").scale.value;

  Widget app({bool disableAnimations = false, MochiMotion? motion}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      lightTheme: motion == null ? null : MochiTheme.light.copyWith(motion: motion),
      home: Builder(
        builder: (context) => Center(
          child: MochiButton(
            onPress: () =>
                Navigator.of(context)
                    .push(MochiPageRoute<void>(builder: (_) => const Center(child: Text("pushed")))),
            child: const Text("open"),
          ),
        ),
      ),
    ),
  );

  testWidgets("a pushed page fades and scales in, then settles", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(opacity(tester), greaterThan(0));
    expect(opacity(tester), lessThan(1));
    expect(scale(tester), inInclusiveRange(0.96, 1));

    await tester.pumpAndSettle();
    expect(find.text("pushed"), findsOneWidget);
    expect(opacity(tester), 1);
    expect(scale(tester), 1);
  });

  testWidgets("durations come from the theme", (tester) async {
    final motion = MochiMotion(
      transitionDuration: const Duration(milliseconds: 600),
      transitionReverseDuration: const Duration(milliseconds: 300),
    );
    await tester.pumpWidget(app(motion: motion));
    await tester.tap(find.text("open"));
    await tester.pump();

    // Still well inside the longer enter animation.
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets("reduced motion skips the transition widgets", (tester) async {
    await tester.pumpWidget(app(disableAnimations: true));
    await tester.tap(find.text("open"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.text("pushed"), findsOneWidget);
    expect(find.byType(ScaleTransition), findsNothing);
  });

  testWidgets("popping animates back out", (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Halfway out: still on screen, already fading and shrinking.
    expect(find.text("pushed"), findsOneWidget);
    expect(opacity(tester), lessThan(1));
    expect(scale(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(find.text("pushed"), findsNothing);
  });

  testWidgets("a slide page comes in from the side", (tester) async {
    await tester.pumpWidget(app());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MochiPageRoute<void>(
          transition: MochiTransition.slide,
          builder: (_) => const Center(child: Text("pushed")),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final offset = tester.widget<SlideTransition>(find.byType(SlideTransition).last).position.value;
    expect(offset.dx, greaterThan(0), reason: "still travelling in from the right");
    expect(offset.dy, 0);

    await tester.pumpAndSettle();
  });

  testWidgets("a slide page travels back out on pop", (tester) async {
    await tester.pumpWidget(app());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MochiPageRoute<void>(
          transition: MochiTransition.slide,
          builder: (_) => const Center(child: Text("pushed")),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Offset offset() => tester.widget<SlideTransition>(find.byType(SlideTransition).last).position.value;
    expect(offset(), Offset.zero);

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(offset().dx, greaterThan(0), reason: "travelling back out to the right");

    await tester.pumpAndSettle();
    expect(find.text("pushed"), findsNothing);
  });

  testWidgets("nothing is left behind once a page has settled", (tester) async {
    // Regression: routes are transparent, so a shadow or a dimming layer drawn at rest showed
    // through and tinted the page.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    bool hasDim() => tester.widgetList<ColoredBox>(find.byType(ColoredBox)).any((box) {
      final shadow = MochiColors.light.shadow;
      return box.color.a > 0 && box.color.a < 1 && box.color.r == shadow.r;
    });

    bool hasShadow() => tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .any(
          (box) => switch (box.decoration) {
            BoxDecoration(:final boxShadow?) => boxShadow.isNotEmpty,
            _ => false,
          },
        );

    expect(hasShadow(), isFalse, reason: "shadow at rest");
    expect(hasDim(), isFalse, reason: "dimming at rest");

    await tester.tap(find.text("open"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(hasShadow(), isTrue, reason: "shadow mid-transition");
    expect(hasDim(), isTrue, reason: "dimming mid-transition");

    await tester.pumpAndSettle();
    expect(hasShadow(), isFalse, reason: "shadow settled again");
    expect(hasDim(), isFalse, reason: "dimming settled again");
  });

  testWidgets("MochiPage builds the same route for routers", (tester) async {
    const page = MochiPage<void>(transition: MochiTransition.slide, child: Text("routed"));
    final route = page.createRoute(tester.element(find.byType(Container).first));

    expect(route, isA<MochiPageRoute<void>>());
    expect((route as MochiPageRoute<void>).transition, MochiTransition.slide);
  });

  group("defaults.transition", () {
    Widget app({MochiTransition? defaults, MochiTransition? route}) => MochiApp(
      themeMode: MochiThemeMode.light,
      lightTheme: defaults == null
          ? null
          : MochiTheme.light.copyWith(defaults: MochiDefaults(transition: defaults)),
      home: Builder(
        builder: (context) => Center(
          child: MochiButton(
            onPress: () => showMochiDialog<void>(
              context,
              transition: route,
              builder: (context) => const MochiDialog(title: Text("pushed")),
            ),
            child: const Text("open"),
          ),
        ),
      ),
    );

    /// Whether the surface is being scaled as well as faded, halfway through its entrance.
    Future<bool> scales(WidgetTester tester, Widget host) async {
      await tester.pumpWidget(host);
      await tester.tap(find.text("open"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scaled = find.ancestor(of: find.text("pushed"), matching: find.byType(ScaleTransition));
      final answer = scaled.evaluate().isNotEmpty;

      // Put it away before the next case: a standing dialog's barrier swallows the tap that
      // would open the next one, and the old panel would be measured twice.
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text("pushed"), findsNothing);

      return answer;
    }

    testWidgets("is what a dialog takes when it is not told otherwise", (tester) async {
      expect(await scales(tester, app()), isTrue, reason: "scaleFade out of the box");
      expect(await scales(tester, app(defaults: MochiTransition.fade)), isFalse);
    });

    testWidgets("gives way to the one a route was given", (tester) async {
      expect(
        await scales(tester, app(defaults: MochiTransition.fade, route: MochiTransition.scaleFade)),
        isTrue,
      );
    });
  });
}
