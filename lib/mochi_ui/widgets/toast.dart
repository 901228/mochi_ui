import "dart:async";
import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/icons.dart";
import "../theme/responsive.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "button.dart";

/// A brief message over the page: what just happened, and sometimes how to undo it.
///
/// Raised with [showMochiToast] rather than built directly.
class MochiToast extends StatelessWidget {
  const MochiToast({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
    this.intent = MochiIntent.neutral,
  });

  final Widget title;

  /// A second line under the title.
  final Widget? description;

  /// Leading icon. Coloured by [intent].
  final Widget? icon;

  /// A single button, usually the way to undo what the toast is reporting.
  final Widget? action;

  /// Shows a close button when set.
  final VoidCallback? onClose;

  final MochiIntent intent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final neutral = intent == MochiIntent.neutral;

    // Only bites on a toast standing on its own: inside a stack the width is settled there and
    // handed down tight. The floor keeps a one-word message from shrinking to a stub.
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 240, maxWidth: g.toastWidth),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: g.space.sm, vertical: g.space.xs),
        decoration: ShapeDecoration(
          color: colors.overlay,
          // Smaller than a dialog's: toasts stack a few pixels apart, and the one in front casts
          // onto the one behind it, where a large shadow reads as dirt in the gap.
          shadows: g.shadows.of(MochiElevation.md, colors.shadow),
          shape: RoundedSuperellipseBorder(
            borderRadius: g.radius.md,
            // A toast carries its intent in its edge rather than its fill: it sits over the page
            // for a moment, and a block of colour there is more alarm than the message warrants.
            side: BorderSide(color: neutral ? colors.border : tone.base, width: g.borderWidth),
          ),
        ),
        child: Row(
          spacing: g.space.xs,
          children: [
            if (icon case final icon?)
              IconTheme.merge(
                data: IconThemeData(color: neutral ? colors.mutedForeground : tone.onSoft, size: 18),
                child: icon,
              ),
            // Expanded, not Flexible: the message takes whatever is left so the action and the
            // close button sit against the right edge instead of trailing the text.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: g.space.xs3,
                children: [
                  DefaultTextStyle(
                    style: theme.typography.body.sm
                        .withWeight(FontWeight.w500)
                        .copyWith(color: colors.foreground),
                    child: title,
                  ),
                  if (description case final description?)
                    DefaultTextStyle(
                      style: theme.typography.body.xs.copyWith(color: colors.mutedForeground),
                      child: description,
                    ),
                ],
              ),
            ),
            ?action,
            if (onClose case final onClose?) _ToastClose(onPress: onClose),
          ],
        ),
      ),
    );
  }
}

class _ToastClose extends StatelessWidget {
  const _ToastClose({required this.onPress});

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return MochiButton.icon(
      appearance: MochiButtonAppearance.ghost,
      size: MochiButtonSize.xs,
      onPress: onPress,
      icon: Icon(theme.icons.close),
    );
  }
}

/// What [showMochiToast] hands back, so a toast can be taken away before its time is up.
class MochiToastHandle {
  MochiToastHandle._(this._dismiss);

  final VoidCallback _dismiss;

  void dismiss() => _dismiss();
}

/// Hosts the toasts raised under it.
///
/// [MochiApp] installs one above the navigator, so a toast outlives the page that raised it and
/// stays visible over a dialog.
class MochiToaster extends StatefulWidget {
  const MochiToaster({super.key, required this.child, this.alignment, this.maxVisible = 3, this.width});

  final Widget child;

  /// Defaults to the bottom right on a wide screen and the bottom edge on a phone, where the
  /// corners are the hardest part of the screen to reach.
  final Alignment? alignment;

  /// Older toasts beyond this many are taken away as new ones arrive.
  final int maxVisible;

  /// How wide the stack is. Defaults to `geometry.toastWidth`.
  final double? width;

  @override
  State<MochiToaster> createState() => MochiToasterState();

