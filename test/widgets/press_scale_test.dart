import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  const box = Key("box");

  Widget app({required double width, bool scaleOnPress = true, bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      home: Center(
        child: MochiTappable(
          scaleOnPress: scaleOnPress,
          onPress: () {},
          builder: (context, states, _) => SizedBox(key: box, width: width, height: 40),
        ),
      ),
    ),
  );

  Rect rect(WidgetTester tester) => tester.getRect(find.byKey(box));

  testWidgets("grows while pressed, capped by pressMaxGrowth, and settles back", (tester) async {
    await tester.pumpWidget(app(width: 300));
    final rest = rect(tester);
    final growth = MochiMotion.standard.pressMaxGrowth;

    final gesture = await tester.startGesture(rest.center);
    await tester.pump(const Duration(milliseconds: 150)); // past kPressTimeout: pressed
    await tester.pump(const Duration(milliseconds: 400)); // spring settles
    final pressed = rect(tester);
    expect(pressed.center, rest.center);
    expect(pressed.width, greaterThan(rest.width));
    expect(pressed.width - rest.width, moreOrLessEquals(2 * growth, epsilon: 0.1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(rect(tester), rectMoreOrLessEquals(rest));
  });

  testWidgets("small surfaces are capped by pressScale", (tester) async {
    await tester.pumpWidget(app(width: 20));
    final rest = rect(tester);
    final gesture = await tester.startGesture(rest.center);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 400));
    // Longest side is 40, so 2 * 3 / 40 = 0.15 exceeds pressScale - 1 = 0.06.
    expect(
      rect(tester).height / rest.height,
      moreOrLessEquals(MochiMotion.standard.pressScale, epsilon: 0.001),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets("a quick tap is still visible", (tester) async {
    await tester.pumpWidget(app(width: 300));
    final rest = rect(tester);
    await tester.tap(find.byType(MochiTappable));
    await tester.pump(); // the ticker's first frame is the animation's start (t = 0)
    await tester.pump(const Duration(milliseconds: 60));
    expect(rect(tester).width, greaterThan(rest.width));
    await tester.pumpAndSettle();
    expect(rect(tester), rectMoreOrLessEquals(rest));
  });

  testWidgets("disabled by scaleOnPress: false and by disableAnimations", (tester) async {
    for (final w in [app(width: 300, scaleOnPress: false), app(width: 300, disableAnimations: true)]) {
      await tester.pumpWidget(w);
      final rest = rect(tester);
      final gesture = await tester.startGesture(rest.center);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rect(tester), rectMoreOrLessEquals(rest));
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });
}
