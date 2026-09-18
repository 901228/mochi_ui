import "dart:math" as math;

import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/typography.dart";
import "divider.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";

/// A header that shows and hides the [child] under it.
///
/// The building block for a collapsible [MochiCard], an accordion and a sidebar's groups, so
/// they all open alike: the body grows over `motion.sizeDuration` along `motion.sizeCurve` (a
/// size that nothing is dragging wants to ease at both ends), and the chevron turns with it.
///
/// Uncontrolled by default, starting from [initiallyExpanded]. Pass [expanded] to own the state
/// instead: a press then only calls [onExpandedChanged], and the widget follows whatever it is
/// rebuilt with — which is how an accordion keeps only one open.
class MochiCollapsible extends StatefulWidget {
  const MochiCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.enabled = true,
    this.maintainState = false,
    this.headerPadding = EdgeInsets.zero,
    this.bodyPadding = EdgeInsets.zero,
    this.radius = BorderRadius.zero,
    this.divider = false,
  });

  /// The header's label. Styled as a heading; the chevron is added after it.
  final Widget title;

  /// The body.
  final Widget child;

  /// Owns the state when non-null. See the class docs.
  final bool? expanded;

  /// Where an uncontrolled collapsible starts.
  final bool initiallyExpanded;

  final ValueChanged<bool>? onExpandedChanged;

  final bool enabled;

  /// Keep the body built while it is closed, so its state (a scroll position, a half-filled
  /// field) survives. Off by default: a closed body costs nothing.
  final bool maintainState;

  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry bodyPadding;

  /// The corners of whatever the collapsible fills, so the header's hover fill and focus ring
  /// follow them: all four while closed, the top two while open.
  final BorderRadius radius;

  /// A rule between the header and the open body, which opens and closes with it.
  ///
  /// Wants a full [bodyPadding] on top. Without one, whatever holds the collapsible has to leave
  /// the gap below the header, and the header's hover fill runs right up to the content.
  final bool divider;

  @override
  State<MochiCollapsible> createState() => _MochiCollapsibleState();
}

class _MochiCollapsibleState extends State<MochiCollapsible> with SingleTickerProviderStateMixin {
  late bool _open = widget.expanded ?? widget.initiallyExpanded;

  late final _controller = AnimationController(vsync: this, value: _open ? 1 : 0);
  // The curve is set from the theme on every build.
  late final _progress = CurvedAnimation(parent: _controller, curve: Curves.linear);

  @override
  void didUpdateWidget(MochiCollapsible old) {
    super.didUpdateWidget(old);

    // No setState: a build follows didUpdateWidget anyway.
    if (widget.expanded case final expanded? when expanded != _open) _animateTo(_open = expanded);
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();

    super.dispose();
  }

  void _toggle() {
    final next = !_open;
    widget.onExpandedChanged?.call(next);
    // A controlled collapsible waits to be rebuilt with the new value.
    if (widget.expanded == null) {
      setState(() => _open = next);
      _animateTo(next);
    }
  }

  void _animateTo(bool open) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = open ? 1 : 0;
    } else if (open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.theme.motion;
    _controller.duration = motion.sizeDuration;
    _progress.curve = motion.sizeCurve;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _open,
          child: MochiTappable(
            enabled: widget.enabled,
            onPress: _toggle,
            // A header is a row, not a button: it tints rather than grows.
            scaleOnPress: false,
            builder: (context, states, _) => _Header(
              states: states,
              enabled: widget.enabled,
              turns: _progress,
              padding: widget.headerPadding,
              radius: widget.radius,
              open: _open,
              title: widget.title,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _progress,
          builder: (context, body) {
            final t = _progress.value;
            final closed = t == 0 && !_open;
            if (closed && !widget.maintainState) return const SizedBox.shrink();
            // The same tree open or closed, so a kept body's state survives.
            return Offstage(
              offstage: closed,
              // Align rather than SizeTransition, which would also clip the body's own shadows and
              // focus rings sideways; the ClipRect only needs to cut along the axis that grows.
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  heightFactor: t,
                  child: Opacity(opacity: t, child: body),
                ),
              ),
            );
          },
          // A closing body keeps its content but can no longer be reached with Tab.
          child: ExcludeFocus(
            excluding: !_open,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.divider) const MochiDivider(),
                Padding(padding: widget.bodyPadding, child: widget.child),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.states,
    required this.enabled,
    required this.turns,
    required this.padding,
    required this.radius,
    required this.open,
    required this.title,
  });

  final Set<WidgetState> states;
  final bool enabled;
  final Animation<double> turns;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final bool open;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final clear = colors.foreground.withValues(alpha: 0);

    return MochiStateTransition(
      states: states,
      duration: theme.motion.stateDuration,
      builder: (context, blend) => MochiFocusRing(
        visible: blend.contains(WidgetState.focused),
        radius: open ? BorderRadius.only(topLeft: radius.topLeft, topRight: radius.topRight) : radius,
        // Whatever holds a collapsible usually clips it, so the ring stays inside.
        inset: true,
        child: Stack(
          children: [
            // While open, the fill's bottom meets the body and has to be square. Rather than a shape
            // with only its top corners rounded, which not every renderer draws square at the
            // bottom, the same all-round shape runs on past the header and the Stack's own clip
            // cuts it off there.
            Positioned.fill(
              bottom: open ? -math.max(radius.bottomLeft.y, radius.bottomRight.y) : 0,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: blend.color((st) => MochiColors.stateLayer(clear, colors.foreground, st)),
                  shape: RoundedSuperellipseBorder(borderRadius: radius),
                ),
              ),
            ),
            Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Padding(
                padding: padding,
                child: Row(
                  spacing: theme.geometry.space.sm,
                  children: [
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: theme.typography.body.sm.withWeight(FontWeight.w600),
                        child: title,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: turns,
                      builder: (context, icon) => Transform.rotate(angle: turns.value * math.pi, child: icon),
                      child: Icon(theme.icons.chevronDown, size: 16, color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
