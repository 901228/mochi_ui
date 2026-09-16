import "package:flutter/widgets.dart";

/// Motion tokens: durations and springs shared by components.
@immutable
class MochiMotion {
  MochiMotion({
    this.stateDuration = const Duration(milliseconds: 120),
    this.themeDuration = const Duration(milliseconds: 150),
    this.indeterminateDuration = const Duration(milliseconds: 1000),
    this.sizeDuration = const Duration(milliseconds: 320),
    this.sizeCurve = Curves.easeInOutCubic,
    this.transitionDuration = const Duration(milliseconds: 320),
    this.transitionReverseDuration = const Duration(milliseconds: 240),
    this.transitionCurve = Curves.easeOutCubic,
    this.transitionReverseCurve = Curves.easeInCubic,
    this.pressScale = 1.06,
    this.pressMaxGrowth = 3,
    SpringDescription? pressSpring,
    SpringDescription? releaseSpring,
  }) : pressSpring = pressSpring ?? SpringDescription.withDurationAndBounce(duration: _press),
       releaseSpring =
           releaseSpring ?? SpringDescription.withDurationAndBounce(duration: _release, bounce: 0.4);

  static const _press = Duration(milliseconds: 220);
  static const _release = Duration(milliseconds: 480);

  /// Interaction state changes (hover, pressed, selected colors).
  final Duration stateDuration;

  /// Light / dark theme transitions. Kept short: every frame of it rebuilds every component on
  /// screen, so its cost grows with how busy the page is.
  final Duration themeDuration;

  /// Metrics changing under a component: the touch scale switching to the desktop one, say.
  ///
  /// Matches [transitionDuration] on purpose — both are app-wide movements nobody's finger is
  /// driving — but stays its own token, since the two need different curves.
  final Duration sizeDuration;

  /// Eased at both ends: a size leaving rest at full speed reads as a jolt, since nothing the
  /// user did is driving it.
  final Curve sizeCurve;

  /// Entering a page or an overlay (dialog, sheet, popover, toast).
  final Duration transitionDuration;

  /// Leaving is quicker than entering: the surface is on its way out and should not hold
  /// attention.
  final Duration transitionReverseDuration;

  final Curve transitionCurve;
  final Curve transitionReverseCurve;

  /// One cycle of an indeterminate spinner or bar. Both move at a constant speed and keep a
  /// constant size, so the two read as one family.
  final Duration indeterminateDuration;

  /// iOS-style press feedback: pressables grow while pressed, up to this scale...
  final double pressScale;

  /// ...and by at most this many logical pixels on each side, so large surfaces don't balloon.
  final double pressMaxGrowth;

  /// Spring toward the pressed scale.
  final SpringDescription pressSpring;

  /// Spring back to rest; bouncy, so the surface settles with a slight overshoot.
  final SpringDescription releaseSpring;

  static final standard = MochiMotion();

  static bool _springEquals(SpringDescription a, SpringDescription b) =>
      a.mass == b.mass && a.stiffness == b.stiffness && a.damping == b.damping;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiMotion &&
          stateDuration == other.stateDuration &&
          themeDuration == other.themeDuration &&
          indeterminateDuration == other.indeterminateDuration &&
          sizeDuration == other.sizeDuration &&
          sizeCurve == other.sizeCurve &&
          transitionDuration == other.transitionDuration &&
          transitionReverseDuration == other.transitionReverseDuration &&
          transitionCurve == other.transitionCurve &&
          transitionReverseCurve == other.transitionReverseCurve &&
          pressScale == other.pressScale &&
          pressMaxGrowth == other.pressMaxGrowth &&
          _springEquals(pressSpring, other.pressSpring) &&
          _springEquals(releaseSpring, other.releaseSpring);

  @override
  int get hashCode => Object.hash(
    stateDuration,
    themeDuration,
    indeterminateDuration,
    sizeDuration,
    sizeCurve,
    transitionDuration,
    transitionReverseDuration,
    transitionCurve,
    transitionReverseCurve,
    pressScale,
    pressMaxGrowth,
    pressSpring.stiffness,
    pressSpring.damping,
    releaseSpring.stiffness,
    releaseSpring.damping,
  );
}
