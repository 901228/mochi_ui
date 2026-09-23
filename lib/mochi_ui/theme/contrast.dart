import "dart:math" as math;

import "package:flutter/widgets.dart";

/// WCAG contrast, the arithmetic behind "is this readable".
///
/// Not exported: these are here so the theme can work a colour out rather than have it handed in
/// already correct. An app asking about its own colours is asking a different question, with its
/// own answer about large text, icons and what counts as a pass.

/// The WCAG 2.x ratio between two colours, 1 (the same) to 21 (black on white).
double contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = math.max(first, second);
  final darker = math.min(first, second);

  return (lighter + 0.05) / (darker + 0.05);
}

/// Whichever of [options] stands out most against [background]. Text on a fill is a choice
/// between two inks rather than a colour to be found, so this picks instead of adjusting.
Color mostReadable(Color background, List<Color> options) => options.reduce(
  (best, option) => contrastRatio(background, option) > contrastRatio(background, best) ? option : best,
);

/// [color] moved along its own lightness until it reads against [background].
///
/// Hue and saturation are left alone: the answer to "this blue is too pale to read" is a darker
/// blue, not a different colour. Away from the background, so a light page darkens the colour and
/// a dark page lightens it. If the target cannot be reached at all — a mid-grey page has nowhere
/// far enough to go — the most readable point found is returned rather than an exception, since a
/// theme that throws at build time helps nobody.
Color readableOn(Color background, Color color, {double target = 4.5}) {
  if (contrastRatio(background, color) >= target) return color;

  final hsl = HSLColor.fromColor(color);
  // A light page pushes the colour down, a dark one pushes it up.
  final down = background.computeLuminance() > 0.35;

  var best = color;
  var bestRatio = contrastRatio(background, color);

  for (var step = 1; step <= 100; step++) {
    final lightness = (down ? hsl.lightness - step * 0.01 : hsl.lightness + step * 0.01).clamp(0.0, 1.0);
    final candidate = hsl.withLightness(lightness).toColor();
    final ratio = contrastRatio(background, candidate);

    if (ratio >= target) return candidate;
    if (ratio > bestRatio) {
      best = candidate;
      bestRatio = ratio;
    }

    if (lightness == 0 || lightness == 1) break;
  }

  return best;
}
