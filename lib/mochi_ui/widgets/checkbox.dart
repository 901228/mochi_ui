import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";
import "value_transition.dart";

/// A box that is checked or not — or, with [tristate], partly checked (null).
///
/// Give it a [label] and the label is part of the target: pressing the words toggles it too, the
/// way a form's checkbox should. A [description] sits under the label in muted text.
class MochiCheckbox extends StatelessWidget {
  const MochiCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.intent = MochiIntent.primary,
    this.label,
    this.description,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(tristate || value != null, "Only a tristate checkbox can be partly checked.");

  /// Null is partly checked, and only allowed with [tristate].
  final bool? value;

  /// Called with the next value: unchecked → checked → (partly checked, with [tristate]) →
  /// unchecked. Null disables the checkbox.
  final ValueChanged<bool?>? onChanged;

  final bool tristate;
  final MochiIntent intent;
  final Widget? label;
  final Widget? description;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  bool? get _next => switch (value) {
    false => true,
    true => tristate ? null : false,
    null => false,
  };

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return Semantics(
      checked: value ?? false,
      mixed: tristate && value == null,
      child: MochiTappable(
        enabled: enabled,
        selected: value != false,
        onPress: onChanged == null ? null : () => onChanged(_next),
        focusNode: focusNode,
        autofocus: autofocus,
        semanticLabel: semanticLabel,
        // The mark drawing in is the feedback; a growing row of text would be noise.
        scaleOnPress: false,
        builder: (context, states, _) => _CheckboxSurface(
          states: states,
          value: value,
          intent: intent,
          label: label,
          description: description,
        ),
      ),
    );
  }
}

class _CheckboxSurface extends StatelessWidget {
  const _CheckboxSurface({
    required this.states,
    required this.value,
    required this.intent,
    required this.label,
    required this.description,
  });

  final Set<WidgetState> states;
  final bool? value;
  final MochiIntent intent;
  final Widget? label;
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // The box's size comes from the theme, so switching scales would otherwise jump.
    return MochiValueTransition(
      value: theme.touch ? 20.0 : 16.0,
      lerp: (a, b, t) => lerpDouble(a, b, t)!,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, size, _) => _build(context, theme, size),
    );
  }

  Widget _build(BuildContext context, MochiTheme theme, double size) {
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final radius = g.radius.xs;

    Color fill(Set<WidgetState> st) => st.contains(WidgetState.selected)
        ? MochiColors.stateLayer(tone.base, tone.onBase, st)
        : MochiColors.stateLayer(colors.surface, colors.foreground, st);

    Color border(Set<WidgetState> st) => switch (st) {
      _ when st.contains(WidgetState.selected) => tone.base.withValues(alpha: 0),
      _ when st.contains(WidgetState.hovered) => Color.lerp(colors.border, colors.mutedForeground, 0.5)!,
      _ => colors.border,
    };

    return MochiStateTransition(
      states: states,
      duration: theme.motion.stateDuration,
      builder: (context, blend) {
        final checked = blend.number((st) => st.contains(WidgetState.selected) ? 1 : 0);
        final box = MochiFocusRing(
          visible: blend.contains(WidgetState.focused),
          radius: radius,
          child: Container(
            width: size,
            height: size,
            decoration: ShapeDecoration(
              color: blend.color(fill),
              shape: g.shape(
                borderRadius: radius,
                side: BorderSide(color: blend.color(border), width: g.borderWidth),
              ),
            ),
            // The mark grows and fades in with the fill rather than popping.
            child: Opacity(
              opacity: checked,
              child: Transform.scale(
                scale: 0.5 + 0.5 * checked,
                child: Icon(
                  value == null ? theme.icons.minus : theme.icons.check,
                  size: size * 0.75,
                  color: tone.onBase,
                ),
              ),
            ),
          ),
        );

        final label = this.label;
        final description = this.description;
        final content = label == null
            ? box
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: g.space.xs,
                children: [
                  // Centred on the label's first line rather than on the whole block.
                  SizedBox(
                    height: _lineHeight(theme),
                    child: Center(child: box),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: g.space.xs3,
                      children: [
                        DefaultTextStyle.merge(
                          style: theme.typography.body.sm.copyWith(color: colors.foreground),
                          child: label,
                        ),
                        if (description != null)
                          DefaultTextStyle.merge(
                            style: theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                            child: description,
                          ),
                      ],
                    ),
                  ),
                ],
              );

        return Opacity(
          opacity: blend.number((st) => st.contains(WidgetState.disabled) ? 0.4 : 1),
          child: content,
        );
      },
    );
  }

  static double _lineHeight(MochiTheme theme) {
    final style = theme.typography.body.sm;
    return (style.fontSize ?? 14) * (style.height ?? 1.4);
  }
}
