import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/styles/button_style.dart";
import "../theme/size.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";
import "tappable.dart";
import "tooltip.dart";

class MochiButton extends StatelessWidget {
  const MochiButton({
    super.key,
    required this.onPress,
    required this.child,
    this.prefix,
    this.suffix,
    this.intent,
    this.appearance,
    this.size,
    this.style,
    this.metrics,
    this.enabled = true,
    this.selected = false,
    this.onLongPress,
    this.onDoublePress,
    this.onSecondaryPress,
    this.onSecondaryLongPress,
    this.onHoverChange,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.semanticLabel,
    this.tooltip,
  }) : _iconOnly = false;

  /// A square button containing only [icon].
  ///
  /// Icon-only buttons have no visible label; set [tooltip] or [semanticLabel] so they
  /// can be identified.
  const MochiButton.icon({
    super.key,
    required this.onPress,
    required Widget icon,
    this.intent,
    this.appearance,
    this.size,
    this.style,
    this.metrics,
    this.enabled = true,
    this.selected = false,
    this.onLongPress,
    this.onDoublePress,
    this.onSecondaryPress,
    this.onSecondaryLongPress,
    this.onHoverChange,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.semanticLabel,
    this.tooltip,
  }) : child = icon,
       prefix = null,
       suffix = null,
       _iconOnly = true;

  final Widget child;
  final Widget? prefix;
  final Widget? suffix;

  /// Defaults to [MochiDefaults.buttonIntent].
  final MochiIntent? intent;

  /// Defaults to [MochiDefaults.buttonAppearance], or [MochiDefaults.iconButtonAppearance]
  /// for [MochiButton.icon].
  final MochiButtonAppearance? appearance;

  /// Defaults to [MochiDefaults.buttonSize].
  final MochiSize? size;

  /// Overrides the colors derived from [intent] and [appearance].
  final MochiButtonStyle? style;

  /// Overrides the layout derived from [size] and [MochiTheme.touch].
  final MochiButtonMetrics? metrics;

  /// See [MochiTappable.enabled].
  final bool enabled;
  final bool selected;

  final VoidCallback? onPress;
  final VoidCallback? onLongPress;

  /// See [MochiTappable.onDoublePress]: setting this delays [onPress].
  final VoidCallback? onDoublePress;
  final VoidCallback? onSecondaryPress;
  final VoidCallback? onSecondaryLongPress;
  final ValueChanged<bool>? onHoverChange;
  final ValueChanged<bool>? onFocusChange;

  final FocusNode? focusNode;
  final bool autofocus;
  final WidgetStatesController? statesController;
  final String? semanticLabel;

  /// Wraps the button in a [MochiTooltip] with this message.
  final String? tooltip;

  final bool _iconOnly;

  // Does not read the theme: only [_ButtonSurface] depends on it, so a theme animation
  // rebuilds the surface without rebuilding the focus/gesture/semantics wrappers.
  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip;

    final button = MochiTappable(
      enabled: enabled,
      selected: selected,
      onPress: onPress,
      onLongPress: onLongPress,
      onDoublePress: onDoublePress,
      onSecondaryPress: onSecondaryPress,
      onSecondaryLongPress: onSecondaryLongPress,
      onHoverChange: onHoverChange,
      onFocusChange: onFocusChange,
      focusNode: focusNode,
      autofocus: autofocus,
      statesController: statesController,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => _ButtonSurface(
        intent: intent,
        appearance: appearance,
        style: style,
        size: size,
        metrics: metrics,
        iconOnly: _iconOnly,
        states: states,
        prefix: prefix,
        suffix: suffix,
        child: child,
      ),
    );

    return tooltip == null ? button : MochiTooltip(message: tooltip, child: button);
  }
}

class _ButtonSurface extends StatelessWidget {
  const _ButtonSurface({
    required this.intent,
    required this.appearance,
    required this.style,
    required this.size,
    required this.metrics,
    required this.iconOnly,
    required this.states,
    required this.prefix,
    required this.suffix,
    required this.child,
  });

  final MochiIntent? intent;
  final MochiButtonAppearance? appearance;
  final MochiButtonStyle? style;
  final MochiSize? size;
  final MochiButtonMetrics? metrics;
  final bool iconOnly;
  final Set<WidgetState> states;
  final Widget? prefix;
  final Widget? suffix;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final defaults = theme.defaults;
    final appearance =
        this.appearance ?? (iconOnly ? defaults.iconButtonAppearance : defaults.buttonAppearance);
    final s = style ?? MochiButtonStyle.of(intent ?? defaults.buttonIntent, appearance);
    final target = metrics ?? MochiButtonMetrics.of(size ?? defaults.buttonSize, touch: theme.touch);

    // Sizes come from the theme, so switching scales would otherwise jump.
    return MochiValueTransition(
      value: target,
      lerp: MochiButtonMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => _surface(context, theme, colors, s, m),
    );
  }

  Widget _surface(
    BuildContext context,
    MochiTheme theme,
    MochiColors colors,
    MochiButtonStyle s,
    MochiButtonMetrics m,
  ) {
    final label = m.textStyle(theme.typography).withWeight(FontWeight.w600);
    final radius = m.radius(theme.geometry.radius);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: m.gap,
      children: [?prefix, child, ?suffix],
    );

    return MochiStateTransition(
      states: states,
      duration: s.duration ?? theme.motion.stateDuration,
      builder: (context, blend) {
        final fg = blend.color((st) => s.foreground(colors, st));
        return Opacity(
          opacity: blend.number((st) => st.contains(WidgetState.disabled) ? 0.4 : 1),
          child: MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: radius,
            child: Container(
              constraints: BoxConstraints(minHeight: m.height, minWidth: iconOnly ? m.height : 0),
              // No `alignment`: it would make the button expand to fill its parent. The min
              // constraints reach the Row, which centers its children on both axes.
              padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : m.horizontalPadding),
              decoration: ShapeDecoration(
                color: blend.color((st) => s.background(colors, st)),
                shape: RoundedSuperellipseBorder(
                  borderRadius: radius,
                  side: BorderSide(
                    color: blend.color((st) => s.border(colors, st)),
                    width: theme.geometry.borderWidth,
                  ),
                ),
              ),
              child: DefaultTextStyle(
                style: label.copyWith(
                  color: fg,
                  decoration: s.underline(blend.to) ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: fg,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: fg, size: m.iconSize),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
