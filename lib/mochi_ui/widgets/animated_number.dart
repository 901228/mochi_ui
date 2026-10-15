import "package:flutter/widgets.dart";

import "value_transition.dart";

/// A number that counts to [value] rather than appearing at once.
///
/// It starts at [initial] and eases to [value]; a later change eases from wherever the number has
/// got to, so a result that arrives mid-count does not snap. A `null` or non-finite [value] shows
/// [fallback] instead, and the two cross-fade over [fadeDuration], as do two different fallbacks. The count does not fade and
/// the fallback does not count: only a change between two numbers moves.
///
/// Digits are tabular, so a count does not shuffle the line it sits on. Screen readers hear the
/// final value once, not every frame of the count.
///
/// Give it a new [Key] to count from [initial] again, for example when the session it shows
/// changes.
class MochiAnimatedNumber extends StatelessWidget {
  const MochiAnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.fallback = "--",
    this.style,
    this.initial = 0,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.fadeDuration = const Duration(milliseconds: 200),
  });

  /// What to show. Null or non-finite shows [fallback].
  final double? value;

  /// Turns the number on screen into text. Called on every frame of the count.
  final String Function(double value) format;

  /// Shown instead of a number, for a missing result. A symbol rather than a word, so it needs no
  /// translation.
  final String fallback;

  /// Merged over the ambient text style, with tabular figures added.
  final TextStyle? style;

  /// Where the count starts the first time the number is shown.
  final double initial;

  final Duration duration;
  final Curve curve;

  /// How long the cross-fade between a number and [fallback] takes.
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final number = v != null && v.isFinite;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final textStyle = (style ?? const TextStyle()).copyWith(
      fontFeatures: [...?style?.fontFeatures, const FontFeature.tabularFigures()],
    );

    return Semantics(
      label: number ? format(v) : fallback,
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : fadeDuration,
        child: number
            ? MochiValueTransition<double>(
                key: const ValueKey("number"),
                value: v,
                initial: initial,
                lerp: _lerp,
                duration: duration,
                curve: curve,
                builder: (context, n, _) => Text(format(n), style: textStyle),
              )
            : Text(fallback, key: ValueKey("fallback:$fallback"), style: textStyle),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
