import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/geometry.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "divider.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";
import "tappable.dart";
import "shape_shadow.dart";

/// The parts of a row's layout that change with the theme's scale.
@immutable
class _RowMetrics {
  const _RowMetrics({required this.minHeight, required this.verticalPadding, required this.iconSize});

  factory _RowMetrics.of(MochiTheme theme) => _RowMetrics(
    minHeight: (theme.touch ? 52 : 40) * theme.density,
    verticalPadding: theme.touch ? theme.geometry.space.sm : theme.geometry.space.xs,
    iconSize: theme.touch ? 20 : 18,
  );

  final double minHeight;
  final double verticalPadding;
  final double iconSize;

  static _RowMetrics lerp(_RowMetrics a, _RowMetrics b, double t) => _RowMetrics(
    minHeight: lerpDouble(a.minHeight, b.minHeight, t)!,
    verticalPadding: lerpDouble(a.verticalPadding, b.verticalPadding, t)!,
    iconSize: lerpDouble(a.iconSize, b.iconSize, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is _RowMetrics &&
      minHeight == other.minHeight &&
      verticalPadding == other.verticalPadding &&
      iconSize == other.iconSize;

  @override
  int get hashCode => Object.hash(minHeight, verticalPadding, iconSize);
}

/// Width of the prefix column: the icon plus the gap to the title.
double _prefixColumn(MochiTheme theme) => (theme.touch ? 20 : 18) + theme.geometry.space.sm;

/// Lets rows see the group's layout decisions.
class _TileGroupScope extends InheritedWidget {
  const _TileGroupScope({required this.reservePrefix, required this.ground, required super.child});

  final bool reservePrefix;

  /// What the group is filled with, which its rows are mixed over.
  final Color ground;

  static Color? groundOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TileGroupScope>()?.ground;

  static bool reservesPrefix(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TileGroupScope>()?.reservePrefix ?? false;

  @override
  bool updateShouldNotify(_TileGroupScope old) => old.reservePrefix != reservePrefix || old.ground != ground;
}

/// A row in a [MochiTileGroup]: settings entries, list items, menu entries.
///
/// forui splits this into FTile and FItem; here one widget covers both, since the tile was only
/// a thin wrapper with touch-sized padding.
class MochiTile extends StatelessWidget {
  const MochiTile({
    super.key,
    required this.title,
    this.prefix,
    this.subtitle,
    this.details,
    this.suffix,
    this.intent = MochiIntent.primary,
    this.enabled = true,
    this.selected = false,
    this.onPress,
    this.onLongPress,
    this.onSecondaryPress,
    this.semanticLabel,
  });

  final Widget title;

  /// Leading widget, usually an icon.
  final Widget? prefix;

  /// Secondary line under [title].
  final Widget? subtitle;

  /// Trailing value, shown before [suffix] in the muted text style.
  final Widget? details;

  /// Trailing widget, usually a chevron, switch or icon button.
  final Widget? suffix;

  /// Colors the selected state.
  final MochiIntent intent;

  final bool enabled;
  final bool selected;
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // A group that reserves the prefix column lines every row's title up, prefix or not.
    final placeholder = prefix == null && _TileGroupScope.reservesPrefix(context)
        ? SizedBox(width: _prefixColumn(context.theme) - context.theme.geometry.space.sm)
        : null;

    return MochiTappable(
      enabled: enabled,
      selected: selected,
      onPress: onPress,
      onLongPress: onLongPress,
      onSecondaryPress: onSecondaryPress,
      semanticLabel: semanticLabel,
      // Rows keep their place; they tint instead of growing.
      scaleOnPress: false,
      builder: (context, states, _) => _TileSurface(
        states: states,
        enabled: enabled,
        intent: intent,
        prefix: prefix ?? placeholder,
        title: title,
        subtitle: subtitle,
        details: details,
        suffix: suffix,
      ),
    );
  }
}

class _TileSurface extends StatelessWidget {
  const _TileSurface({
    required this.states,
    required this.enabled,
    required this.intent,
    required this.prefix,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.suffix,
  });

  final Set<WidgetState> states;
  final bool enabled;
  final MochiIntent intent;
  final Widget? prefix;
  final Widget title;
  final Widget? subtitle;
  final Widget? details;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final typography = theme.typography;

    // Rows sit on the group's fill, not on the page, so the selected fill is mixed over that.
    final ground = _TileGroupScope.groundOf(context) ?? colors.surface;
    final selected = colors.softOn(tone, ground);

    Color background(Set<WidgetState> st) => st.contains(WidgetState.selected)
        ? MochiColors.stateLayer(selected, tone.onSoft, st)
        : MochiColors.stateLayer(ground, colors.foreground, st);

    Color foreground(Set<WidgetState> st) =>
        st.contains(WidgetState.selected) ? tone.onSoft : colors.foreground;

    // Row sizes come from the theme, so switching scales would otherwise jump.
    return MochiValueTransition(
      value: _RowMetrics.of(theme),
      lerp: _RowMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, metrics, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) {
          final fg = blend.color(foreground);
          final muted = blend.color(
            (st) => st.contains(WidgetState.selected) ? tone.onSoft : colors.mutedForeground,
          );

          return MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: BorderRadius.zero,
            // Groups clip their rows, so the ring has to live inside the row.
            inset: true,
            child: ColoredBox(
              // The background stays opaque: fading the whole row would let the group's border show
              // through it, which reads as an extra outline around that row.
              color: blend.color(background),
              child: Opacity(
                // Keyed off `enabled`, not the disabled state: a row whose only interactive part is
                // its suffix has no callbacks of its own and must not look disabled.
                opacity: enabled ? 1 : 0.4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: g.space.md, vertical: metrics.verticalPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: metrics.minHeight),
                    child: IconTheme.merge(
                      data: IconThemeData(color: fg, size: metrics.iconSize),
                      child: Row(
                        spacing: g.space.sm,
                        children: [
                          ?prefix,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              spacing: g.space.xs3,
                              children: [
                                DefaultTextStyle(
                                  style: typography.body.sm.copyWith(color: fg),
                                  child: title,
                                ),
                                if (subtitle case final subtitle?)
                                  DefaultTextStyle(
                                    style: typography.body.xs.copyWith(color: muted),
                                    child: subtitle,
                                  ),
                              ],
                            ),
                          ),
                          if (details case final details?)
                            DefaultTextStyle(
                              style: typography.body.xs.copyWith(color: muted),
                              child: details,
                            ),
                          ?suffix,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// How rows in a [MochiTileGroup] are separated.
enum MochiTileDivider {
  /// No line between rows.
  none,

  /// Starts where the row below's text starts (past its prefix) and runs to the group's edge.
  leading,

  /// A line inset by the row's horizontal padding on both sides.
  indented,

  /// A line spanning the full width of the group.
  full,
}

/// A card of [MochiTile]s separated by dividers, with an optional label and description.
class MochiTileGroup extends StatelessWidget {
  const MochiTileGroup({
    super.key,
    required this.children,
    this.label,
    this.description,
    this.divider = MochiTileDivider.leading,
    this.reservePrefix = false,
  });

  final List<Widget> children;

  /// Shown above the card, in the muted label style.
  final Widget? label;

  /// Shown below the card.
  final Widget? description;

  final MochiTileDivider divider;

  /// Reserve the prefix column on rows that have no prefix, so every title in the group lines up.
  final bool reservePrefix;

  /// Where the line starts. A leading divider clears the prefix column, and does so for every row
  /// in the group: lines of different lengths in one list read as a mistake, so a group with any
  /// prefix indents all of its dividers.
  double _indent(MochiTheme theme) {
    final g = theme.geometry;
    final hasPrefix = children.any((child) => child is MochiTile && child.prefix != null);
    return switch (divider) {
      .none || .full => 0,
      .indented => g.space.md,
      .leading => g.space.md + (hasPrefix ? _prefixColumn(theme) : 0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    // A raised group is one lifted block like a raised card: lighter than the page, no line, a
    // deeper shadow, and rounder.
    final raised = theme.layering == .raised;
    final ground = raised ? colors.overlay : colors.surface;
    final radius = raised ? g.radius.lg : g.radius.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: g.space.xs,
      children: [
        if (label case final label?)
          DefaultTextStyle(
            style: theme.typography.title.xs.copyWith(color: colors.mutedForeground),
            child: label,
          ),
        ShapeShadow(
          radius: radius,
          shadows: raised ? g.shadows.raised(MochiElevation.md, colors) : null,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: ground,
              shape: RoundedSuperellipseBorder(
                borderRadius: radius,
                // Transparent, not absent: the line's width stays in the layout.
                side: BorderSide(
                  color: raised ? ground.withValues(alpha: 0) : colors.border,
                  width: g.borderWidth,
                ),
              ),
            ),
            // Clipped so a row's hover tint follows the card's corners.
            child: ClipRSuperellipse(
              borderRadius: radius,
              child: _TileGroupScope(
                reservePrefix: reservePrefix,
                ground: ground,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (index, child) in children.indexed) ...[
                      if (index > 0 && divider != MochiTileDivider.none)
                        MochiDivider(
                          indent: _indent(theme),
                          endIndent: divider == MochiTileDivider.indented ? g.space.md : 0,
                        ),
                      child,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (description case final description?)
          DefaultTextStyle(
            style: theme.typography.body.xs.copyWith(color: colors.mutedForeground),
            child: description,
          ),
      ],
    );
  }
}
