import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/typography.dart";
import "focus_ring.dart";
import "menu.dart";
import "popover.dart";
import "state_transition.dart";
import "tappable.dart";

/// One step along a [MochiBreadcrumb].
class MochiBreadcrumbItem {
  const MochiBreadcrumbItem({required this.label, this.icon, this.onPress, this.semanticLabel});

  final Widget label;

  /// Before the label.
  final Widget? icon;

  /// Null makes the step plain text — which is what the last one, the place you already are,
  /// should be.
  final VoidCallback? onPress;

  final String? semanticLabel;
}

/// The trail back up from where you are: Sessions › 3x3 main › 12 July.
///
/// The last step is where the app is, so it is written in plain text rather than offered as
/// somewhere to go. A trail longer than [maxItems] keeps its first and last steps and folds the
/// middle into a … that opens them as a menu, so a deep path doesn't push the current place off
/// the edge.
class MochiBreadcrumb extends StatelessWidget {
  const MochiBreadcrumb({super.key, required this.items, this.separator, this.maxItems});

  final List<MochiBreadcrumbItem> items;

  /// Between steps. Defaults to a chevron pointing the way the text runs.
  final Widget? separator;

  /// How many steps to show before folding the middle away. Null shows them all.
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final max = maxItems;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final separator = this.separator ?? Icon(rtl ? theme.icons.chevronLeft : theme.icons.chevronRight);

    // The first step, the … , and the last two: enough to say where you started and where you
    // are, which is what the trail is for.
    final folded = max != null && items.length > max && max >= 3;
    final shown = folded ? [items.first, ...items.skip(items.length - (max - 1))] : items;
    final hidden = folded ? items.sublist(1, items.length - (max - 1)) : const <MochiBreadcrumbItem>[];

    return DefaultTextStyle.merge(
      style: theme.typography.body.sm,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: IconTheme.merge(
        data: IconThemeData(size: 16, color: theme.colors.mutedForeground),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: g.space.xs2,
          children: [
            for (final (index, item) in shown.indexed) ...[
              if (index > 0) ...[
                separator,
                if (index == 1 && folded) ...[_Overflow(items: hidden), separator],
              ],
              Flexible(
                child: _Step(item: item, current: identical(item, shown.last)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A step: a link, or plain text once it is the place you are.
class _Step extends StatelessWidget {
  const _Step({required this.item, required this.current, this.focusNode});

  final MochiBreadcrumbItem item;
  final bool current;

  /// The popover's, when this step is the … that opens one: that is what returns the focus.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;

    Widget content(Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: g.space.xs3,
      children: [
        if (item.icon case final icon?)
          IconTheme.merge(
            data: IconThemeData(color: color),
            child: icon,
          ),
        Flexible(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: color)
                .merge(current ? theme.typography.body.sm.withWeight(FontWeight.w600) : null),
            child: item.label,
          ),
        ),
      ],
    );

    if (current || item.onPress == null) {
      return Semantics(
        // A screen reader is told this is the page it is on, not a link it failed to follow.
        header: current,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: g.space.xs3),
          child: content(current ? colors.foreground : colors.mutedForeground),
        ),
      );
    }

    return MochiTappable(
      onPress: item.onPress,
      focusNode: focusNode,
      semanticLabel: item.semanticLabel,
      // A word in a line of text: it colours rather than growing.
      scaleOnPress: false,
      builder: (context, states, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) => MochiFocusRing(
          visible: blend.contains(WidgetState.focused),
          radius: g.radius.xs,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: g.space.xs3),
            decoration: ShapeDecoration(
              color: blend.color(
                (st) => MochiColors.stateLayer(colors.surface.withValues(alpha: 0), colors.foreground, st),
              ),
              shape: RoundedSuperellipseBorder(borderRadius: g.radius.xs),
            ),
            child: content(
              blend.color(
                (st) => st.contains(WidgetState.hovered) ? colors.foreground : colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The … that holds the steps a long trail folded away.
class _Overflow extends StatelessWidget {
  const _Overflow({required this.items});

  final List<MochiBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return MochiPopoverMenu(
      align: MochiPopoverAlign.start,
      menuBuilder: (context) => [
        for (final item in items) MochiMenuItem(prefix: item.icon, title: item.label, onPress: item.onPress),
      ],
      builder: (context, anchor, _) => _Step(
        item: MochiBreadcrumbItem(label: Icon(theme.icons.more), onPress: anchor.toggle, semanticLabel: "…"),
        current: false,
        focusNode: anchor.focusNode,
      ),
    );
  }
}
