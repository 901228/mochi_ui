import "dart:async";

import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/responsive.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "button.dart";
import "transitions.dart";

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
          shadows: g.shadows.of(MochiElevation.lg, colors.shadow),
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
            Flexible(
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
  final _toasts = <_ToastRequest>[];

  /// Raises [toast]. See [showMochiToast] for the usual way in.
  MochiToastHandle show(Widget toast, {Duration duration = const Duration(seconds: 4)}) {
    final request = _ToastRequest(toast: toast, duration: duration);
    setState(() {
      _toasts.add(request);
      if (_toasts.length > widget.maxVisible) _toasts.removeAt(0);
    });

    return MochiToastHandle._(() => request.dismiss?.call());
  }

  void _remove(_ToastRequest request) {
    if (!mounted) return;
    setState(() => _toasts.remove(request));
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: alignment.x < 0
                        ? CrossAxisAlignment.start
                        : alignment.x > 0
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center,
                    spacing: g.space.xs,
                    children: [
                      for (final request in _toasts)
                        _Toast(
                          key: request.key,
                          request: request,
                          alignment: alignment,
                          onRemoved: () => _remove(request),
                        ),
                    ],
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

  /// Set by the entry once it is on screen.
  VoidCallback? dismiss;
}

class _Toast extends StatefulWidget {
  const _Toast({super.key, required this.request, required this.alignment, required this.onRemoved});

  final _ToastRequest request;
  final Alignment alignment;
  final VoidCallback onRemoved;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
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
    _animation
      ..duration = motion.transitionDuration
      ..reverseDuration = motion.transitionReverseDuration;

    if (_animation.isDismissed && !_animation.isAnimating) {
      _animation.forward();
      _wait();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  void _wait() {
    _timer?.cancel();
    _timer = Timer(widget.request.duration, _leave);
  }

  void _leave() {
    _timer?.cancel();
    if (!mounted || _animation.status == AnimationStatus.reverse) return;
    _animation.reverse().then((_) {
      if (_animation.isDismissed) widget.onRemoved();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // A toast with an Undo in it has to still be there when the pointer arrives.
      onEnter: (_) => _timer?.cancel(),
      onExit: (_) => _wait(),
      child: MochiSurfaceTransition(
        animation: _animation,
        transition: MochiTransition.slide,
        slideFrom: widget.alignment.y > 0 ? AxisDirection.down : AxisDirection.up,
        scrim: false,
        child: widget.request.toast,
      ),
    );
  }
}

/// Raises a [MochiToast] over the page.
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
      builder: (context) => MochiToast(
        title: title,
        description: description,
        icon: icon,
        action: action,
        intent: intent,
        onClose: closeable ? () => handle.dismiss() : null,
      ),
    ),
    duration: duration,
  );

  return handle;
}
