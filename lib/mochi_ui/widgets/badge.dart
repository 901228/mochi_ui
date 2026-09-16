import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";

enum MochiBadgeAppearance { solid, soft, outlined }

/// A small pill label: status, counts, penalties.
class MochiBadge extends StatelessWidget {
  const MochiBadge({
    super.key,
    required this.child,
    this.prefix,
    this.suffix,
    this.intent = MochiIntent.neutral,
    this.appearance = MochiBadgeAppearance.soft,
  });

  final Widget child;
  final Widget? prefix;
  final Widget? suffix;
  final MochiIntent intent;
  final MochiBadgeAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final tone = theme.colors.of(intent);
    final touch = theme.touch;

    final (background, foreground, border) = switch (appearance) {
      .solid => (tone.base, tone.onBase, tone.base.withValues(alpha: 0)),
      .soft => (tone.soft, tone.onSoft, tone.base.withValues(alpha: 0)),
      .outlined => (tone.soft.withValues(alpha: 0), tone.onSoft, tone.base),
    };

    return Container(
      constraints: BoxConstraints(minHeight: touch ? 24 : 20),
      padding: EdgeInsets.symmetric(horizontal: g.space.xs, vertical: g.space.xs3),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedSuperellipseBorder(
          borderRadius: g.radius.full,
          side: BorderSide(color: border, width: g.borderWidth),
        ),
      ),
      child: DefaultTextStyle(
        style: theme.typography.body.xs.withWeight(FontWeight.w600).copyWith(color: foreground),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: touch ? 14 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: g.space.xs3 * 2,
            children: [?prefix, child, ?suffix],
          ),
        ),
      ),
    );
  }
}
