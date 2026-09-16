import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  Widget app(Widget child, {required bool touch, bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MochiApp(
      themeMode: MochiThemeMode.light,
      touch: touch,
      home: Center(child: SizedBox(width: 320, child: child)),
    ),
  );

  group("sizes ease between scales", () {
    testWidgets("button", (tester) async {
      Widget button() => MochiButton(onPress: () {}, child: const Text("Save"));

      await tester.pumpWidget(app(button(), touch: false));
      await tester.pumpAndSettle();
      final desktop = tester.getSize(find.byType(MochiButton)).height;

      await tester.pumpWidget(app(button(), touch: true));
      await tester.pump(); // the ticker's first frame is the animation's start
      await tester.pump(const Duration(milliseconds: 60));

      final midway = tester.getSize(find.byType(MochiButton)).height;

      await tester.pumpAndSettle();
      final touchHeight = tester.getSize(find.byType(MochiButton)).height;

      expect(touchHeight, greaterThan(desktop));
      expect(midway, greaterThan(desktop));
      expect(midway, lessThan(touchHeight));
    });

    testWidgets("tile", (tester) async {
      const tile = MochiTile(title: Text("Row"));

      await tester.pumpWidget(app(tile, touch: false));
      await tester.pumpAndSettle();
      final desktop = tester.getSize(find.byType(MochiTile)).height;

      await tester.pumpWidget(app(tile, touch: true));
      await tester.pump(); // the ticker's first frame is the animation's start
      await tester.pump(const Duration(milliseconds: 60));

      final midway = tester.getSize(find.byType(MochiTile)).height;

      await tester.pumpAndSettle();
      expect(midway, greaterThan(desktop));
      expect(midway, lessThan(tester.getSize(find.byType(MochiTile)).height));
    });

    testWidgets("switch", (tester) async {
      // Aligned, so the switch takes its natural width instead of the 320 the box forces on it.
      final toggle = Align(
        alignment: Alignment.centerLeft,
        child: MochiSwitch(value: true, onChanged: (_) {}),
      );

      await tester.pumpWidget(app(toggle, touch: false));
      await tester.pumpAndSettle();
      final desktop = tester.getSize(find.byType(MochiSwitch)).width;

      await tester.pumpWidget(app(toggle, touch: true));
      await tester.pump(); // the ticker's first frame is the animation's start
      await tester.pump(const Duration(milliseconds: 60));

      final midway = tester.getSize(find.byType(MochiSwitch)).width;

      await tester.pumpAndSettle();
      expect(midway, greaterThan(desktop));
      expect(midway, lessThan(tester.getSize(find.byType(MochiSwitch)).width));
    });
  });

  testWidgets("reduced motion switches scale immediately", (tester) async {
    Widget button() => MochiButton(onPress: () {}, child: const Text("Save"));

    await tester.pumpWidget(app(button(), touch: false, disableAnimations: true));
    await tester.pumpAndSettle();
    final desktop = tester.getSize(find.byType(MochiButton)).height;

    await tester.pumpWidget(app(button(), touch: true, disableAnimations: true));
    await tester.pump();
    expect(tester.getSize(find.byType(MochiButton)).height, greaterThan(desktop));
  });

  testWidgets("a theme color animation does not restart the size animation", (tester) async {
    // Regression guard for the rule this widget exists for: implicit Animated* widgets restart
    // whenever their target is recomputed, which happens on every frame of a theme animation.
    Widget app(MochiThemeMode mode) => MochiApp(
      themeMode: mode,
      touch: false,
      home: Center(
        child: MochiButton(onPress: () {}, child: const Text("Save")),
      ),
    );

    await tester.pumpWidget(app(MochiThemeMode.light));
    await tester.pumpAndSettle();
    final height = tester.getSize(find.byType(MochiButton)).height;

    await tester.pumpWidget(app(MochiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getSize(find.byType(MochiButton)).height, height);
  });
}
