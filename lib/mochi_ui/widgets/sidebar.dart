import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "collapsible.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";
import "tooltip.dart";
import "value_transition.dart";

/// How wide the sidebar is, and how far its width has travelled between the two.
///
/// Items read it to know whether to show their labels, so the whole column moves as one.
class _SidebarScope extends InheritedWidget {
  const _SidebarScope({required this.open, required super.child});

  /// 1 while the sidebar is at its full width, 0 while it is a rail, and in between while it is
  /// on its way.
  final double open;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SidebarScope>()?.open ?? 1;

  @override
  bool updateShouldNotify(_SidebarScope old) => old.open != open;
}

/// The column of destinations down the side of an app: sessions, statistics, settings.
///
/// [collapsed] narrows it to a rail of icons, and each item's label becomes its tooltip. The
/// width is animated, so the page beside it slides over rather than jumping.
///
/// The app owns which item is chosen, the same way it owns the page: pass `selected` on the item
/// that matches where you are.
///
/// ```dart
/// MochiSidebar(
///   collapsed: railed,
///   header: const MochiSidebarHeading(Text("Mochi")),
///   children: [
///     MochiSidebarItem(
///       icon: const Icon(TablerIcons.clock),
///       label: const Text("Timer"),
///       selected: page == Page.timer,
///       onPress: () => go(Page.timer),
///     ),
///   ],
/// )
/// ```
class MochiSidebar extends StatelessWidget {
  const MochiSidebar({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.collapsed = false,
    this.width = 240,
    this.railWidth,
    this.padding,
    this.background,
    this.border = true,
  });

  /// [MochiSidebarItem]s, [MochiSidebarGroup]s and anything else that belongs in the column.
  final List<Widget> children;

  /// Above the items, outside the scroll: a logo, a workspace switcher.
  final Widget? header;

  /// Below the items: an account row, a collapse button.
  final Widget? footer;

  /// Narrows it to [railWidth] and leaves only the icons.
  final bool collapsed;

  /// The full width.
  final double width;

  /// The collapsed width. Defaults to a square target for the icons: 56, or 64 on touch.
  final double? railWidth;

  /// Around the items. Defaults to `space.xs2` all round.
  final EdgeInsetsGeometry? padding;

  /// Defaults to `colors.surface`.
  final Color? background;

  /// Whether to draw a line down its trailing edge, against the page.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final rail = railWidth ?? (theme.touch ? 64 : 56);

