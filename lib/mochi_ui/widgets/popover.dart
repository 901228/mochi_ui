import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/theme.dart";
import "transitions.dart";

/// Which side of the anchor the popover sits on.
///
/// The popover flips to the opposite side when the preferred one has no room.
enum MochiPopoverSide { top, bottom, left, right }

/// How the popover lines up with the anchor along the side it sits on.
enum MochiPopoverAlign { start, center, end }

/// Handed to [MochiPopover.builder].
///
/// Wire [focusNode] into the control that opens the popover so focus returns to it on close,
/// and call [toggle] from that control's press handler.
class MochiPopoverAnchor {
  const MochiPopoverAnchor(this.controller, this.focusNode);

  final MenuController controller;
  final FocusNode focusNode;

  bool get isOpen => controller.isOpen;

  /// Opens at [position], an offset from the anchor's top left corner. Used for context menus,
  /// which open where the pointer is rather than against an edge.
  void open({Offset? position}) => controller.open(position: position);

  void close() => controller.close();

  void toggle({Offset? position}) => isOpen ? close() : open(position: position);
}

/// Builds the widget the popover is anchored to.
typedef MochiPopoverBuilder = Widget Function(BuildContext context, MochiPopoverAnchor anchor, Widget? child);

/// A floating panel anchored to a control: the base for menus and context menus.
///
/// Built on [RawMenuAnchor], which mounts the panel in an [Overlay], closes it on an outside tap
/// or Escape, and restores focus to [MochiPopoverAnchor.focusNode] afterwards. The panel enters
/// and leaves with [MochiSurfaceTransition], so it moves like a dialog or a pushed page.
///
/// ```dart
/// MochiPopover(
///   popoverBuilder: (context) => const Text("hello"),
///   builder: (context, anchor, _) =>
///       MochiButton(focusNode: anchor.focusNode, onPress: anchor.toggle, child: const Text("open")),
/// )
/// ```
class MochiPopover extends StatefulWidget {
  const MochiPopover({
    super.key,
    required this.popoverBuilder,
    required this.builder,
    this.controller,
    this.child,
    this.side = MochiPopoverSide.bottom,
    this.align = MochiPopoverAlign.center,
    this.gap,
    this.constraints,
    this.matchAnchorWidth = false,
    this.padding,
    this.surface = true,
    this.consumeOutsideTaps = false,
    this.closeOnAnchorPress = false,
    this.autofocus = true,
    this.onOpen,
    this.onClose,
  });

  /// Builds the panel's content. Wrapped in a surface unless [surface] is false.
  final WidgetBuilder popoverBuilder;

  /// Builds the anchor. Passed [child] unchanged, so a subtree that doesn't depend on the anchor
  /// can be built once.
  final MochiPopoverBuilder builder;
  final Widget? child;

  /// Opens and closes the popover from outside the anchor. One is created if omitted.
  final MenuController? controller;

  final MochiPopoverSide side;
  final MochiPopoverAlign align;

  /// Distance between the anchor and the panel. Defaults to `geometry.space.xs2`.
  final double? gap;

  /// Applied to the panel on top of the room available on screen.
  final BoxConstraints? constraints;

  /// Whether the panel is at least as wide as the anchor, as a select's list is under its field.
  final bool matchAnchorWidth;

  /// Inside the panel's surface. Defaults to `geometry.space.xs`.
  final EdgeInsetsGeometry? padding;

  /// Whether to paint the panel background, border and shadow. Turn it off for content that
  /// brings its own surface.
  final bool surface;

  /// Whether the tap that closes the popover is also delivered to whatever is underneath.
  final bool consumeOutsideTaps;

  /// Whether pressing the anchor while the popover is open puts it away.
  ///
  /// The anchor counts as part of the popover, so a press on it is not an outside tap and leaves
  /// the popover standing. That is what an anchor which toggles wants — it closes itself, and
  /// closing here first would just reopen it. An anchor that only opens (a row with a context
  /// menu, a panel opened at the pointer) wants the opposite: pressing it is the same gesture as
  /// pressing anywhere else on the page, and should put the popover away.
  final bool closeOnAnchorPress;

  /// Whether the panel takes focus when it opens, so Escape and arrow keys reach it.
  final bool autofocus;

  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  State<MochiPopover> createState() => _MochiPopoverState();
}

