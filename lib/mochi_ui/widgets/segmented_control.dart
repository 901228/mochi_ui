import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/geometry.dart";
import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";
import "value_transition.dart";

/// How a [MochiSegmentedControl] looks.
///
/// An appearance rather than two components: picking one of a few choices laid out in a row is
/// the same behaviour either way, and what changes is whether it reads as a control or as the
/// tabs of the page under it.
enum MochiSegmentedAppearance {
  /// A track with the chosen segment raised inside it, the way a control sits in a form.
  segmented,

  /// A line under the chosen segment: the tabs over a page's content.
  underline,
}

/// One choice in a [MochiSegmentedControl].
class MochiSegment<T> {
  const MochiSegment({required this.value, this.label, this.icon, this.enabled = true, this.semanticLabel})
    : assert(label != null || icon != null, "A segment needs a label, an icon, or both.");

  /// What `onChanged` is called with when this one is chosen.
  final T value;

  final Widget? label;

  /// Before the label, or on its own for an icon-only segment.
  final Widget? icon;

  final bool enabled;

  /// For an icon-only segment, which has no words of its own.
  final String? semanticLabel;
}

/// One of a few choices in a row: ao5 / ao12 / chart, list / grid, the tabs over a page.
///
/// Segments share the width equally, so the chosen one doesn't shuffle its neighbours about as it
/// moves. With [expanded] off the row is as wide as its widest segment needs, rather than filling
/// what it is given. The control is one tab stop and the arrows move the choice, as a radio group
/// does.
///
/// Switching what is *under* it is the app's own `switch`: this is the picker, not the page.
///
/// ```dart
/// MochiSegmentedControl<Average>(
///   value: average,
///   onChanged: (value) => setState(() => average = value),
///   children: const [
///     MochiSegment(value: Average.ao5, label: Text("ao5")),
///     MochiSegment(value: Average.ao12, label: Text("ao12")),
///   ],
/// )
/// ```
class MochiSegmentedControl<T> extends StatefulWidget {
  const MochiSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.appearance = MochiSegmentedAppearance.segmented,
    this.intent = MochiIntent.neutral,
    this.size = MochiSize.md,
    this.expanded = true,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The chosen segment's value.
  final T value;

  /// Null disables the whole control.
  final ValueChanged<T>? onChanged;

  final List<MochiSegment<T>> children;
  final MochiSegmentedAppearance appearance;

  /// Colours the chosen segment. Neutral is the plain control; anything else tints it.
  final MochiIntent intent;

  final MochiSize size;

  /// Fills the width it is given. Off, it is as wide as its widest segment times their number.
  final bool expanded;

  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<MochiSegmentedControl<T>> createState() => _MochiSegmentedControlState<T>();
}

