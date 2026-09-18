import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/size.dart";
import "../theme/theme.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";
import "tooltip.dart";
import "value_transition.dart";

/// A round × that closes or removes whatever it sits in: a toast, a badge, a panel.
///
/// Takes its colour from where it is (the ambient [IconTheme]) rather than from an intent, so the
/// same button reads right on a danger badge, inside a toast, or on the page. It stays quiet at
/// rest and only fills in under the pointer.
///
/// Screen readers hear [MochiStrings.close] unless [semanticLabel] says otherwise. There is no
/// tooltip by default: next to a badge's text it is noise, and in a toast there is no overlay for
/// one to float in.
class MochiCloseButton extends StatelessWidget {
  const MochiCloseButton({
    super.key,
    required this.onPress,
    this.size = MochiSize.md,
    this.metrics,
    this.color,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback? onPress;

  /// `xs` fits inside a badge; `md` (the default) sits beside the text of a toast or a header.
  final MochiSize size;

  /// Overrides the metrics [size] would pick.
  final MochiCloseButtonMetrics? metrics;

  /// Defaults to the ambient icon colour.
  final Color? color;

  final bool enabled;

  /// Defaults to [MochiStrings.close].
  final String? semanticLabel;

  final String? tooltip;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip;

    final button = MochiTappable(
      enabled: enabled,
      onPress: onPress,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel ?? context.theme.strings.close,
      builder: (context, states, _) =>
          _CloseSurface(size: size, metrics: metrics, color: color, states: states),
    );

    return tooltip == null ? button : MochiTooltip(message: tooltip, child: button);
  }
}

class _CloseSurface extends StatelessWidget {
  const _CloseSurface({required this.size, required this.metrics, required this.color, required this.states});

  final MochiSize size;
  final MochiCloseButtonMetrics? metrics;
  final Color? color;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = this.color ?? IconTheme.of(context).color ?? theme.colors.foreground;
    final clear = color.withValues(alpha: 0);
    final target = metrics ?? MochiCloseButtonMetrics.of(size, touch: theme.touch, density: theme.density);

    return MochiValueTransition(
      value: target,
      lerp: MochiCloseButtonMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) => Opacity(
          opacity: blend.number((st) => st.contains(WidgetState.disabled) ? 0.4 : 1),
          child: MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: theme.geometry.radius.full,
            child: Container(
              width: m.diameter,
              height: m.diameter,
              decoration: ShapeDecoration(
                color: blend.color((st) => MochiColors.stateLayer(clear, color, st)),
                shape: RoundedSuperellipseBorder(borderRadius: theme.geometry.radius.full),
              ),
              child: Icon(
                theme.icons.close,
                size: m.iconSize,
                // Quiet at rest, so it doesn't compete with what it closes.
                color: blend.color(
                  (st) => st.contains(WidgetState.hovered) || st.contains(WidgetState.pressed)
                      ? color
                      : color.withValues(alpha: color.a * 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sizes for [MochiCloseButton]: the circle and the × inside it.
@immutable
class MochiCloseButtonMetrics {
  const MochiCloseButtonMetrics({required this.diameter, required this.iconSize});

  final double diameter;
  final double iconSize;

  /// [density] scales the circle; see [MochiTheme.density].
  factory MochiCloseButtonMetrics.of(MochiSize size, {required bool touch, double density = 1}) {
    final base = _base(size, touch);
    return density == 1
        ? base
        : MochiCloseButtonMetrics(diameter: base.diameter * density, iconSize: base.iconSize);
  }

  static MochiCloseButtonMetrics _base(MochiSize size, bool touch) => switch ((size, touch)) {
    (.xs, false) => const MochiCloseButtonMetrics(diameter: 16, iconSize: 10),
    (.sm, false) => const MochiCloseButtonMetrics(diameter: 20, iconSize: 12),
    (.md, false) => const MochiCloseButtonMetrics(diameter: 28, iconSize: 14),
    (.lg, false) => const MochiCloseButtonMetrics(diameter: 32, iconSize: 16),
    (.xs, true) => const MochiCloseButtonMetrics(diameter: 20, iconSize: 12),
    (.sm, true) => const MochiCloseButtonMetrics(diameter: 24, iconSize: 14),
    (.md, true) => const MochiCloseButtonMetrics(diameter: 32, iconSize: 16),
    (.lg, true) => const MochiCloseButtonMetrics(diameter: 40, iconSize: 18),
  };

  static MochiCloseButtonMetrics lerp(MochiCloseButtonMetrics a, MochiCloseButtonMetrics b, double t) =>
      MochiCloseButtonMetrics(
        diameter: lerpDouble(a.diameter, b.diameter, t)!,
        iconSize: lerpDouble(a.iconSize, b.iconSize, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiCloseButtonMetrics && diameter == other.diameter && iconSize == other.iconSize;

  @override
  int get hashCode => Object.hash(diameter, iconSize);
}
