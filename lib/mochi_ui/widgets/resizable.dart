import "dart:math" as math;

import "package:flutter/gestures.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "../theme/tone.dart";
import "focus_ring.dart";
import "state_transition.dart";

/// One pane of a [MochiResizable].
@immutable
class MochiResizablePane {
  const MochiResizablePane({required this.child, this.initialFraction, this.minSize = 80, this.maxSize})
    : assert(minSize >= 0),
      assert(initialFraction == null || (initialFraction > 0 && initialFraction <= 1));

  final Widget child;

  /// How much of the whole this pane starts with. Panes left without one share what is left.
  final double? initialFraction;

  /// How small the pane may be dragged, in pixels. A pane that can be dragged shut is a pane
  /// somebody loses.
  final double minSize;

  final double? maxSize;
}

/// Panes with a line between them that can be dragged to give one what the other gives up.
///
/// The sizes are kept as fractions of the whole, so the split survives the window being resized
/// rather than one pane taking every new pixel. Each handle is its own tab stop, and the arrow
/// keys move it, since a split that can only be set by dragging cannot be set at all by someone
/// who is not holding a mouse.
///
/// ```dart
/// MochiResizable(
///   panes: [
///     MochiResizablePane(initialFraction: 0.3, minSize: 180, child: sidebar),
///     MochiResizablePane(child: editor),
///   ],
/// )
/// ```
class MochiResizable extends StatefulWidget {
  const MochiResizable({
    super.key,
    required this.panes,
    this.axis = Axis.horizontal,
    this.onChanged,
    this.handleExtent,
    this.keyboardStep = 16,
  }) : assert(panes.length >= 2, "A split needs two sides.");

  final List<MochiResizablePane> panes;

  /// Which way the panes are laid out; the handles run across it.
  final Axis axis;

  /// The fractions after every change, in case the app wants to remember them.
  final void Function(List<double> fractions)? onChanged;

  /// How much room a handle takes between two panes. Defaults to 8, or 16 on touch, where the
  /// line has to be caught by a finger.
  final double? handleExtent;

  /// How far one arrow key press moves a handle.
  final double keyboardStep;

  @override
  State<MochiResizable> createState() => _MochiResizableState();
}

class _MochiResizableState extends State<MochiResizable> {
  late List<double> _fractions = _initial();

  List<double> _initial() {
    final given = [for (final pane in widget.panes) pane.initialFraction];
    final spoken = given.whereType<double>().fold(0.0, (sum, f) => sum + f);
    final silent = given.where((f) => f == null).length;

    if (silent == 0) return [for (final f in given) f! / spoken];

    // What is left over, shared out between the panes that didn't ask for a share.
    final each = math.max(0.0, 1 - spoken) / silent;
    return [for (final f in given) f ?? each];
  }

  @override
  void didUpdateWidget(MochiResizable old) {
    super.didUpdateWidget(old);

    // A different set of panes is a different split; the same set keeps whatever it was dragged
    // to, which is the whole point of dragging it.
    if (widget.panes.length != old.panes.length) _fractions = _initial();
  }

