import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

void main() {
  group("colors carry value equality", () {
    test("tones compare by color", () {
      const a = MochiTone(
        base: Color(0xFF112233),
        onBase: Color(0xFFFFFFFF),
        soft: Color(0x22112233),
        onSoft: Color(0xFF112233),
      );
      const b = MochiTone(
        base: Color(0xFF112233),
        onBase: Color(0xFFFFFFFF),
        soft: Color(0x22112233),
        onSoft: Color(0xFF112233),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(MochiTone.lerp(a, MochiColors.dark.primary, 0.5)));
    });

    test("a blend that arrives where it started equals its target", () {
      // What lets the theme animation tell "nothing to interpolate" apart from a real change.
      // Only the ends are exact: `Color.lerp` drifts by a float somewhere in between.
      expect(MochiColors.lerp(MochiColors.light, MochiColors.light, 0), MochiColors.light);
      expect(MochiColors.lerp(MochiColors.light, MochiColors.dark, 1), MochiColors.dark);
      expect(MochiColors.lerp(MochiColors.light, MochiColors.dark, 0.5), isNot(MochiColors.dark));
    });

    test("themes differing only in scale interpolate to nothing", () {
      final desktop = MochiTheme.light.copyWith(touch: false);
      final touch = MochiTheme.light.copyWith(touch: true);

      expect(MochiTheme.lerp(desktop, touch, 0), touch);
      expect(MochiTheme.lerp(MochiTheme.light, MochiTheme.dark, 0), isNot(MochiTheme.dark));
    });
  });

  testWidgets("a scale change does not start a theme animation", (tester) async {
    // A theme animation rebuilds the whole app on every frame. Doing that for 200ms to paint the
    // exact same colors dropped the frame rate hard enough to be visible on a busy page.
    Widget app({required bool touch, MochiThemeMode mode = MochiThemeMode.light}) => MochiApp(
      themeMode: mode,
      touch: touch,
      home: const Center(child: Text("x")),
    );

    await tester.pumpWidget(app(touch: false));
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(touch: true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0, reason: "nothing to interpolate");

    await tester.pumpWidget(app(touch: true, mode: MochiThemeMode.dark));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 1, reason: "colors still animate");

    await tester.pumpAndSettle();
  });
}
