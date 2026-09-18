import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

/// Wraps a scrollable and fades its content out at whichever end can still be scrolled,
/// so a cut-off row reads as "there is more" instead of as the end of the list.
///
/// Wrap the scrollable itself, or a subtree containing one; the scrollable keeps its own
/// controller. Scrollbars come from the app's scroll behavior, so they are not part of this.
///
/// A mouse wheel over the area scrolls only the area, even once it has reached its end: see
/// [containScroll].
class MochiScrollArea extends StatefulWidget {
  const MochiScrollArea({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeExtent = 24,
    this.containScroll = true,
  });

  /// The scrollable itself, or a subtree containing one.
  final Widget child;

  final Axis axis;

  /// Length of the fade at each end.
  final double fadeExtent;

  /// Keep the wheel to the area once it reaches an end, rather than letting the page behind it
  /// take over and scroll away mid-gesture (CSS's `overscroll-behavior: contain`).
  ///
  /// Only while there is something to scroll, and only along [axis]: an area whose content fits
  /// passes the wheel on, so the page can still be scrolled with the pointer over it. Touch and
  /// trackpad drags don't need this; the inner scrollable keeps the whole gesture already.
  final bool containScroll;

  @override
  State<MochiScrollArea> createState() => _MochiScrollAreaState();
}

class _MochiScrollAreaState extends State<MochiScrollArea> {
  // Read from notifications rather than a controller: metrics arrive on the first layout too,
  // and the scrollable keeps whatever controller it already had.
  ScrollMetrics? _metrics;

  bool _update(ScrollMetrics metrics) {
    if (_metrics?.pixels == metrics.pixels &&
        _metrics?.maxScrollExtent == metrics.maxScrollExtent &&
        _metrics?.minScrollExtent == metrics.minScrollExtent) {
      return false;
    }
    // Notifications arrive during layout, so the rebuild waits for the frame to finish.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _metrics = metrics);
    });
    return false;
  }

  /// How much of the fade to show at the start and end, 0..1.
  // A wheel event goes to the first scrollable along the hit path that registers for it. The one
  // inside registers only while it can still move, so at its end this registers a handler that
  // does nothing, ahead of whatever scrollable lies further out.
  void _contain(PointerSignalEvent event) {
    final metrics = _metrics;
    if (event is! PointerScrollEvent || metrics == null) return;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) return;
    final delta = switch (widget.axis) {
      Axis.vertical => event.scrollDelta.dy,
      Axis.horizontal => event.scrollDelta.dx,
    };
    if (delta == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  (double, double) _fades() {
    final metrics = _metrics;
    if (metrics == null) return (0, 0);

    double fade(double distance) => (distance / widget.fadeExtent).clamp(0, 1);
    return (fade(metrics.pixels - metrics.minScrollExtent), fade(metrics.maxScrollExtent - metrics.pixels));
  }

  @override
  Widget build(BuildContext context) {
    final (start, end) = _fades();

    final listener = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _update(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _update(n.metrics),
        child: widget.containScroll
            ? Listener(
                // Translucent: on desktop the scrollbar inside wraps the list in a MouseRegion
                // that isn't opaque, and that reports "not hit" to its parent even when the list
                // was. Deferring to the child would leave this out of the hit path, and the wheel
                // would never reach it.
                behavior: HitTestBehavior.translucent,
                onPointerSignal: _contain,
                child: widget.child,
              )
            : widget.child,
      ),
    );

    if (start == 0 && end == 0) return listener;

    return ShaderMask(
      // dstIn keeps the child where the mask is opaque and fades it where it is not.
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final extent = widget.axis == Axis.vertical ? bounds.height : bounds.width;
        final fraction = (widget.fadeExtent / extent).clamp(0.0, 0.5);
        const opaque = Color(0xFFFFFFFF);
        return LinearGradient(
          begin: widget.axis == Axis.vertical ? Alignment.topCenter : Alignment.centerLeft,
          end: widget.axis == Axis.vertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [
            opaque.withValues(alpha: 1 - start),
            opaque,
            opaque,
            opaque.withValues(alpha: 1 - end),
          ],
          stops: [0, fraction, 1 - fraction, 1],
        ).createShader(bounds);
      },
      child: listener,
    );
  }
}