class _MochiPopoverState extends State<MochiPopover> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
  MenuController? _ownController;
  final _focusNode = FocusNode(debugLabel: "MochiPopover anchor");

  MenuController get _controller => widget.controller ?? (_ownController ??= MenuController());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.theme.motion;
    _animation
      ..duration = motion.transitionDuration
      ..reverseDuration = motion.transitionReverseDuration;
  }

  @override
  void dispose() {
    _animation.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _animationsOff => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _handleOpenRequest(Offset? position, VoidCallback showOverlay) {
    showOverlay();
    if (_animationsOff) {
      _animation.value = 1;
      return;
    }
    _animation.forward();
  }

  void _handleClose() {
    // Not every close goes through the exit animation: closing a parent menu's children, a
    // scroll, or the view changing size all hide the overlay outright. Put the animation back to
    // the start so the next open runs from there rather than appearing fully grown.
    _animation.value = 0;
    widget.onClose?.call();
  }

  void _handleCloseRequest(VoidCallback hideOverlay) {
    if (_animationsOff || !_animation.isAnimating && _animation.value == 0) {
      _animation.value = 0;
      hideOverlay();
      return;
    }
    // The overlay stays mounted until the exit animation finishes; reopening part-way through
    // starts it forward again, and this callback then leaves it alone.
    _animation.reverse().then((_) {
      if (_animation.status == AnimationStatus.dismissed) hideOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    final anchor = MochiPopoverAnchor(_controller, _focusNode);

    return RawMenuAnchor(
      controller: _controller,
      childFocusNode: _focusNode,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      onOpenRequested: _handleOpenRequest,
      onCloseRequested: _handleCloseRequest,
      onOpen: widget.onOpen,
      onClose: _handleClose,
      overlayBuilder: _buildOverlay,
      builder: (context, controller, child) {
        final built = widget.builder(context, anchor, child);
        if (!widget.closeOnAnchorPress) return built;

        // A Listener rather than a tap callback: the anchor's own gesture would win the arena,
        // and this has to happen whatever the press turns out to mean.
        return Listener(
          onPointerDown: (_) {
            if (controller.isOpen) controller.close();
          },
          child: built,
        );
      },
      child: widget.child,
    );
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final theme = context.theme;
    final g = theme.geometry;
    final gap = widget.gap ?? g.space.xs2;

    Widget panel = widget.popoverBuilder(context);
    if (widget.surface) {
      panel = MochiPopoverSurface(padding: widget.padding, child: panel);
    }
    if (widget.constraints case final constraints?) {
      panel = ConstrainedBox(constraints: constraints, child: panel);
    }
    if (widget.matchAnchorWidth) {
      panel = ConstrainedBox(
        constraints: BoxConstraints(minWidth: info.anchorRect.width),
        child: panel,
      );
    }

    return CustomSingleChildLayout(
      delegate: _PopoverLayout(
        // A position given to open() is relative to the anchor's top left corner, and replaces
        // the anchor entirely: a context menu opens at the pointer, not against an edge.
        anchorRect: info.position == null
            ? info.anchorRect
            : (info.anchorRect.topLeft + info.position!) & Size.zero,
        side: widget.side,
        align: widget.align,
        gap: gap,
        margin: g.space.xs,
        textDirection: Directionality.of(context),
      ),
      // RawMenuAnchor puts the panel beside the anchor in the element tree rather than under it,
      // so the panel needs its own TapRegion in the same group to count as inside. Escape is
      // already handled: the DismissMenuAction the anchor installs is an inherited lookup.
      child: TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (_) => _controller.close(),
        child: FocusScope(
          autofocus: widget.autofocus,
          child: MochiSurfaceTransition(
            animation: _animation,
            scrim: false,
            alignment: _growFrom,
            child: panel,
          ),
        ),
      ),
    );
  }

  /// Corner or edge the panel grows out of, so it appears to come from the anchor.
  Alignment get _growFrom {
    final cross = switch (widget.align) {
      MochiPopoverAlign.start => -1.0,
      MochiPopoverAlign.center => 0.0,
      MochiPopoverAlign.end => 1.0,
    };

    return switch (widget.side) {
      MochiPopoverSide.top => Alignment(cross, 1),
      MochiPopoverSide.bottom => Alignment(cross, -1),
      MochiPopoverSide.left => Alignment(1, cross),
      MochiPopoverSide.right => Alignment(-1, cross),
    };
  }
}

/// The panel a popover floats in: [MochiColors.overlay] rather than `surface`, so it reads as
/// floating above a card instead of continuing it.
///
/// Public for anything that floats like a popover without being one, such as a text field's
/// context menu, which [EditableText] places itself.
class MochiPopoverSurface extends StatelessWidget {
  const MochiPopoverSurface({super.key, this.padding, required this.child});

  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: theme.colors.overlay,
        shadows: g.shadows.of(MochiElevation.lg, theme.colors.shadow),
        shape: RoundedSuperellipseBorder(
          borderRadius: g.radius.md,
          side: BorderSide(color: theme.colors.border, width: g.borderWidth),
        ),
      ),
      child: ClipRSuperellipse(
        borderRadius: g.radius.md,
        child: Padding(padding: padding ?? EdgeInsets.all(g.space.xs), child: child),
      ),
    );
  }
}

