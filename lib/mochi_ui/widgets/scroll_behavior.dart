import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// Scrollbars for desktop platforms: a rounded thumb that thickens when the pointer comes near
/// it, so it is easy to grab without taking much room at rest.
class MochiScrollBehavior extends ScrollBehavior {
  const MochiScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) =>
      switch (getPlatform(context)) {
        TargetPlatform.linux || TargetPlatform.macOS || TargetPlatform.windows => MochiScrollbar(
          controller: details.controller,
          axis: switch (details.direction) {
            AxisDirection.up || AxisDirection.down => Axis.vertical,
            AxisDirection.left || AxisDirection.right => Axis.horizontal,
          },
          child: child,
        ),
        _ => child,
      };
}

/// A rounded scrollbar that grows near the pointer. Usually installed by [MochiScrollBehavior]
/// rather than used directly.
class MochiScrollbar extends StatefulWidget {
  const MochiScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.axis = Axis.vertical,
    this.thickness = 6,
    this.hoverThickness = 11,
    this.proximity = 32,
  });

  final Widget child;
  final ScrollController? controller;
  final Axis axis;

  /// Thickness at rest, and once the pointer is within [proximity] of the thumb's edge.
  final double thickness;
  final double hoverThickness;

  /// How close to the scrollbar's edge the pointer has to be for it to grow.
  final double proximity;

  @override
  State<MochiScrollbar> createState() => _MochiScrollbarState();
}

class _MochiScrollbarState extends State<MochiScrollbar> with SingleTickerProviderStateMixin {
  late final _grow = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));

  bool _near = false;
  bool _dragging = false;

  @override
  void dispose() {
    _stopWatchingPointer();
    _grow.dispose();

    super.dispose();
  }

  void _setNear(bool value) {
    if (_near == value) return;
    _near = value;
    _apply();
  }

  // Stays thick for the whole drag, even when the pointer wanders off the scrollbar.
  void _apply() => _dragging || _near ? _grow.forward() : _grow.reverse();

  void _handleHover(PointerHoverEvent event) => _updateNear(event.position);

  void _updateNear(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(globalPosition);
    final distance = switch (widget.axis) {
      Axis.vertical => box.size.width - local.dx,
      Axis.horizontal => box.size.height - local.dy,
    };
    _setNear(distance >= 0 && distance <= widget.proximity);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_near || _dragging) return;
    _dragging = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointer);
  }

  // The pointer can be released anywhere, so the release is caught globally.
  void _handleGlobalPointer(PointerEvent event) {
    if (event is! PointerUpEvent && event is! PointerCancelEvent) return;
    _stopWatchingPointer();
    // The drag may have ended far from the scrollbar, so proximity is re-read from where the
    // pointer actually is rather than from the last hover.
    _updateNear(event.position);
    _apply();
  }

  void _stopWatchingPointer() {
    if (!_dragging) return;
    _dragging = false;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleGlobalPointer);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Listener(
      // Translucent: the MouseRegion below is not opaque, so deferring to the child would leave
      // the listener out of the hit-test path and it would never see the press.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: MouseRegion(
        opaque: false,
        onHover: _handleHover,
        onExit: (_) => _setNear(false),
        child: AnimatedBuilder(
          animation: _grow,
          builder: (context, child) {
            final thickness = widget.thickness + (widget.hoverThickness - widget.thickness) * _grow.value;
            return RawScrollbar(
              controller: widget.controller,
              // Desktop scrollables keep a thin bar on screen instead of only showing one mid-scroll.
              thumbVisibility: true,
              thickness: thickness,
              // Fully rounded ends, whatever the thickness.
              radius: Radius.circular(thickness / 2),
              thumbColor: Color.lerp(colors.border, colors.mutedForeground, _grow.value),
              // Keeps the thumb clear of a rounded container's corners.
              crossAxisMargin: 2,
              mainAxisMargin: 4,
              interactive: true,
              child: child!,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
