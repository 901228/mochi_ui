import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/theme.dart";

/// A list whose rows can be dragged into another order.
///
/// Wraps the widgets layer's [ReorderableList], and adds the two things a kit has to say about
/// it: what a row looks like while it is being carried, and what starts the carrying. On touch
/// that is a long press anywhere on the row, since a phone has no pointer to aim a small handle
/// with; with a mouse it is a [MochiSortableHandle], because a row you can drag by its middle is
/// a row you cannot select text in or press a button on by mistake. Pass `wholeItemDrags` to say
/// so yourself.
///
/// [onReorder] is given the index the row came from and the index it ended up at, already
/// counted with the row taken out — moving row 0 down one is `(0, 1)`, and the list it describes
/// is the list after the move.
///
/// Every row needs a key of its own, which is what the list follows through the move.
///
/// ```dart
/// MochiSortable(
///   itemCount: steps.length,
///   onReorder: (from, to) => setState(() => steps.insert(to, steps.removeAt(from))),
///   itemBuilder: (context, index) => MochiTile(
///     key: ValueKey(steps[index]),
///     title: Text(steps[index]),
///     trailing: MochiSortableHandle(index: index),
///   ),
/// )
/// ```
class MochiSortable extends StatelessWidget {
  const MochiSortable({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.spacing = 0,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.onReorderStart,
    this.onReorderEnd,
    this.wholeItemDrags,
  }) : assert(itemCount >= 0);

  final int itemCount;

  /// Builds the row at [index]. It must carry a [Key] of its own.
  final IndexedWidgetBuilder itemBuilder;

  /// Where a row came from and where it ended up, counted with the row taken out.
  final void Function(int from, int to) onReorder;

  /// Between rows. A gap is part of the row for the drag's purposes, so a row lands where the
  /// eye expects rather than a gap's width away from it.
  final double spacing;

  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  final void Function(int index)? onReorderStart;
  final void Function(int index)? onReorderEnd;

  /// Whether the whole row starts a drag after a long press, rather than only a handle.
  /// Defaults to the theme's `touch`.
  final bool? wholeItemDrags;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final whole = wholeItemDrags ?? theme.touch;
    final half = spacing / 2;
    final gap = scrollDirection == Axis.vertical
        ? EdgeInsets.symmetric(vertical: half)
        : EdgeInsets.symmetric(horizontal: half);

    return ReorderableList(
      itemCount: itemCount,
      padding: padding,
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      physics: physics,
      controller: controller,
      onReorderStart: onReorderStart,
      onReorderEnd: onReorderEnd,
      // The framework's newer callback, which has already counted the row out of the list: the
      // adjustment everyone writes by hand under the old one is exactly the bug it caused.
      onReorderItem: onReorder,
      proxyDecorator: (child, index, animation) => _Carried(animation: animation, child: child),
      itemBuilder: (context, index) {
        final item = itemBuilder(context, index);
        assert(item.key != null, "Every row of a MochiSortable needs a key of its own.");

        // The key goes on the outside, where the list looks for it, and the padding inside it.
        return KeyedSubtree(
          key: item.key,
          child: Padding(
            padding: spacing == 0 ? EdgeInsets.zero : gap,
            child: whole ? ReorderableDelayedDragStartListener(index: index, child: item) : item,
          ),
        );
      },
    );
  }
}

/// The row being carried: lifted off the page, and grown the way a press grows it.
class _Carried extends StatelessWidget {
  const _Carried({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final shadows = theme.geometry.shadows.of(MochiElevation.lg, theme.colors.shadow);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        // The lift is the drag's own animation, so it grows as the row leaves the list and
        // settles back as it lands.
        final t = Curves.easeOut.transform(animation.value);

        return Transform.scale(
          scale: 1 + 0.03 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(boxShadow: [for (final shadow in shadows) shadow.scale(t)]),
            child: child,
          ),
        );
      },
    );
  }
}

/// What a row is dragged by: a grip the pointer can aim at.
///
/// On touch the whole row answers a long press, so a handle is there to be seen rather than to
/// be hit — [MochiSortable] does not need one to work.
class MochiSortableHandle extends StatelessWidget {
  const MochiSortableHandle({super.key, required this.index, this.icon, this.size = 20, this.enabled = true});

  /// The row this handle belongs to.
  final int index;

  /// Defaults to `icons.grip`.
  final IconData? icon;

  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ReorderableDragStartListener(
      index: index,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.grab : MouseCursor.defer,
        // Not a MochiTappable: a press here is the start of a drag, not a press, and growing
        // under the finger that is about to carry the row off reads as two things happening.
        child: Semantics(
          label: theme.strings.reorder,
          child: Icon(
            icon ?? theme.icons.grip,
            size: size,
            color: enabled ? theme.colors.mutedForeground : theme.colors.border,
          ),
        ),
      ),
    );
  }
}
