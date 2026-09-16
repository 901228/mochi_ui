import "package:flutter/widgets.dart";

/// Motion tokens: durations and springs shared by components.
@immutable
class MochiMotion {
  MochiMotion({
    this.stateDuration = const Duration(milliseconds: 120),
    this.themeDuration = const Duration(milliseconds: 200),
    this.indeterminateDuration = const Duration(milliseconds: 1000),
    this.sizeDuration = const Duration(milliseconds: 200),
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

  /// Light / dark theme transitions.
  final Duration themeDuration;

  /// Metrics changing under a component: the touch scale switching to the desktop one, say.
  final Duration sizeDuration;

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
