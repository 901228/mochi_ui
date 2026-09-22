import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";

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
  });

  /// The destination the app is at.
  final T value;

  /// Null disables the whole bar.
  final ValueChanged<T>? onChanged;

  final List<MochiBottomNavItem<T>> items;
  final MochiIntent intent;

  /// Labels under the icons. Off, only the chosen one says what it is.
  final bool showLabels;

  /// Defaults to `colors.surface`.
  final Color? background;

  /// Whether to draw a line along its top edge, against the page.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;

    return Container(
      decoration: BoxDecoration(
        color: background ?? colors.surface,
        border: border
            ? Border(
                top: BorderSide(color: colors.border, width: g.borderWidth),
              )
            : null,
      ),
      // The bar runs to the bottom of the screen, so the inset is its own to clear.
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      // Not stretched: the bar sizes to its destinations, which are as tall as each other, and a
      // stretch would hand them the unbounded height of the column they sit at the bottom of.
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _Destination<T>(
                item: item,
                selected: item.value == value,
                intent: intent,
                showLabel: showLabels,
                onPress: onChanged == null || !item.enabled || item.value == value
                    ? null
                    : () => onChanged!(item.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Destination<T> extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.selected,
    required this.intent,
    required this.showLabel,
    required this.onPress,
  });

  final MochiBottomNavItem<T> item;
  final bool selected;
  final MochiIntent intent;
  final bool showLabel;
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

          return MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: g.radius.sm,
            inset: true,
            child: Opacity(
              opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
              child: SizedBox(
                height: height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: g.space.xs3,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: g.space.sm, vertical: g.space.xs3),
                      decoration: ShapeDecoration(
                        // The pill is what marks the destination; the press and hover layers sit
                        // on top of it.
                        color: blend.color(
                          (st) => st.contains(WidgetState.selected)
                              ? MochiColors.stateLayer(colors.softOn(tone, colors.surface), tone.onSoft, st)
                              : MochiColors.stateLayer(colors.surface, colors.foreground, st),
                        ),
                        shape: RoundedSuperellipseBorder(borderRadius: g.radius.full),
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