  static MochiToasterState of(BuildContext context) {
    final state = context.findAncestorStateOfType<MochiToasterState>();
    assert(state != null, "No MochiToaster above this context. MochiApp installs one.");
    return state!;
  }

  static MochiToasterState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MochiToasterState>();
}

class MochiToasterState extends State<MochiToaster> {
  final _toasts = <_ToastRequest>[];
  final _waiting = <_ToastRequest>[];

  /// Raises [toast]. See [showMochiToast] for the usual way in.
  MochiToastHandle show(Widget toast, {Duration duration = const Duration(seconds: 4)}) {
    final request = _ToastRequest(toast: toast, duration: duration);
    setState(() {
      _waiting.add(request);
      _fill();
    });

    return MochiToastHandle._(() {
      // Nothing has been seen of a toast still waiting its turn, so it just leaves the queue.
      if (_waiting.remove(request)) {
        setState(() {});
        return;
      }
      request.dismiss?.call();
    });
  }

  /// Brings waiting toasts up as there is room for them, at the end new ones arrive at — which is
  /// where the deck is, so one comes up out of the deck wherever in the stack the room appeared.
  ///
  /// Raising more than [MochiToaster.maxVisible] at once queues the rest rather than dropping
  /// them: a toast nobody saw may as well not have been raised.
  void _fill({bool promoted = false}) {
    var taken = _toasts.where((request) => !request.leaving).length;
    while (_waiting.isNotEmpty && taken < widget.maxVisible) {
      _toasts.add(
        _waiting.removeAt(0)
          ..promoted = promoted
          ..held = promoted,
      );
      taken++;
    }
  }

  /// A toast has started sliding away. The card at the front of the deck is what becomes the next
  /// toast, so it leaves the deck now and stands in its place — same size, same spot — behind the
  /// one on its way out. What that one uncovers as it goes is the new toast, not a blank card.
  void _startLeaving(_ToastRequest request) {
    if (!mounted || request.leaving) return;
    setState(() {
      request.leaving = true;
      _fill(promoted: true);
    });
  }

  /// The toast has slid clear and its place is closing. The one standing in the deck's place can
  /// start growing now, and the two movements cancel: the stack below the gap slides up by
  /// exactly what the new toast takes at the end.
  void _startClosing() {
    if (!mounted) return;
    setState(() {
      for (final request in _toasts) {
        request.held = false;
      }
      _fill(promoted: true);
    });
  }

