import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/styles/progress_metrics.dart";
import "../theme/styles/button_style.dart";
import "../theme/size.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "circular_progress.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";
import "tappable.dart";
import "tooltip.dart";

/// A press, in every colour and weight the kit has.
///
/// Colour and weight are separate axes: [intent] says what it means and
/// [MochiButtonAppearance] says how loudly, so a destructive action is `danger` whether it is
/// solid in a dialog or a ghost in a row. [MochiButton.icon] is the square form.
///
/// A press that has to wait for something says so in place: [loading] puts a spinner over the
/// label, which stays laid out underneath so the button keeps its width. [MochiButton.async] is
/// the same thing with the waiting owned by the button.
///
/// ```dart
/// MochiButton(intent: .danger, onPress: delete, child: const Text("Delete"))
/// ```
class MochiButton extends StatefulWidget {
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
    this.scaleOnPress = true,
    this.loading = false,
    this.semanticLabel,
    this.tooltip,
  }) : _iconOnly = false,
       _run = null;

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
    this.scaleOnPress = true,
    this.loading = false,
    this.semanticLabel,
    this.tooltip,
  }) : child = icon,
       prefix = null,
       suffix = null,
       _iconOnly = true,
       _run = null;

  /// A button that runs a future and waits for it: it shows the spinner while the errand is in
  /// flight, takes no second press, and puts its label back however the future ends.
  ///
  /// The waiting lives here rather than in the app, which is what saves the `setState` either
  /// side of every `await`. Use the plain constructor with [loading] instead when something else
  /// on the page is waiting for the same errand, or when it can be started from somewhere else:
  /// then the state belongs to the app and the button only draws it.
  ///
  /// A failure is reported through [FlutterError.reportError] rather than swallowed, the same
  /// bargain `MochiRefresh` makes, and the button comes back either way.
  ///
  /// ```dart
  /// MochiButton.async(onPress: () => dao.save(draft), child: const Text("Save"))
  /// ```
  const MochiButton.async({
    super.key,
    required Future<void> Function() onPress,
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
    this.onHoverChange,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.scaleOnPress = true,
    this.semanticLabel,
    this.tooltip,
  }) : _run = onPress,
       onPress = null,
       onLongPress = null,
       onDoublePress = null,
       onSecondaryPress = null,
       onSecondaryLongPress = null,
       loading = false,
       _iconOnly = false;

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

  /// Grow while pressed. Off for a button that is really a piece of chrome — a word in a
  /// menubar, say — where the growth reads as the wrong kind of thing being pressed.
  final bool scaleOnPress;

  /// Puts a spinner where the label is and takes no press while it is there. The label stays laid
  /// out underneath it, so a button does not change width as it starts and stops waiting.
  final bool loading;

  final String? semanticLabel;

  /// Wraps the button in a [MochiTooltip] with this message.
  final String? tooltip;

  final bool _iconOnly;

  /// What [MochiButton.async] waits for. Null for every other constructor.
  final Future<void> Function()? _run;

  @override
  State<MochiButton> createState() => _MochiButtonState();
}

class _MochiButtonState extends State<MochiButton> {
  /// Only [MochiButton.async] sets this; the plain constructor is told by `loading` instead.
  bool _running = false;

  bool get _loading => widget.loading || _running;

  Future<void> _run() async {
    final run = widget._run;
    if (run == null || _running) return;

    setState(() => _running = true);
    try {
      await run();
    } catch (error, stack) {
      // Reported rather than swallowed: a button that quietly did nothing is the hardest kind of
      // failure to find.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: "mochi_ui",
          context: ErrorDescription("running a MochiButton.async press"),
        ),
      );
    } finally {
      // However it ended: the label comes back, or the button is dead for good.
      if (mounted) setState(() => _running = false);
    }
  }

  // Does not read the theme: only [_ButtonSurface] depends on it, so a theme animation
  // rebuilds the surface without rebuilding the focus/gesture/semantics wrappers.
  @override
  Widget build(BuildContext context) {
    final tooltip = widget.tooltip;

    final button = MochiTappable(
      // A button that is waiting takes no second press, but it is not disabled: it is drawn at
      // full strength with the spinner over it, since 40% opacity on a spinner reads as broken.
      enabled: widget.enabled && !_loading,
      selected: widget.selected,
      onPress: widget._run == null ? widget.onPress : _run,
      onLongPress: widget.onLongPress,
      onDoublePress: widget.onDoublePress,
      onSecondaryPress: widget.onSecondaryPress,
      onSecondaryLongPress: widget.onSecondaryLongPress,
      onHoverChange: widget.onHoverChange,
      onFocusChange: widget.onFocusChange,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      statesController: widget.statesController,
      scaleOnPress: widget.scaleOnPress,
      semanticLabel: widget.semanticLabel,
      builder: (context, states, _) => _ButtonSurface(
        intent: widget.intent,
        appearance: widget.appearance,
        style: widget.style,
        size: widget.size,
        metrics: widget.metrics,
        iconOnly: widget._iconOnly,
        loading: _loading,
        states: states,
        prefix: widget.prefix,
        suffix: widget.suffix,
        child: widget.child,
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
    required this.loading,
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
  final bool loading;
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
    final target =
        metrics ??
        MochiButtonMetrics.of(size ?? defaults.buttonSize, touch: theme.touch, density: theme.density);

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
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: m.gap,
      children: [?prefix, child, ?suffix],
    );
    // The label keeps its place while it waits — hidden, not taken out — so the button is the
    // same width before, during and after, and nothing beside it shuffles.
    final content = loading
        ? Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0, child: row),
              MochiCircularProgress(
                // A ring the size of the icons it stands among.
                metrics: MochiProgressMetrics(
                  diameter: m.iconSize,
                  strokeWidth: m.iconSize / 6,
                  thickness: m.iconSize / 6,
                ),
              ),
            ],
          )
        : row;

    return MochiStateTransition(
      states: states,
      duration: s.duration ?? theme.motion.stateDuration,
      builder: (context, blend) {
        final fg = blend.color((st) => s.foreground(colors, st));
        return Opacity(
          // Waiting is not disabled: the spinner is doing the saying, and fading it would only
          // make the button look broken.
          opacity: blend.number((st) => st.contains(WidgetState.disabled) && !loading ? 0.4 : 1),
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
                shape: theme.geometry.shape(
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
