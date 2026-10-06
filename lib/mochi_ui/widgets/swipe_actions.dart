import "dart:math" as math;

import "package:flutter/semantics.dart";
import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "action.dart";
import "state_transition.dart";
import "tappable.dart";

/// A row that slides aside to show actions behind it: a record that a swipe deletes, a message a
/// swipe pins.
///
/// The actions are [MochiAction]s, so the icon, the words and the intent are the ones the rest of
/// the kit uses, and the label is also each action's name in semantics — a screen reader is
/// offered them directly, with no swipe to make. [trailing] sit at the end of the row and are
/// revealed by dragging towards its start, [leading] the other way; both follow the text
/// direction. Menus (`MochiAction.menu`) are not actions here: there is no room behind a row to
/// open one.
///
/// Dragged past half of its actions it stays open, short of that it springs back; pressing an
/// action runs it and closes the row. With [fullSwipe], a drag most of the way across runs the
/// outermost action outright, the way a phone deletes a row — off by default, since that is also
/// the easiest way to delete something by accident.
///
/// Only one row is open at a time, and pressing an open row or scrolling the list it is in closes
/// it. Dragging follows `theme.touch` unless [enabled] says otherwise: a mouse has no swipe, so on
/// a desktop the same actions belong in a `MochiContextMenu`.
class MochiSwipeActions extends StatefulWidget {
  const MochiSwipeActions({
    super.key,
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.fullSwipe = false,
    this.enabled,
    this.actionWidth = 72,
  });

  final Widget child;
  final List<MochiAction> leading;
  final List<MochiAction> trailing;

  /// Whether a drag most of the way across runs the outermost action: the last of [trailing], or
  /// the first of [leading].
  final bool fullSwipe;

  /// Whether the row can be dragged. Null follows `theme.touch`.
  final bool? enabled;

  /// How wide each action is.
  final double actionWidth;

  @override
  State<MochiSwipeActions> createState() => _MochiSwipeActionsState();
}

class _MochiSwipeActionsState extends State<MochiSwipeActions> with TickerProviderStateMixin {
  /// The open rows, so opening one closes the others.
  static final _open = <_MochiSwipeActionsState>{};

  /// How far the row has moved, in pixels: positive is towards the right whatever the direction.
  late final AnimationController _offset = AnimationController.unbounded(vsync: this);

  /// 0 to 1: how far the outermost action has taken over the whole of the revealed width, which
  /// is what says a full swipe will run it — two buttons widening side by side would not say
  /// which one.
  late final AnimationController _takeover = AnimationController(vsync: this);
  ScrollPosition? _scroll;
  double _width = 0;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// The sign of a drag that reveals [MochiSwipeActions.trailing]: towards the row's start.
  double get _trailingSign => _rtl ? 1 : -1;

  List<MochiAction> _shown(List<MochiAction> actions) => [
    for (final action in actions)
      if (action.children == null) action,
  ];

  List<MochiAction> get _trailing => _shown(widget.trailing);
  List<MochiAction> get _leading => _shown(widget.leading);