  void _move(int handle, double delta, double content) {
    if (content <= 0 || delta == 0) return;

    final sizes = [for (final fraction in _fractions) fraction * content];
    final (before, after) = (handle, handle + 1);
    final first = widget.panes[before];
    final second = widget.panes[after];

    // The handle gives one pane exactly what it takes from the other, so nothing else on the
    // row moves: what limits it is whichever of the two runs out of room first.
    final lower = math.max(first.minSize - sizes[before], sizes[after] - (second.maxSize ?? double.infinity));
    final upper = math.min((first.maxSize ?? double.infinity) - sizes[before], sizes[after] - second.minSize);
    if (lower > upper) return;

    final step = delta.clamp(lower, upper);
    if (step == 0) return;

    sizes[before] += step;
    sizes[after] -= step;

    setState(() => _fractions = [for (final size in sizes) size / content]);
    widget.onChanged?.call(List.unmodifiable(_fractions));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final extent = widget.handleExtent ?? (theme.touch ? 16.0 : 8.0);
    final handles = widget.panes.length - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final whole = widget.axis == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
        assert(whole.isFinite, "A MochiResizable needs a bounded size along its axis.");

        // The handles are not part of what the fractions divide, so a pane's share is the same
        // whatever the handles measure.
        final content = math.max(0.0, whole - extent * handles);
        final sizes = [for (final fraction in _fractions) fraction * content];

        final children = <Widget>[];
        for (var i = 0; i < widget.panes.length; i++) {
          children.add(
            SizedBox(
              width: widget.axis == Axis.horizontal ? sizes[i] : null,
              height: widget.axis == Axis.vertical ? sizes[i] : null,
              child: widget.panes[i].child,
            ),
          );

          if (i < handles) {
            children.add(
              _Handle(
                axis: widget.axis,
                extent: extent,
                step: widget.keyboardStep,
                onMove: (delta) => _move(i, delta, content),
              ),
            );
          }
        }

        return widget.axis == Axis.horizontal
            ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
      },
    );
  }
}

/// The line between two panes: a drag, a cursor that says so, and a tab stop with arrow keys.
class _Handle extends StatefulWidget {
  const _Handle({required this.axis, required this.extent, required this.step, required this.onMove});

  final Axis axis;
  final double extent;
  final double step;
  final ValueChanged<double> onMove;

  @override
  State<_Handle> createState() => _HandleState();
}

class _HandleState extends State<_Handle> {
  final _states = <WidgetState>{};

  bool get _horizontal => widget.axis == Axis.horizontal;

  void _set(WidgetState state, bool on) => setState(() => on ? _states.add(state) : _states.remove(state));

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final back = _horizontal ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowUp;
    final on = _horizontal ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowDown;

    if (event.logicalKey == back) {
      widget.onMove(-widget.step);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == on) {
      widget.onMove(widget.step);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final primary = colors.of(MochiIntent.primary);

    return Focus(
      onFocusChange: (focused) => _set(WidgetState.focused, focused),
      onKeyEvent: _onKey,
      child: MouseRegion(
        cursor: _horizontal ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
        onEnter: (_) => _set(WidgetState.hovered, true),
        onExit: (_) => _set(WidgetState.hovered, false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _horizontal ? (_) => _set(WidgetState.dragged, true) : null,
          onHorizontalDragUpdate: _horizontal ? (details) => widget.onMove(details.delta.dx) : null,
          onHorizontalDragEnd: _horizontal ? (_) => _set(WidgetState.dragged, false) : null,
          onHorizontalDragCancel: _horizontal ? () => _set(WidgetState.dragged, false) : null,
          onVerticalDragStart: _horizontal ? null : (_) => _set(WidgetState.dragged, true),
          onVerticalDragUpdate: _horizontal ? null : (details) => widget.onMove(details.delta.dy),
          onVerticalDragEnd: _horizontal ? null : (_) => _set(WidgetState.dragged, false),
          onVerticalDragCancel: _horizontal ? null : () => _set(WidgetState.dragged, false),
          child: SizedBox(
            width: _horizontal ? widget.extent : null,
            height: _horizontal ? null : widget.extent,
            child: MochiStateTransition(
              states: _states,
              duration: theme.motion.stateDuration,
              builder: (context, blend) => MochiFocusRing(
                visible: blend.contains(WidgetState.focused),
                // Inside: the handle is a line between two panes, with nothing outside it to
                // paint on.
                inset: true,
                radius: theme.geometry.radius.full,
                child: Center(
                  child: Container(
                    width: _horizontal ? theme.geometry.borderWidth : double.infinity,
                    height: _horizontal ? double.infinity : theme.geometry.borderWidth,
                    decoration: ShapeDecoration(
                      color: blend.color(
                        (states) => switch (states) {
                          _ when states.contains(WidgetState.dragged) => primary.base,
                          _ when states.contains(WidgetState.hovered) => primary.base,
                          _ => colors.border,
                        },
                      ),
                      shape: const StadiumBorder(),
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
