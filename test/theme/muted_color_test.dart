import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";
import "package:mochi_ui/mochi_ui/theme/contrast.dart";

void main() {
  // Light only: white on Latte's blue is 4.91:1, barely over the line, where the dark theme's text
  // on its fill has room for the whole step either way.
  test("on a fill with little room, a lower bar lets it move", () {
    final colors = MochiColors.light;
    final tone = colors.primary;
    final strict = colors.muted(tone.onBase, on: tone.base);
    final loose = colors.muted(tone.onBase, on: tone.base, minContrast: 3);
    expect(contrastRatio(tone.base, loose), greaterThanOrEqualTo(3));
    expect(contrastRatio(tone.base, loose), lessThan(contrastRatio(tone.base, strict)));
  });

  for (final (name, colors) in [("light", MochiColors.light), ("dark", MochiColors.dark)]) {
    group(name, () {
      test("muting the text lands next to the theme's own muted text", () {
        final muted = colors.muted(colors.foreground);
        // Within a few steps of 255 on every channel: the step was read off the palette.
        expect((muted.r - colors.mutedForeground.r).abs(), lessThan(0.04));
        expect((muted.g - colors.mutedForeground.g).abs(), lessThan(0.04));
        expect((muted.b - colors.mutedForeground.b).abs(), lessThan(0.04));
      });

      test("an intent's text is muted without falling under 4.5:1", () {
        for (final intent in MochiIntent.values) {
          final text = colors.of(intent).onSoft;
          final muted = colors.muted(text);
          expect(contrastRatio(colors.background, muted), greaterThanOrEqualTo(4.5), reason: intent.name);
          expect(muted, isNot(text), reason: "${intent.name} is quieter than it was");
        }
      });

      test("against another ground, it is that ground it moves towards and reads on", () {
        final muted = colors.muted(colors.foreground, on: colors.surface);
        expect(contrastRatio(colors.surface, muted), greaterThanOrEqualTo(4.5));
        expect(
          contrastRatio(colors.surface, muted),
          lessThan(contrastRatio(colors.surface, colors.foreground)),
        );
      });

      test("a colour already too faint to read is left alone", () {
        final faint = Color.lerp(colors.foreground, colors.background, 0.8)!;
        expect(colors.muted(faint), faint);
      });
    });
  }
}