class _MochiSegmentedControlState<T> extends State<MochiSegmentedControl<T>> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  bool _focusVisible = false;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  int get _index {
    final index = widget.children.indexWhere((segment) => segment.value == widget.value);
    return index < 0 ? 0 : index;
  }

  @override
  void dispose() {
    _ownFocusNode?.dispose();

    super.dispose();
  }

  void _choose(int index) {
    final segment = widget.children[index];
    if (!segment.enabled || segment.value == widget.value) return;
    widget.onChanged?.call(segment.value);
  }

  /// The arrows walk to the next segment that can be chosen, and stop at the ends.
  void _move(int direction) {
    for (var next = _index + direction; next >= 0 && next < widget.children.length; next += direction) {
      if (widget.children[next].enabled) return _choose(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = MochiButtonMetrics.of(widget.size, touch: theme.touch, density: theme.density);

    return MochiValueTransition(
      value: target,
      lerp: MochiButtonMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => _build(context, theme, m),
    );
  }

  Widget _build(BuildContext context, MochiTheme theme, MochiButtonMetrics m) {
    // Not an assert on the constructor: a const list's length can't be read at compile time.
    assert(widget.children.isNotEmpty, "A segmented control needs at least one segment.");
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(widget.intent);
    final neutral = widget.intent == MochiIntent.neutral;
    final count = widget.children.length;
    final underline = widget.appearance == MochiSegmentedAppearance.underline;
    final radius = m.radius(g.radius);
    // The track's padding and border, which the segments sit inside: a segmented control is as
    // tall as a button of the same size, all in.
    final inset = underline ? 0.0 : 3.0;
    final edge = inset + (underline ? 0.0 : g.borderWidth);

    final indicator = underline
        ? Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 2,
              decoration: ShapeDecoration(
                color: neutral ? colors.foreground : tone.base,
                shape: RoundedSuperellipseBorder(borderRadius: g.radius.full),
              ),
            ),
          )
        : Container(
            decoration: ShapeDecoration(
              // Raised out of the track, the way a chosen segment reads on iOS.
              color: neutral ? colors.overlay : colors.softOn(tone, colors.surface),
              shadows: neutral ? g.shadows.of(MochiElevation.sm, colors.shadow) : const [],
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular((radius.topLeft.x - inset).clamp(0.0, double.infinity)),
                ),
              ),
            ),
          );

    Widget segment(int index) {
      final segment = widget.children[index];
      final selected = index == _index;

      return MochiTappable(
        enabled: _enabled && segment.enabled,
        selected: selected,
        semanticLabel: segment.semanticLabel,
        // Segments stay put: the indicator is what moves.
        scaleOnPress: false,
        onPress: () => _choose(index),
        builder: (context, states, _) => MochiStateTransition(
          states: states,
          duration: theme.motion.stateDuration,
          builder: (context, blend) => Opacity(
            opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
            child: Container(
              height: m.height - 2 * edge,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: m.horizontalPadding),
              decoration: ShapeDecoration(
                // Only the hover and press layers; the chosen one is lit by the indicator behind.
                color: blend.color(
                  (st) => st.contains(WidgetState.selected)
                      ? const Color(0x00000000)
                      : MochiColors.stateLayer(colors.surface.withValues(alpha: 0), colors.foreground, st),
                ),
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular((radius.topLeft.x - inset).clamp(0.0, double.infinity)),
                  ),
                ),
              ),
              child: DefaultTextStyle(
                style: m
                    .textStyle(theme.typography)
                    .copyWith(
                      color: blend.color(
                        (st) => switch (st) {
                          _ when !st.contains(WidgetState.selected) => colors.mutedForeground,
                          _ when neutral => colors.foreground,
                          _ => tone.onSoft,
                        },
                      ),
                    ),
                child: IconTheme.merge(
                  data: IconThemeData(size: m.iconSize),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: m.gap,
                    children: [?segment.icon, ?segment.label],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final row = Stack(
      children: [
        Positioned.fill(
          // Only the indicator is rebuilt as it slides: a tick that rebuilt every segment costs
          // enough on a busy page to drop the frames the slide is made of, and what is left
          // reads as a jump.
          child: MochiValueTransition(
            value: _index.toDouble(),
            lerp: (a, b, t) => a + (b - a) * t,
            duration: theme.motion.indicatorDuration,
            curve: theme.motion.indicatorCurve,
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: MochiFocusRing(
                visible: _focusVisible,
                // Inside: a track clips, and tabs sit against whatever is under them.
                inset: true,
                radius: BorderRadius.all(
                  Radius.circular((radius.topLeft.x - inset).clamp(0.0, double.infinity)),
                ),
                child: indicator,
              ),
            ),
            builder: (context, at, child) => Align(
              // -1 is flush with the start, 1 with the end: the fraction walks between them.
              alignment: AlignmentDirectional(count == 1 ? 0 : (2 * at / (count - 1)) - 1, 0),
              child: child,
            ),
          ),
        ),
        // The control is the tab stop; a segment is reached with the arrows, not with Tab.
        ExcludeFocus(
          child: Row(children: [for (var index = 0; index < count; index++) Expanded(child: segment(index))]),
        ),
      ],
    );

    final track = Container(
      padding: EdgeInsets.all(inset),
      decoration: ShapeDecoration(
        color: underline ? null : colors.surface,
        shape: underline
            ? const RoundedSuperellipseBorder()
            : RoundedSuperellipseBorder(
                borderRadius: radius,
                side: BorderSide(color: colors.border, width: g.borderWidth),
              ),
      ),
      child: row,
    );

    return FocusableActionDetector(
      enabled: _enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (visible) => setState(() => _focusVisible = visible),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-1),
      },
      actions: {
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (intent) {
            final rtl = Directionality.of(context) == TextDirection.rtl;
            _move(rtl ? -intent.direction : intent.direction);
            return null;
          },
        ),
      },
      // Sized to its widest segment when it isn't filling the width: a flex row's intrinsic width
      // is its widest child times the number of them, which is exactly equal segments.
      child: widget.expanded ? track : IntrinsicWidth(child: track),
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.direction);

  final int direction;
}