    return MochiValueTransition(
      value: collapsed ? 0.0 : 1.0,
      lerp: (a, b, t) => lerpDouble(a, b, t)!,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, open, _) => _SidebarScope(
        open: open,
        child: Container(
          width: lerpDouble(rail, width, open),
          decoration: BoxDecoration(
            color: background ?? colors.surface,
            border: border
                ? BorderDirectional(
                    end: BorderSide(color: colors.border, width: g.borderWidth),
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              // The items scroll; the header and the footer stay put.
              Expanded(
                child: SingleChildScrollView(
                  padding: padding ?? EdgeInsets.all(g.space.xs2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: g.space.xs3,
                    children: children,
                  ),
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// One destination in a [MochiSidebar].
///
/// Collapsed, it is its icon alone and its label moves into a tooltip — taken from [tooltip], or
/// from the label itself when that is a [Text].
class MochiSidebarItem extends StatelessWidget {
  const MochiSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.selected = false,
    this.enabled = true,
    this.onPress,
    this.intent = MochiIntent.primary,
    this.tooltip,
    this.semanticLabel,
    this.focusNode,
  });

  final Widget icon;
  final Widget label;

  /// After the label: a count, a badge. Hidden while the sidebar is a rail.
  final Widget? trailing;

  /// Whether this is where the app currently is.
  final bool selected;

  final bool enabled;
  final VoidCallback? onPress;

  /// Colours the chosen row.
  final MochiIntent intent;

  /// Shown while collapsed. Defaults to the label's text when [label] is a [Text].
  final String? tooltip;

  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final open = _SidebarScope.of(context);
    final metrics = _SidebarMetrics.of(theme);

    final row = MochiTappable(
      enabled: enabled && onPress != null,
      selected: selected,
      focusNode: focusNode,
      semanticLabel: semanticLabel ?? _labelText,
      // A row in a list: it tints rather than growing.
      scaleOnPress: false,
      onPress: onPress,
      builder: (context, states, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) {
          final foreground = blend.color(
            (st) => switch (st) {
              _ when st.contains(WidgetState.selected) => tone.onSoft,
              _ => colors.foreground,
            },
          );

          return MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: g.radius.sm,
            // The column clips as it scrolls, so the ring is painted inside the row.
            inset: true,
            child: Opacity(
              opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
              child: Container(
                height: metrics.height,
                padding: EdgeInsetsDirectional.symmetric(horizontal: metrics.inset),
                decoration: ShapeDecoration(
                  color: blend.color(
                    (st) => st.contains(WidgetState.selected)
                        ? MochiColors.stateLayer(colors.softOn(tone, colors.surface), tone.onSoft, st)
                        : MochiColors.stateLayer(colors.surface, colors.foreground, st),
                  ),
                  shape: RoundedSuperellipseBorder(borderRadius: g.radius.sm),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground, size: metrics.iconSize),
                  child: DefaultTextStyle(
                    style: theme.typography.body.sm
                        .withWeight(selected ? FontWeight.w600 : FontWeight.w400)
                        .copyWith(color: foreground),
                    child: Row(
                      children: [
                        icon,
                        // The label takes the room the width gives it and fades with it, so the
                        // icon never shifts as the sidebar opens.
                        Expanded(
                          child: ClipRect(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: open,
                              child: Opacity(
                                opacity: open,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.only(start: metrics.gap),
                                  child: Row(
                                    children: [
                                      Expanded(child: DefaultTextStyle.merge(maxLines: 1, child: label)),
                                      if (trailing case final trailing?)
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(start: metrics.gap),
                                          child: trailing,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    final message = tooltip ?? _labelText;
    // Only while there is nothing to read in the row itself.
    if (open > 0.5 || message == null) return row;

    return MochiTooltip(message: message, child: row);
  }

  String? get _labelText => label is Text ? (label as Text).data : null;
}

/// A heading over a set of [MochiSidebarItem]s, optionally collapsing them.
///
/// Two different things open and close in a sidebar, and this is the inner one: the group's own
/// items folding away under its heading. The outer one is the sidebar itself narrowing to a rail
/// ([MochiSidebar.collapsed]), which hides these headings altogether — a heading over icons says
/// nothing.
class MochiSidebarGroup extends StatelessWidget {
  const MochiSidebarGroup({
    super.key,
    required this.children,
    this.label,
    this.collapsible = false,
    this.expanded,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
  });

  final List<Widget> children;

  /// Over the items, in muted small text.
  final Widget? label;

  /// Whether pressing the heading folds the items away.
  final bool collapsible;

  /// Owns the state when non-null, as [MochiCollapsible] does.
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final open = _SidebarScope.of(context);

    final items = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: g.space.xs3,
      children: children,
    );

    final label = this.label;
    // A rail has no room for a heading, and no need for one: the items are icons in a line.
    if (label == null || open < 0.5) {
      return Padding(
        padding: EdgeInsets.only(top: g.space.xs2),
        child: items,
      );
    }

    final heading = DefaultTextStyle.merge(
      style: theme.typography.body.xs
          .withWeight(FontWeight.w600)
          .copyWith(color: theme.colors.mutedForeground),
      maxLines: 1,
      child: label,
    );

    return Padding(
      padding: EdgeInsets.only(top: g.space.sm),
      child: collapsible
          ? MochiCollapsible(
              title: heading,
              expanded: expanded,
              initiallyExpanded: initiallyExpanded,
              onExpandedChanged: onExpandedChanged,
              headerPadding: EdgeInsets.symmetric(horizontal: g.space.xs2, vertical: g.space.xs3),
              radius: g.radius.sm,
              child: Padding(
                padding: EdgeInsets.only(top: g.space.xs3),
                child: items,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: g.space.xs3,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: g.space.xs2, vertical: g.space.xs3),
                  child: heading,
                ),
                items,
              ],
            ),
    );
  }
}

/// A sidebar's own heading or footer row: padded like the items, and cut down with them.
class MochiSidebarHeading extends StatelessWidget {
  const MochiSidebarHeading(this.child, {super.key, this.collapsedChild});

  final Widget child;

  /// Shown in place of [child] while the sidebar is a rail — a mark instead of a name.
  final Widget? collapsedChild;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final open = _SidebarScope.of(context);
    final metrics = _SidebarMetrics.of(theme);
    final railed = open < 0.5;

    return Container(
      height: metrics.height + 2 * g.space.xs2,
      padding: EdgeInsets.symmetric(horizontal: g.space.xs2 + metrics.inset),
      alignment: railed ? Alignment.center : AlignmentDirectional.centerStart,
      child: DefaultTextStyle.merge(
        style: theme.typography.title.md.copyWith(color: theme.colors.foreground),
        maxLines: 1,
        child: railed ? (collapsedChild ?? child) : child,
      ),
    );
  }
}

/// The parts of a sidebar row that change with the theme's scale.
@immutable
class _SidebarMetrics {
  const _SidebarMetrics({
    required this.height,
    required this.inset,
    required this.gap,
    required this.iconSize,
  });

  factory _SidebarMetrics.of(MochiTheme theme) => _SidebarMetrics(
    height: (theme.touch ? 44 : 34) * theme.density,
    // Half the icon's box, so an icon sits in the middle of a rail.
    inset: theme.touch ? 14 : 11,
    gap: theme.geometry.space.xs,
    iconSize: theme.touch ? 20 : 18,
  );

  final double height;
  final double inset;
  final double gap;
  final double iconSize;
}
