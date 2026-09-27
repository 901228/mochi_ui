import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "action.dart";

/// Where a header's title sits between its two groups of actions.
enum MochiHeaderAlignment { start, center }

/// Whether the header is separated from the content below it.
enum MochiHeaderVariant {
  /// Sits directly on the page background.
  plain,

  /// A surface with a hairline along its bottom edge, for pages that scroll under it.
  bordered,

  /// Inset from the page edges with a border all the way around: a bar that floats above the
  /// content instead of capping the page.
  floating,
}

/// The bar at the top of a [MochiScaffold]: a title with actions on either side.
///
/// A pushed page puts [MochiAction.back] in [prefixes]; there is no separate nested variant,
/// since that was the only difference. Each group is a [MochiActionBar], so a group with more
/// actions than the breakpoint has room for folds its last ones into a … rather than squeezing
/// the title out.
class MochiHeader extends StatelessWidget {
  const MochiHeader({
    super.key,
    required this.title,
    this.prefixes = const [],
    this.suffixes = const [],
    this.maxVisibleActions,
    this.alignment = MochiHeaderAlignment.start,
    this.variant = MochiHeaderVariant.plain,
  });

  final Widget title;

  /// Leading actions, usually [MochiAction.back].
  final List<MochiAction> prefixes;
  final List<MochiAction> suffixes;

  /// How many slots each group has, the … included. Defaults to the breakpoint's own count.
  final int? maxVisibleActions;

  /// Where the title sits between the two action groups.
  final MochiHeaderAlignment alignment;

  final MochiHeaderVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    final border = BorderSide(color: theme.colors.border, width: g.borderWidth);

    return Container(
      margin: switch (variant) {
        .plain || .bordered => EdgeInsets.zero,
        .floating => EdgeInsets.all(g.space.xs),
      },
      padding: EdgeInsets.symmetric(horizontal: g.space.md, vertical: g.space.sm),
      decoration: switch (variant) {
        .plain => null,
        .bordered => BoxDecoration(
          color: theme.colors.surface,
          border: Border(bottom: border),
        ),
        .floating => ShapeDecoration(
          color: theme.colors.surface,
          shape: RoundedSuperellipseBorder(borderRadius: g.radius.md, side: border),
        ),
      },
      child: Row(
        spacing: g.space.xs,
        children: [
          if (prefixes.isNotEmpty) MochiActionBar(prefixes, maxVisible: maxVisibleActions),
          Expanded(
            child: Align(
              alignment: switch (alignment) {
                .start => AlignmentDirectional.centerStart,
                .center => Alignment.center,
              },
              child: DefaultTextStyle(
                style: theme.typography.title.lg.copyWith(color: theme.colors.foreground),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                child: title,
              ),
            ),
          ),
          if (suffixes.isNotEmpty) MochiActionBar(suffixes, maxVisible: maxVisibleActions),
        ],
      ),
    );
  }
}
