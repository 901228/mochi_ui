import "package:flutter/widgets.dart";

import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";

/// The box that opens a picker: a text field's look, with an icon at its end.
///
/// Shared by the date, time and date-and-time pickers, which differ in what they open and what
/// they write, not in what they look like shut.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.text,
    required this.icon,
    required this.empty,
    required this.metrics,
    this.maxLines = 1,
    required this.open,
    required this.error,
    required this.enabled,
    required this.autofocus,
    required this.onPress,
    this.focusNode,
  });

  /// What it says: the value, or the hint when there is none.
  final String text;

  /// At the end of the box: a calendar, a clock.
  final IconData icon;

  /// Whether [text] is standing in for a value rather than being one, which is what greys it.
  final bool empty;

  /// One line for a day, two for a run of them: a range that spans two years has nothing left to
  /// shorten, and a date cut off by an ellipsis says nothing at all.
  final int maxLines;

  final MochiButtonMetrics metrics;
  final bool open;
  final bool error;
  final bool enabled;
  final bool autofocus;
  final VoidCallback onPress;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final primary = colors.of(MochiIntent.primary);
    final danger = colors.of(MochiIntent.danger);
    final radius = metrics.radius(g.radius);

    return MochiTappable(
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      // A field, not a button: it tints its border rather than growing.
      scaleOnPress: false,
      onPress: onPress,
      semanticLabel: empty ? null : text,
      builder: (context, states, _) => MochiStateTransition(
        states: {...states, if (open) WidgetState.selected, if (error) WidgetState.error},
        duration: theme.motion.stateDuration,
        builder: (context, blend) => MochiFocusRing(
          visible: blend.contains(WidgetState.focused),
          radius: radius,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: colors.surface,
              shape: RoundedSuperellipseBorder(
                borderRadius: radius,
                side: BorderSide(
                  width: g.borderWidth,
                  color: blend.color(
                    (st) => switch (st) {
                      _ when st.contains(WidgetState.error) => danger.base,
                      _ when st.contains(WidgetState.selected) => primary.base,
                      _ when st.contains(WidgetState.hovered) => Color.lerp(
                        colors.border,
                        colors.mutedForeground,
                        0.5,
                      )!,
                      _ => colors.border,
                    },
                  ),
                ),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: metrics.height),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: metrics.gap / 2,
                ),
                child: Row(
                  spacing: metrics.gap,
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: metrics
                            .textStyle(theme.typography)
                            .copyWith(color: empty ? colors.mutedForeground : colors.foreground),
                      ),
                    ),
                    Icon(icon, size: metrics.iconSize, color: colors.mutedForeground),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
