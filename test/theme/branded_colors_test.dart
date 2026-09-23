import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mochi_ui/mochi_ui.dart";

/// The WCAG ratio, written out here rather than imported: the theme's own copy is private, and a
/// test that shares the arithmetic it is checking is checking nothing.
double ratio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // A spread of hues, saturations and lightnesses: the ones a brand actually picks, plus the two
  // that are hard — a pale yellow (nothing white reads on) and a near-black navy.
  const brands = [
    Color(0xFF7C3AED), // violet
    Color(0xFF2563EB), // blue
    Color(0xFF16A34A), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFFFDE68A), // pale yellow
    Color(0xFF0B1020), // near-black navy
    Color(0xFF64748B), // slate
  ];

  group("MochiTone.from", () {
    test("text on the fill reads, whatever the fill is", () {
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.light ? MochiColors.light : MochiColors.dark;
        for (final brand in brands) {
          final tone = MochiTone.from(brand, background: theme.background, softAlpha: theme.softAlpha);
          expect(
            ratio(tone.base, tone.onBase),
            greaterThanOrEqualTo(4.5),
            reason: "$brand on ${brightness.name}",
          );
        }
      }
    });

    test("intent-coloured text reads against the page", () {
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.light ? MochiColors.light : MochiColors.dark;
        for (final brand in brands) {
          final tone = MochiTone.from(brand, background: theme.background, softAlpha: theme.softAlpha);
          expect(
            ratio(tone.onSoft, theme.background),
            greaterThanOrEqualTo(4.5),
            reason: "$brand on ${brightness.name}",
          );
        }
      }
    });

    test("the soft fill is the accent laid over the page", () {
      final tone = MochiTone.from(
        const Color(0xFF7C3AED),
        background: MochiColors.light.background,
        softAlpha: MochiColors.light.softAlpha,
      );
      expect(
        tone.soft,
        Color.alphaBlend(
          const Color(0xFF7C3AED).withValues(alpha: MochiColors.light.softAlpha),
          MochiColors.light.background,
        ),
      );
    });

    test("nothing is worked out that was given", () {
      const pink = Color(0xFFFF00FF);
      final tone = MochiTone.from(
        const Color(0xFF7C3AED),
        background: MochiColors.light.background,
        softAlpha: MochiColors.light.softAlpha,
        onBase: pink,
        soft: pink,
        onSoft: pink,
      );
      expect([tone.onBase, tone.soft, tone.onSoft], everyElement(pink));
    });

    test("a hue is kept; only its lightness moves", () {
      const brand = Color(0xFFFDE68A);
      final tone = MochiTone.from(
        brand,
        background: MochiColors.light.background,
        softAlpha: MochiColors.light.softAlpha,
      );
      expect(
        HSLColor.fromColor(tone.onSoft).hue,
        moreOrLessEquals(HSLColor.fromColor(brand).hue, epsilon: 1),
        reason: "a pale yellow that cannot be read is a darker yellow, not another colour",
      );
    });
  });

  group("MochiColors.branded", () {
    test("keeps the neutrals it was not asked about", () {
      final branded = MochiColors.branded(primary: const Color(0xFF7C3AED));
      expect(branded.background, MochiColors.light.background);
      expect(branded.surface, MochiColors.light.surface);
      expect(branded.border, MochiColors.light.border);
      expect(branded.foreground, MochiColors.light.foreground);
      expect(branded.neutral, MochiColors.light.neutral);
    });

    test("changes only the intents it was given", () {
      final branded = MochiColors.branded(primary: const Color(0xFF7C3AED));
      expect(branded.primary, isNot(MochiColors.light.primary));
      expect(branded.info, MochiColors.light.info);
      expect(branded.success, MochiColors.light.success);
      expect(branded.warning, MochiColors.light.warning);
      expect(branded.danger, MochiColors.light.danger);
    });

    test("the dark one is built on the dark theme", () {
      final branded = MochiColors.branded(brightness: Brightness.dark, primary: const Color(0xFF7C3AED));
      expect(branded.brightness, Brightness.dark);
      expect(branded.background, MochiColors.dark.background);
      expect(branded.softAlpha, MochiColors.dark.softAlpha);
    });

    test("every intent reads, in both themes", () {
      for (final brightness in Brightness.values) {
        final branded = MochiColors.branded(
          brightness: brightness,
          primary: const Color(0xFF7C3AED),
          info: const Color(0xFF0EA5E9),
          success: const Color(0xFF16A34A),
          warning: const Color(0xFFFDE68A),
          danger: const Color(0xFFEF4444),
        );

        for (final intent in MochiIntent.values) {
          final tone = branded.of(intent);
          expect(ratio(tone.base, tone.onBase), greaterThanOrEqualTo(4.5), reason: "$intent onBase");
          expect(ratio(tone.onSoft, branded.background), greaterThanOrEqualTo(4.5), reason: "$intent onSoft");
        }
      }
    });

    test("two of the same brand are the same theme", () {
      // Value equality is what keeps AnimatedMochiTheme from restarting on every rebuild.
      final one = MochiColors.branded(primary: const Color(0xFF7C3AED));
      final two = MochiColors.branded(primary: const Color(0xFF7C3AED));
      expect(one, two);
      expect(one.hashCode, two.hashCode);
    });
  });

  testWidgets("a branded theme is a theme like any other", (tester) async {
    const brand = Color(0xFF7C3AED);
    MochiColors? seen;
    await tester.pumpWidget(
      MochiApp(
        themeMode: MochiThemeMode.light,
        lightTheme: MochiTheme.light.copyWith(colors: MochiColors.branded(primary: brand)),
        home: Builder(
          builder: (context) {
            seen = context.colors;
            return MochiButton(onPress: () {}, child: const Text("Go"));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(seen!.primary.base, brand);
    expect(seen!.background, MochiColors.light.background, reason: "the page is still the kit's");
  });
}