  /// How far the row moves to show its actions on the side [sign] reveals.
  double _reach(double sign) =>
      (sign == _trailingSign ? _trailing.length : _leading.length) * widget.actionWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A list that scrolls under an open row closes it: the row's actions were for that moment.
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != _scroll) {
      _scroll?.removeListener(_close);
      _scroll = scroll?..addListener(_close);
    }
  }

  @override
  void dispose() {
    _open.remove(this);
    _scroll?.removeListener(_close);
    _offset.dispose();
    _takeover.dispose();
    super.dispose();
  }

  Duration get _duration => MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : context.theme.motion.sizeDuration;

  Future<void> _settle(double to) {
    if (to == 0) {
      _open.remove(this);
    } else {
      for (final other in _open.toList()) {
        if (other != this) other._close();
      }
      _open.add(this);
    }
    // Only a row on its way across keeps the outermost action spread over it.
    _take(to.abs() == _width && to != 0);
    if (_duration == Duration.zero) {
      _offset.value = to;
      return Future.value();
    }
    return _offset.animateTo(to, duration: _duration, curve: context.theme.motion.sizeCurve);
  }

  /// Whether a full swipe is about to run: past six tenths, with an outermost action that runs.
  bool _armed(double value) {
    if (!widget.fullSwipe || value == 0) return false;
    final sign = value.sign;
    if (_reach(sign) == 0 || value.abs() <= _width * 0.6) return false;
    return _runs(sign == _trailingSign ? _trailing.last : _leading.first);
  }

  void _take(bool taken) {
    final target = taken ? 1.0 : 0.0;
    if (_takeover.value == target ||
        _takeover.isAnimating &&
            _takeover.status == (taken ? AnimationStatus.forward : AnimationStatus.reverse)) {
      return;
    }
    if (_duration == Duration.zero) {
      _takeover.value = target;
      return;
    }
    _takeover.animateTo(target, duration: context.theme.motion.stateDuration, curve: Curves.easeOut);
  }

  void _close() {
    if (_offset.value != 0 && !_offset.isAnimating) _settle(0);
  }

  void _handleDragStart(DragStartDetails details) {
    _offset.stop();
    for (final other in _open.toList()) {
      if (other != this) other._close();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = _offset.value + details.primaryDelta!;
    final sign = next.sign;
    final reach = _reach(sign);
    if (reach == 0) {
      _offset.value = 0;
      return;
    }
    // Past its actions the row moves on, against something: halved, unless a full swipe is
    // allowed, which needs the room to go all the way across.
    final past = next.abs() - reach;
    _offset.value = past <= 0 || widget.fullSwipe ? next.clamp(-_width, _width) : sign * (reach + past / 2);
    _take(_armed(_offset.value));
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    final value = _offset.value;
    final sign = value.sign;
    final reach = _reach(sign);
    final velocity = details.primaryVelocity ?? 0;

    if (_armed(value)) {
      final action = sign == _trailingSign ? _trailing.last : _leading.first;
      await _settle(sign * _width);
      action.onPress!();
      if (mounted) await _settle(0);
      return;
    }

    // A fling decides by its direction; a slow release by how far the row has come.
    final opening = velocity.abs() > 700 ? velocity.sign == sign : value.abs() > reach / 2;
    await _settle(opening && reach > 0 ? sign * reach : 0);
  }

  /// The width of the button at [index] (left to right) among [count], over [revealed] pixels.
  ///
  /// Up to their own width they share what is showing; past it the extra all goes to the
  /// outermost one, the one at the screen's edge, since that is the one a full swipe runs; and as
  /// [_takeover] rises it takes the rest of the room from the others too.
  double _widthOf(int index, int count, double revealed, double sign) {
    // The edge the buttons are against is the right one when the row moved left.
    final outermost = sign < 0 ? count - 1 : 0;
    final share = math.min(revealed / count, widget.actionWidth) * (1 - _takeover.value);
    return index == outermost ? revealed - share * (count - 1) : share;
  }

  bool _runs(MochiAction action) => action.enabled && action.onPress != null;

  void _press(MochiAction action) {
    action.onPress!();
    _settle(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final draggable = widget.enabled ?? theme.touch;

    final semantics = {
      for (final action in [..._leading, ..._trailing])
        if (_runs(action)) CustomSemanticsAction(label: action.labelOf(theme)): action.onPress!,
    };

    return Semantics(
      customSemanticsActions: semantics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;

          return GestureDetector(
            onHorizontalDragStart: draggable ? _handleDragStart : null,
            onHorizontalDragUpdate: draggable ? _handleDragUpdate : null,
            onHorizontalDragEnd: draggable ? _handleDragEnd : null,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: Listenable.merge([_offset, _takeover]),
                builder: (context, child) {
                  final dx = _offset.value;
                  final sign = dx.sign;
                  // The side that is showing, laid out at the edge the row has moved away from.
                  final actions = sign == 0
                      ? const <MochiAction>[]
                      : (sign == _trailingSign ? _trailing : _leading);
                  final open = dx != 0;

                  return Stack(
                    children: [
                      if (actions.isNotEmpty)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: sign < 0 ? null : 0,
                          right: sign < 0 ? 0 : null,
                          // Wider than its buttons once the row is pulled past them, so the colour
                          // keeps up with the row rather than leaving a gap behind it.
                          width: math.max(dx.abs(), 0),
                          child: Row(
                            textDirection: TextDirection.ltr,
                            children: [
                              // In the order they are given, reading from the row's start.
                              for (final (index, action) in (_rtl ? actions.reversed : actions).indexed)
                                SizedBox(
                                  width: _widthOf(index, actions.length, dx.abs(), sign),
                                  child: _SwipeButton(
                                    action: action,
                                    onPress: _runs(action) ? () => _press(action) : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(dx, 0),
                        // An open row is put away by pressing it, and the press does nothing else.
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: open ? () => _settle(0) : null,
                          child: AbsorbPointer(absorbing: open, child: child),
                        ),
                      ),
                    ],
                  );
                },
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SwipeButton extends StatelessWidget {
  const _SwipeButton({required this.action, required this.onPress});

  final MochiAction action;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final tone = theme.colors.of(action.intent);
    final icon = action.iconOf(theme);

    return MochiTappable(
      onPress: onPress,
      // A slot behind a row: it tints rather than growing.
      scaleOnPress: false,
      semanticLabel: action.labelOf(theme),
      builder: (context, states, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) => ColoredBox(
          color: blend.color((st) => MochiColors.stateLayer(tone.base, tone.onBase, st)),
          child: Opacity(
            opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: theme.geometry.space.xs3,
                  children: [
                    if (icon != null) Icon(icon, size: 20, color: tone.onBase),
                    Text(
                      action.labelOf(theme),
                      style: theme.typography.body.xs.copyWith(color: tone.onBase),
                      maxLines: 1,
                    ),
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