/// Places the panel beside [anchorRect], flipping to the opposite side when the preferred one
/// has no room and then clamping it inside the overlay.
class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout({
    required this.anchorRect,
    required this.side,
    required this.align,
    required this.gap,
    required this.margin,
    required this.textDirection,
  });

  final Rect anchorRect;
  final MochiPopoverSide side;
  final MochiPopoverAlign align;
  final double gap;

  /// Smallest distance kept between the panel and the edge of the overlay.
  final double margin;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest).deflate(EdgeInsets.all(margin));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final resolved = _resolveSide(size, childSize);
    final vertical = resolved == MochiPopoverSide.top || resolved == MochiPopoverSide.bottom;

    final main = switch (resolved) {
      MochiPopoverSide.top => anchorRect.top - gap - childSize.height,
      MochiPopoverSide.bottom => anchorRect.bottom + gap,
      MochiPopoverSide.left => anchorRect.left - gap - childSize.width,
      MochiPopoverSide.right => anchorRect.right + gap,
    };

    final cross = switch (_resolveAlign()) {
      MochiPopoverAlign.start => vertical ? anchorRect.left : anchorRect.top,
      MochiPopoverAlign.center =>
        vertical ? anchorRect.center.dx - childSize.width / 2 : anchorRect.center.dy - childSize.height / 2,
      MochiPopoverAlign.end =>
        vertical ? anchorRect.right - childSize.width : anchorRect.bottom - childSize.height,
    };

    final x = vertical ? cross : main;
    final y = vertical ? main : cross;

    return Offset(_clamp(x, childSize.width, size.width), _clamp(y, childSize.height, size.height));
  }

  /// Keeps the panel on screen; a panel too large to fit is pinned to the leading edge rather
  /// than pushed off the trailing one.
  double _clamp(double value, double extent, double available) =>
      value.clamp(margin, (available - margin - extent).clamp(margin, double.infinity));

  MochiPopoverSide _resolveSide(Size size, Size childSize) {
    final (before, after, extent) = switch (side) {
      MochiPopoverSide.top ||
      MochiPopoverSide.bottom => (anchorRect.top, size.height - anchorRect.bottom, childSize.height),
      MochiPopoverSide.left ||
      MochiPopoverSide.right => (anchorRect.left, size.width - anchorRect.right, childSize.width),
    };

    final needed = extent + gap + margin;
    final leading = side == MochiPopoverSide.top || side == MochiPopoverSide.left;
    final room = leading ? before : after;
    // Only flip when the other side is actually better: with neither side big enough the panel
    // would otherwise jump about as its content changes size.
    if (room >= needed || (leading ? after : before) <= room) return side;

    return switch (side) {
      MochiPopoverSide.top => MochiPopoverSide.bottom,
      MochiPopoverSide.bottom => MochiPopoverSide.top,
      MochiPopoverSide.left => MochiPopoverSide.right,
      MochiPopoverSide.right => MochiPopoverSide.left,
    };
  }

  /// Flips start and end for right-to-left text, but only along the horizontal axis.
  MochiPopoverAlign _resolveAlign() {
    if (textDirection == TextDirection.ltr) return align;
    if (side == MochiPopoverSide.left || side == MochiPopoverSide.right) return align;

    return switch (align) {
      MochiPopoverAlign.start => MochiPopoverAlign.end,
      MochiPopoverAlign.center => MochiPopoverAlign.center,
      MochiPopoverAlign.end => MochiPopoverAlign.start,
    };
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      anchorRect != old.anchorRect ||
      side != old.side ||
      align != old.align ||
      gap != old.gap ||
      margin != old.margin ||
      textDirection != old.textDirection;
}