  void _remove(_ToastRequest request) {
    if (!mounted) return;
    setState(() {
      _toasts.remove(request);
      _fill(promoted: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final alignment =
        widget.alignment ??
        context.responsive<Alignment>(mobile: Alignment.bottomCenter, tablet: Alignment.bottomRight);
    final towards = alignment.y > 0 ? 1.0 : -1.0;

    return Stack(
      children: [
        widget.child,
        if (_toasts.isNotEmpty)
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(g.space.md),
                child: Align(
                  alignment: alignment,
                  // Laid out from the end new toasts arrive at, with the list reversed to match.
                  // That end is also painted first, so a toast arriving goes behind the ones
                  // already up rather than over them, and the deck goes behind the lot.
                  // One width for the whole stack rather than one per toast; see
                  // [MochiGeometry.toastWidth].
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: widget.width ?? g.toastWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      verticalDirection: towards > 0 ? VerticalDirection.up : VerticalDirection.down,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Outside the toasts rather than under the newest one: the deck stands
                        // still while a toast leaves, and the cards shuffle up on their own.
                        _Deck(waiting: _waiting, towards: towards),
                        for (final request in _toasts.reversed)
                          _Toast(
                            key: request.key,
                            request: request,
                            alignment: alignment,
                            // The gap between toasts belongs to the toast, not to the column: it
                            // has to be given up along with the height when one leaves, or the
                            // stack above shifts by that gap as one passes another.
                            gap: g.space.xs,
                            onLeaving: () => _startLeaving(request),
                            onClosing: _startClosing,
                            onRemoved: () => _remove(request),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One raised toast, kept outside the widget so its handle survives a rebuild of the list.
class _ToastRequest {
  _ToastRequest({required this.toast, required this.duration});

  final Widget toast;
  final Duration duration;
  final key = UniqueKey();

  /// Whether this one was already showing as a card in the deck before it came up.
  bool promoted = false;

  /// Set the moment it starts sliding away: its place is spoken for from then on, so the next
  /// toast can take it up.
  bool leaving = false;

  /// Set on a toast promoted while the one it follows is still sliding away. It stands where the
  /// front card of the deck was, at that card's size, until the other has gone.
  bool held = false;

  /// Set by the entry once it is on screen.
  VoidCallback? dismiss;
}

class _Toast extends StatefulWidget {
  const _Toast({
    super.key,
    required this.request,
    required this.alignment,
    required this.onRemoved,
    required this.onClosing,
    required this.onLeaving,
    required this.gap,
  });

  final _ToastRequest request;
  final Alignment alignment;
  final VoidCallback onRemoved;

  /// Called once it has slid clear, as the place it holds starts to close.
  final VoidCallback onClosing;

  /// Called as it starts sliding, while its place is still whole.
  final VoidCallback onLeaving;

  /// Space kept between this toast and the one before it, counted as part of its own height.
  final double gap;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with TickerProviderStateMixin {
  /// How much of its place the toast is taking up: it grows into the stack on the way in, and
  /// gives its place back only once it has already slid away.
  late final AnimationController _size = AnimationController(vsync: this);

  /// How far it has slid off towards the edge. Runs on its own, before the place is given up.
  late final AnimationController _slide = AnimationController(vsync: this);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.request.dismiss = _leave;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.theme.motion;
    _size
      // A promoted toast is filling the gap another one is leaving behind, so it grows at exactly
      // the rate that gap closes. Anything else and the stack above the gap drifts as they pass.
      ..duration = widget.request.promoted ? motion.toastReverseDuration : motion.toastDuration
      ..reverseDuration = motion.toastReverseDuration;
    _slide.duration = motion.toastReverseDuration;

    _start();
  }

  @override
  void didUpdateWidget(_Toast old) {
    super.didUpdateWidget(old);
    _start();
  }

  /// A toast promoted while another is still sliding away stands in the deck's place until that
  /// one has gone, and only then grows out of it.
  void _start() {
    if (widget.request.held || !_size.isDismissed || _size.isAnimating) return;
    _size.forward();
    _wait();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _size.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _wait() {
    _timer?.cancel();
    _timer = Timer(widget.request.duration, _leave);
  }

  /// Leaving is two movements, not one: the toast slides off to the side first, with the stack
  /// untouched, and only then gives up its place for the rest to close over. Doing both at once
  /// reads as the stack collapsing around something that is still there.
  void _leave() {
    _timer?.cancel();
    if (!mounted || _slide.isAnimating || _slide.isCompleted) return;

    widget.onLeaving();
    _slide.forward().then((_) {
      if (!mounted) return;
      widget.onClosing();
      _size.reverse().then((_) {
        if (_size.isDismissed) widget.onRemoved();
      });
    });
  }

  /// Which way the stack grows: 1 when new toasts arrive at the bottom, -1 at the top.
  double get _towards => widget.alignment.y > 0 ? 1 : -1;

  /// A toast rises out of the edge its stack is anchored to, which is the same direction the
  /// column grows in, so arriving is one movement rather than two.
  ///
  /// One promoted out of the queue has no distance to cover: it is already standing at the front
  /// of the queue, and [_promotedFrom] takes it from there.
  Offset get _enterFrom => widget.request.promoted ? Offset.zero : Offset(0, _towards);

  /// Where a promoted toast starts: exactly where it was standing as the front of the queue, in
  /// pixels rather than a fraction of its height, so the two line up to the pixel.
  double get _promotedFrom => widget.request.promoted ? _towards * _DeckPlace.step : 0;

  /// It leaves towards the side of the screen instead, so it doesn't travel across the toasts
  /// below it on the way out. A stack down the middle has no side to leave by.
  Offset get _leaveTowards => switch (widget.alignment.x) {
    > 0 => const Offset(1, 0),
    < 0 => const Offset(-1, 0),
    _ => Offset(0, _towards),
  };

  @override
  Widget build(BuildContext context) {
    final motion = context.theme.motion;

    // Hand-rolled rather than MochiSurfaceTransition: a toast comes from one edge and leaves by
    // another, and the height it gives up has to collapse without a clip, which would cut off its
    // own shadow.
    return MouseRegion(
      // A toast with an Undo in it has to still be there when the pointer arrives.
      onEnter: (_) => _timer?.cancel(),
      onExit: (_) => _wait(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_size, _slide]),
        builder: (context, child) {
          // A promoted toast takes the mirror of the exit curve, not the exit curve itself: what
          // it gains has to be exactly what the toast on its way out gives up at that instant, or
          // the stack above the two of them drifts as they pass.
          final curve = switch ((_size.status == AnimationStatus.reverse, widget.request.promoted)) {
            (true, _) => motion.transitionReverseCurve,
            (false, true) => FlippedCurve(motion.transitionReverseCurve),
            (false, false) => motion.transitionCurve,
          };
          final t = curve.transform(_size.value);
          final gone = motion.transitionReverseCurve.transform(_slide.value);
          final travel = _enterFrom * (1 - t) + _leaveTowards * gone;

          return Align(
            // Aligned on both axes: the box this lays out in is as wide as the stack, so leaving
            // the horizontal alignment at zero would centre every toast on the screen.
            alignment: Alignment(widget.alignment.x, _towards),
            // The gap a toast gives up closes over the same time as its exit, so the ones still
            // up slide into place instead of jumping once it is gone.
            heightFactor: t,
            child: Padding(
              padding: EdgeInsets.only(
                top: _towards > 0 ? widget.gap : 0,
                bottom: _towards > 0 ? 0 : widget.gap,
              ),
              child: Opacity(
                // A promoted toast is already on screen, standing at the front of the queue, so
                // it is there in full from the start rather than fading in — that is what the
                // toast in front uncovers as it slides away.
                opacity: ((widget.request.promoted ? 1.0 : t) * (1 - gone)).clamp(0, 1),
                child: Transform.scale(
                  // It grows out of the size it was standing at, and moves up out of the place it
                  // was standing in, over the same half of the exit that closes the gap for it.
                  scale: widget.request.promoted ? lerpDouble(_DeckPlace.scaleAt(0), 1, t) : 1,
                  child: Transform.translate(
                    offset: Offset(0, _promotedFrom * (1 - t)),
                    child: FractionalTranslation(translation: travel, child: child),
                  ),
                ),
              ),
            ),
          );
        },
        child: widget.request.toast,
      ),
    );
  }
}

/// The icon an intent speaks for itself with, so a success or a failure doesn't need one passed
/// in every time.
Widget? _intentIcon(BuildContext context, MochiIntent intent) {
  final icon = context.theme.icons.of(intent);
  return icon == null ? null : Icon(icon);
}

/// The toasts waiting their turn, each showing the edge of itself past the end of the stack, like
/// a pile of cards.
///
/// They are the real toasts, not stand-ins drawn to look like them: the front one is what comes up
/// next, and the only difference between it and a toast in the stack is how much of it can be
/// seen. Only its trailing edge shows, so nothing of the message is legible there — which is the
/// point, since there is nothing to do about it but wait.
///
/// Its own item in the column rather than something drawn under the newest toast: a toast leaving
/// must not take the queue with it.
class _Deck extends StatelessWidget {
  const _Deck({required this.waiting, required this.towards});

  /// The toasts still queued, front of the queue first.
  final List<_ToastRequest> waiting;

  /// 1 when the stack grows downwards, -1 when it grows up.
  final double towards;

  @override
  Widget build(BuildContext context) {
    // No height of its own: the queue hangs past the end of the stack, into the padding, rather
    // than taking a place in it and pushing every toast along as it fills and drains.
    return SizedBox(
      height: 0,
      child: OverflowBox(
        alignment: towards > 0 ? Alignment.topCenter : Alignment.bottomCenter,
        // Only the band past the end of the stack, and clipped to it: the rest of each toast
        // reaches back behind the one in front, and must stay hidden even while that one is
        // sliding out of the way.
        maxHeight: _DeckPlace.step * _DeckPlace.maxLayers,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.passthrough,
          children: [
            // Furthest back first, so each lies over the one behind it.
            for (var depth = _DeckPlace.maxLayers - 1; depth >= 0; depth--)
              if (depth < waiting.length)
                // Keyed by the toast itself, so one moving up a place in the queue is that same
                // widget at a new depth and can travel there, rather than the place being redrawn
                // with someone else standing in it.
                _DeckCard(
                  key: waiting[depth].key,
                  depth: depth,
                  towards: towards,
                  child: waiting[depth].toast,
                ),
          ],
        ),
      ),
    );
  }
}

/// Where a toast stands while it waits its turn. Depth 0 is the front of the queue, which is also
/// where a toast promoted out of it starts from, so both read these.
abstract final class _DeckPlace {
  /// However many are queued, at most this many show: past two it reads as a mess rather than as
  /// a pile.
  static const maxLayers = 2;

  /// How much more of its trailing edge each place further back shows.
  static const step = 6.0;

  /// How much of its width each place further back gives up.
  static const shrink = 0.06;

  /// The edge showing at [depth] places back, and the width it is drawn at there.
  static double outAt(double depth) => step * (depth + 1);
  static double scaleAt(double depth) => 1 - shrink * (depth + 1);
}

/// One waiting toast, at its place in the queue.
///
/// It arrives from a place further back, and moves up as the queue empties in front of it: the
/// front of the queue coming up into the stack pulls the rest along behind it.
class _DeckCard extends StatelessWidget {
  const _DeckCard({super.key, required this.depth, required this.towards, required this.child});

  final int depth;
  final double towards;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.theme.motion;

    return Positioned.fill(
      child: TweenAnimationBuilder(
        // Only the end is read after the first build: moving up a place travels from wherever
        // this one currently stands, and a new one starts a place further back than it belongs.
        tween: Tween<double>(begin: depth + 1, end: depth.toDouble()),
        duration: motion.toastDuration,
        curve: motion.transitionCurve,
        builder: (context, at, card) => Align(
          alignment: towards > 0 ? Alignment.topCenter : Alignment.bottomCenter,
          heightFactor: 1,
          child: SizedBox(
            // The sliver of it that shows. The rest overflows back behind the toast in front,
            // where the band clips it away.
            height: _DeckPlace.outAt(at),
            child: OverflowBox(
              alignment: towards > 0 ? Alignment.bottomCenter : Alignment.topCenter,
              maxHeight: double.infinity,
              child: Transform.scale(scale: _DeckPlace.scaleAt(at), child: card),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Raises a [MochiToast] over the page.
///
/// [intent] brings its own icon from [MochiIcons] unless [icon] says otherwise, so an alert is
/// `showMochiToast(context, title: ..., intent: MochiIntent.danger)`.
///
/// Returns a handle that takes it away early, for a toast whose reason has passed.
MochiToastHandle showMochiToast(
  BuildContext context, {
  required Widget title,
  Widget? description,
  Widget? icon,
  Widget? action,
  MochiIntent intent = MochiIntent.neutral,
  bool closeable = true,
  Duration duration = const Duration(seconds: 4),
}) {
  final toaster = MochiToaster.of(context);
  late final MochiToastHandle handle;

  handle = toaster.show(
    Builder(
      // Built in the toaster's context rather than the caller's, so the icon for an intent comes
      // from the theme the toast is painted in.
      builder: (context) => MochiToast(
        title: title,
        description: description,
        icon: icon ?? _intentIcon(context, intent),
        action: action,
        intent: intent,
        onClose: closeable ? () => handle.dismiss() : null,
      ),
    ),
    duration: duration,
  );

  return handle;
}
