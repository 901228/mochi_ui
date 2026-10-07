import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/geometry.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";
import "shape_shadow.dart";

/// How a [MochiBottomNav] sits at the bottom of the screen.
enum MochiBottomNavVariant {
  /// Across the whole width, against the bottom edge: a desktop's or a web page's bar.
  docked,

  /// Clear of the edges, rounded, standing over the content: a phone's bar. Each destination is
  /// a rounded block of its own inside it, the chosen one filled.
  floating,
}

/// One destination in a [MochiBottomNav].
class MochiBottomNavItem<T> {
  const MochiBottomNavItem({
    required this.value,
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
    this.enabled = true,
  });

  /// What `onChanged` is called with when this one is pressed.
  final T value;

  final Widget icon;

  /// Shown in place of [icon] while this is where the app is — a filled version of the same
  /// shape, usually.
  final Widget? selectedIcon;

  final Widget label;

  /// Over the icon's trailing corner: a count, a dot.
  final Widget? badge;

  final bool enabled;
}

/// The bar of destinations along the bottom of a phone: timer, statistics, settings.
///
/// The same job as [MochiSidebar] on a wide screen, which is why it takes the same kind of list
/// and leaves the page to the app. Destinations share the width equally; the chosen one is
/// tinted and carries a soft pill behind its icon.
///
/// A phone's bar, not a desktop's: on a wide screen the same destinations belong in a
/// [MochiSidebar], and an app switches between the two at a breakpoint (`context.responsive`).
/// Docked is for what is left — a desktop window narrowed to a phone's layout, a phone's browser
/// that does not count as touch.
///
/// It clears the system's bottom inset itself, so it goes straight at the bottom of a
/// [MochiScaffold] without a `SafeArea` around it.
class MochiBottomNav<T> extends StatelessWidget {
  const MochiBottomNav({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.intent = MochiIntent.primary,
    this.showLabels = true,
    this.background,
    this.border = true,
    this.variant,
  });

  /// The destination the app is at.
  final T value;

  /// Null disables the whole bar.
  final ValueChanged<T>? onChanged;

  final List<MochiBottomNavItem<T>> items;
  final MochiIntent intent;

  /// Labels under the icons. Off, only the chosen one says what it is.
  final bool showLabels;

  /// Defaults to `colors.surface`, or `colors.overlay` in the raised look.
  final Color? background;

  /// Whether to draw a line along its top edge, against the page. The raised look has none, and
  /// neither does a floating bar, which is drawn as a whole shape instead.
  final bool border;

  /// Null follows the theme's layering: floating when raised, docked when outlined — a raised bar
  /// is the phone's, and a phone's bar stands clear of the edges.
  final MochiBottomNavVariant? variant;

  /// The widest a floating bar gets: on a tablet, a bar the whole width of the screen would be a
  /// long thin strip with a few icons lost in it.
  static const maxFloatingWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    // A raised bar is lit and lifted like a raised card, and has no line along its top: the shadow
    // is what sets it off the page.
    final raised = theme.layering == .raised;
    final ground = background ?? (raised ? colors.overlay : colors.surface);
    final floating =
        (variant ?? (raised ? MochiBottomNavVariant.floating : MochiBottomNavVariant.docked)) == .floating;

    // A hair between destinations, so a hovered one beside the chosen one reads as two blocks
    // rather than one.
    Widget row({required bool floating}) => Row(
      spacing: g.space.xs2,
      children: [
        for (final item in items)
          Expanded(
            child: _Destination<T>(
              item: item,
              selected: item.value == value,
              intent: intent,
              ground: ground,
              showLabel: showLabels,
              floating: floating,
              onPress: onChanged == null || !item.enabled || item.value == value
                  ? null
                  : () => onChanged!(item.value),
            ),
          ),
      ],
    );

