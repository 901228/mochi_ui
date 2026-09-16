import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";
import "tappable.dart";

/// An on/off switch. Pass a null [onChanged] (or `enabled: false`) to disable it.
class MochiSwitch extends StatelessWidget {
  const MochiSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.intent = MochiIntent.primary,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final MochiIntent intent;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return MochiTappable(
      enabled: enabled,
      selected: value,
      onPress: onChanged == null ? null : () => onChanged(!value),
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      // The thumb already moves; scaling the whole track as well reads as a wobble.
      scaleOnPress: false,
      builder: (context, states, _) => _SwitchSurface(states: states, intent: intent),
    );
  }
}

class _SwitchSurface extends StatelessWidget {
  const _SwitchSurface({required this.states, required this.intent});

  final Set<WidgetState> states;
  final MochiIntent intent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final tone = colors.of(intent);
    final touch = theme.touch;

    final target = touch ? const Size(48, 28) : const Size(40, 24);
    const inset = 3.0;
    // Off, the thumb contrasts with the neutral track and must be light in both themes (neither
    // surface nor foreground is). On, it sits on the intent color, so it uses that tone's on-color:
    // dark in the dark theme, where the accents are pastel.
    final offThumb = colors.brightness == Brightness.light ? colors.overlay : colors.foreground;

    Color thumb(Set<WidgetState> st) => st.contains(WidgetState.selected) ? tone.onBase : offThumb;

    Color track(Set<WidgetState> st) => st.contains(WidgetState.selected)
        ? MochiColors.stateLayer(tone.base, tone.onBase, st)
        : MochiColors.stateLayer(colors.border, colors.foreground, st);

    // The track's size comes from the theme, so switching scales would otherwise jump.
    return MochiValueTransition(
      value: target,
      lerp: (a, b, t) => Size.lerp(a, b, t)!,
      duration: theme.motion.sizeDuration,
      builder: (context, size, _) => _track(context, theme, colors, size, inset, thumb, track),
    );
  }

  Widget _track(
    BuildContext context,
    MochiTheme theme,
    MochiColors colors,
    Size size,
    double inset,
    Color Function(Set<WidgetState>) thumb,
    Color Function(Set<WidgetState>) track,
  ) {
    final width = size.width;
    final height = size.height;
    final thumbSize = height - inset * 2;

    return MochiStateTransition(
      states: states,
      duration: theme.motion.stateDuration,
      builder: (context, blend) => Opacity(
        opacity: blend.number((st) => st.contains(WidgetState.disabled) ? 0.4 : 1),
        child: MochiFocusRing(
          visible: blend.contains(WidgetState.focused),
          radius: BorderRadius.all(Radius.circular(height / 2)),
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.all(inset),
            decoration: ShapeDecoration(
              color: blend.color(track),
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(height / 2))),
            ),
            child: Align(
              alignment: Alignment(blend.number((st) => st.contains(WidgetState.selected) ? 1 : -1), 0),
              child: SizedBox.square(
                dimension: thumbSize,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: blend.color(thumb),
                    shadows: theme.geometry.shadows.of(.sm, colors.shadow),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.all(Radius.circular(thumbSize / 2)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
