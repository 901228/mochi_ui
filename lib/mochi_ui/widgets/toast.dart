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

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 420),
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
  const MochiToaster({super.key, required this.child, this.alignment, this.maxVisible = 3});

  final Widget child;

  /// Defaults to the bottom right on a wide screen and the bottom edge on a phone, where the
  /// corners are the hardest part of the screen to reach.
  final Alignment? alignment;

  /// Older toasts beyond this many are taken away as new ones arrive.
  final int maxVisible;

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
  /// How wide the stack is, or as much of it as the screen allows.
  static const _stackWidth = 400.0;

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

  /// Moves waiting toasts up as room appears. Raising more than [MochiToaster.maxVisible] at once
  /// queues the rest rather than dropping them: a toast nobody saw may as well not have been
  /// raised, and the one pushed out would be the oldest, which is the one that has been waiting.
  ///
  /// One taking a slot that just came free was already on screen as a card in the deck, so it
  /// grows into place from there rather than arriving from off screen.
  void _fill({bool promoted = false}) {
    var held = _toasts.where((request) => !request.leaving).length;
    while (_waiting.isNotEmpty && held < widget.maxVisible) {
      _toasts.add(_waiting.removeAt(0)..promoted = promoted);
      held++;
    }
  }

  /// A toast that has started leaving gives up its slot straight away, so the one taking it grows
  /// while that one shrinks. Waiting for the exit to finish would collapse the stack and then
  /// stretch it again, which shoves everything above the gap down and back up.
  void _startLeaving(_ToastRequest request) {
    if (!mounted || request.leaving) return;
    setState(() {
      request.leaving = true;
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
                  // One width for the whole stack rather than one per toast. A stack that resized
                  // itself around whatever had just arrived would jump every time a longer
                  // message came up and again when it left, and the deck would have nothing
                  // steady to line up with.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _stackWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      verticalDirection: alignment.y > 0 ? VerticalDirection.up : VerticalDirection.down,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Outside the toasts rather than under the newest one: the deck stands
                        // still while a toast leaves, and the cards shuffle up on their own.
                        _DeckStrip(waiting: _waiting.length, towards: alignment.y > 0 ? 1 : -1),
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

  /// Set the moment it starts leaving, so its slot can be filled while it is still on its way out.
  bool leaving = false;

  /// Set by the entry once it is on screen.
  VoidCallback? dismiss;
}

class _Toast extends StatefulWidget {
  const _Toast({
    super.key,
    required this.request,
    required this.alignment,
    required this.onRemoved,
    required this.onLeaving,
    required this.gap,
  });

  final _ToastRequest request;
  final Alignment alignment;
  final VoidCallback onRemoved;

  /// Called as the exit starts, while the toast is still on screen.
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

    if (_size.isDismissed && !_size.isAnimating) {
      _size.forward();
      _wait();
    }
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

    _slide.forward().then((_) {
      if (!mounted) return;
      widget.onLeaving();
      _size.reverse().then((_) {
        if (_size.isDismissed) widget.onRemoved();
      });
    });
  }

  /// Which way the stack grows: 1 when new toasts arrive at the bottom, -1 at the top.
  double get _towards => widget.alignment.y > 0 ? 1 : -1;

  /// Roughly how much narrower a deck card is than the toast above it, which is where a promoted
  /// toast grows from.
  static const _deckScale = 0.94;

  /// A toast rises out of the edge its stack is anchored to, which is the same direction the
  /// column grows in, so arriving is one movement rather than two. One promoted out of the deck
  /// only nudges, since it was already sitting there.
  Offset get _enterFrom => Offset(0, _towards * (widget.request.promoted ? 0.15 : 1));

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
                opacity: (t * (1 - gone)).clamp(0, 1),
                child: Transform.scale(
                  // A promoted toast was a card in the deck a moment ago, so it grows from that
                  // card's size instead of arriving at full size.
                  scale: widget.request.promoted ? lerpDouble(_deckScale, 1, t) : 1,
                  child: FractionalTranslation(translation: travel, child: child),
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

/// Shows the toasts waiting their turn as the top edges of a small pile of cards, at the end of
/// the stack the next one will come up at.
///
/// Its own item in the stack rather than something drawn under the newest toast: a toast leaving
/// must not take the queue with it, and the cards have to be able to shuffle forward on their own
/// while that happens.
///
/// Nothing is said about how many are waiting beyond "more than one": a number would be read as
/// something to act on, and there is nothing to do but wait.
class _DeckStrip extends StatelessWidget {
  const _DeckStrip({required this.waiting, required this.towards});

  final int waiting;

  /// 1 when the stack grows downwards, -1 when it grows up.
  final double towards;

  /// However many are queued, at most this many cards: past two it reads as a mess rather than
  /// as a pile.
  static const _maxLayers = 2;

  /// How much of each card shows, and how much narrower it is than the one in front of it.
  static const _step = 6.0;
  static const _inset = 10.0;

  /// How far a card reaches up behind the toast in front of it. Anything past the sliver that
  /// shows is hidden by that toast, which is painted over it.
  static const _hidden = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final motion = theme.motion;
    final layers = waiting.clamp(0, _maxLayers);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: layers.toDouble()),
      duration: motion.toastDuration,
      curve: motion.transitionCurve,
      // No height of its own: the deck hangs past the end of the stack, into the padding, rather
      // than taking a place in it and pushing every toast along as the queue fills and drains.
      builder: (context, shown, _) => SizedBox(
        height: 0,
        child: OverflowBox(
          alignment: towards > 0 ? Alignment.topCenter : Alignment.bottomCenter,
          // Only the band past the end of the stack, and clipped to it: the rest of each card
          // reaches back behind the toast in front, and must stay hidden even while that toast is
          // sliding out of the way.
          maxHeight: _step * _maxLayers,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            fit: StackFit.passthrough,
            children: [
              // Furthest back first, so each card lies over the one behind it. Every card slides
              // out from under the toast in front as its turn in the queue comes round.
              for (var layer = _maxLayers - 1; layer >= 0; layer--)
                if ((shown - layer).clamp(0, 1) > 0) _card(theme, layer, (shown - layer).clamp(0, 1)),
            ],
          ),
        ),
      ),
    );
  }

  /// [reveal] is how much of this card's own sliver has come out, 0 to 1.
  Widget _card(MochiTheme theme, int layer, double reveal) {
    final g = theme.geometry;
    final out = _step * layer + _step * reveal;
    final corner = g.radius.md.topLeft;

    return Positioned(
      left: _inset * (layer + 1),
      right: _inset * (layer + 1),
      // Anchored at the end of the stack and reaching back behind the toast there: only the part
      // past that toast's edge is ever seen, which is a card's trailing edge.
      top: towards > 0 ? -_hidden : null,
      bottom: towards > 0 ? null : -_hidden,
      height: _hidden + out,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: theme.colors.overlay,
          shape: RoundedSuperellipseBorder(
            borderRadius: towards > 0
                ? BorderRadius.vertical(bottom: corner)
                : BorderRadius.vertical(top: corner),
            side: BorderSide(color: theme.colors.border, width: g.borderWidth),
          ),
        ),
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