    if (floating) {
      // The destinations sit in by exactly the difference between the two corners, so a chosen
      // one's curve runs alongside the bar's rather than cutting across it — whatever corners the
      // theme has been given.
      final inset = g.radius.xl.topLeft.x - g.radius.lg.topLeft.x;
      final bottom = MediaQuery.paddingOf(context).bottom;

      return Padding(
        // Over the home indicator, not on it: the system's inset, and a little room above it.
        padding: EdgeInsets.fromLTRB(
          g.space.md,
          g.space.xs,
          g.space.md,
          bottom + (bottom > 0 ? g.space.xs : g.space.md),
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxFloatingWidth),
            child: ShapeShadow(
              radius: g.radius.xl,
              shadows: raised ? g.shadows.raised(MochiElevation.lg, colors) : null,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: ground,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: g.radius.xl,
                    side: raised || !border
                        ? BorderSide(color: ground.withValues(alpha: 0), width: g.borderWidth)
                        : BorderSide(color: colors.border, width: g.borderWidth),
                  ),
                ),
                child: Padding(padding: EdgeInsets.all(inset), child: row(floating: true)),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ground,
        boxShadow: raised ? g.shadows.raised(MochiElevation.md, colors, up: true) : null,
        border: border && !raised
            ? Border(
                top: BorderSide(color: colors.border, width: g.borderWidth),
              )
            : null,
      ),
      // The bar runs to the bottom of the screen, so the inset is its own to clear.
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      // Not stretched: the bar sizes to its destinations, which are as tall as each other, and a
      // stretch would hand them the unbounded height of the column they sit at the bottom of.
      child: row(floating: false),
    );
  }
}

class _Destination<T> extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.selected,
    required this.intent,
    required this.ground,
    required this.showLabel,
    required this.floating,
    required this.onPress,
  });

  final MochiBottomNavItem<T> item;
  final bool selected;
  final MochiIntent intent;

  /// What the bar is filled with, which the pill and its hover layer are mixed over.
  final Color ground;
  final bool showLabel;

  /// In a floating bar the whole destination is the block that is filled; docked, only the pill
  /// behind the icon.
  final bool floating;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final height = theme.touch ? 60.0 : 52.0;
    final iconSize = theme.touch ? 24.0 : 22.0;

    return MochiTappable(
      enabled: item.enabled && onPress != null,
      selected: selected,
      // A fixed place along the bottom: it tints rather than growing.
      scaleOnPress: false,
      onPress: onPress,
      builder: (context, states, _) => MochiStateTransition(
        states: {...states, if (selected) WidgetState.selected},
        duration: theme.motion.stateDuration,
        builder: (context, blend) {
          final foreground = blend.color(
            (st) => st.contains(WidgetState.selected) ? tone.onSoft : colors.mutedForeground,
          );

          // The press and hover layers sit on top of the fill that marks the destination.
          final fill = blend.color(
            (st) => st.contains(WidgetState.selected)
                ? MochiColors.stateLayer(colors.softOn(tone, ground), tone.onSoft, st)
                : MochiColors.stateLayer(ground, colors.foreground, st),
          );
          final cell = floating ? g.radius.lg : g.radius.sm;

          return MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: cell,
            inset: true,
            child: Opacity(
              opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
              child: Container(
                height: height,
                decoration: floating
                    ? ShapeDecoration(
                        color: fill,
                        shape: RoundedSuperellipseBorder(borderRadius: cell),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: g.space.xs3,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: g.space.sm, vertical: g.space.xs3),
                      decoration: floating
                          ? null
                          : ShapeDecoration(
                              color: fill,
                              // `sm`, not the floating cell's `lg`: the block is little taller than
                              // the icon, and a corner past half its height would round it into a pill.
                              shape: RoundedSuperellipseBorder(borderRadius: g.radius.sm),
                            ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconTheme.merge(
                            data: IconThemeData(color: foreground, size: iconSize),
                            child: selected ? (item.selectedIcon ?? item.icon) : item.icon,
                          ),
                          if (item.badge case final badge?)
                            PositionedDirectional(top: -g.space.xs2, end: -g.space.sm, child: badge),
                        ],
                      ),
                    ),
                    if (showLabel || selected)
                      DefaultTextStyle(
                        style: theme.typography.body.xs2
                            .withWeight(selected ? FontWeight.w600 : FontWeight.w400)
                            .copyWith(color: foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: item.label,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
