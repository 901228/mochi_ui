import "dart:ui" show lerpDouble;

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "divider.dart";
import "focus_ring.dart";
import "popover.dart";
import "state_transition.dart";
import "tappable.dart";
import "value_transition.dart";

/// The menu an item belongs to, so a [MochiMenuItem] can close the whole menu when it is chosen.
///
/// Only the outermost menu installs one, so an item in a submenu closes the menu it was opened
/// from rather than just its own panel.
class _MenuHost extends InheritedWidget {
  const _MenuHost({required this.controller, required super.child});

  final MenuController controller;

  static MenuController? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MenuHost>()?.controller;

  @override
  bool updateShouldNotify(_MenuHost old) => old.controller != controller;
}

/// The parts of a menu row's layout that change with the theme's scale.
@immutable
class _MenuMetrics {
  const _MenuMetrics({required this.minHeight, required this.padding, required this.iconSize});

  factory _MenuMetrics.of(MochiTheme theme) => _MenuMetrics(
    minHeight: theme.touch ? 40 : 30,
    padding: theme.touch ? theme.geometry.space.xs : theme.geometry.space.xs2,
    iconSize: theme.touch ? 18 : 16,
  );

  final double minHeight;
  final double padding;
  final double iconSize;

  static _MenuMetrics lerp(_MenuMetrics a, _MenuMetrics b, double t) => _MenuMetrics(
    minHeight: lerpDouble(a.minHeight, b.minHeight, t)!,
    padding: lerpDouble(a.padding, b.padding, t)!,
    iconSize: lerpDouble(a.iconSize, b.iconSize, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is _MenuMetrics &&
      minHeight == other.minHeight &&
      padding == other.padding &&
      iconSize == other.iconSize;

  @override
  int get hashCode => Object.hash(minHeight, padding, iconSize);
}

/// The body of a menu: [MochiMenuItem]s, [MochiMenuDivider]s and [MochiMenuLabel]s in a column.
///
/// Sizes itself to its widest row and scrolls once it runs out of room, so it can be handed
/// straight to [MochiPopover]. Up and down arrows move between rows.
class MochiMenu extends StatelessWidget {
  const MochiMenu({super.key, required this.children, this.minWidth = 160});

  final List<Widget> children;

  /// Keeps a menu of short labels from looking like a sliver.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    // The arrow shortcuts RawMenuAnchor installs sit on the anchor, which the panel is a sibling
    // of, so the panel brings its own.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
        SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
      },
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: SingleChildScrollView(
          child: IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row in a [MochiMenu].
///
/// Closes the menu when pressed, so a handler doesn't have to. Pass an [intent] other than
/// [MochiIntent.neutral] for an action that needs to stand out — `danger` for a destructive one.
class MochiMenuItem extends StatelessWidget {
  const MochiMenuItem({
    super.key,
    required this.title,
    this.prefix,
    this.suffix,
    this.intent = MochiIntent.neutral,
    this.enabled = true,
    this.selected = false,
    this.onPress,
    this.closeOnPress = true,
    this.semanticLabel,
  });

  final Widget title;

  /// Leading widget, usually an icon.
  final Widget? prefix;

  /// Trailing widget: a shortcut, a check mark, a submenu chevron.
  final Widget? suffix;

  /// Colors the row. Neutral rows take the plain foreground; anything else is tinted throughout,
  /// not only while hovered, since the colour is what marks the action out.
  final MochiIntent intent;

  final bool enabled;
  final bool selected;
  final VoidCallback? onPress;

  /// Whether choosing this row closes the menu it belongs to, submenus included.
  final bool closeOnPress;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final host = closeOnPress ? _MenuHost.of(context) : null;

    return MochiTappable(
      enabled: enabled && onPress != null,
      selected: selected,
      semanticLabel: semanticLabel,
      // Rows keep their place in the list; they tint instead of growing.
      scaleOnPress: false,
      onPress: onPress == null
          ? null
          : () {
              onPress!();
              host?.close();
            },
      builder: (context, states, _) =>
          _MenuItemSurface(states: states, intent: intent, prefix: prefix, title: title, suffix: suffix),
    );
  }
}

class _MenuItemSurface extends StatelessWidget {
  const _MenuItemSurface({
    required this.states,
    required this.intent,
    required this.prefix,
    required this.title,
    required this.suffix,
  });

  final Set<WidgetState> states;
  final MochiIntent intent;
  final Widget? prefix;
  final Widget title;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    final neutral = intent == MochiIntent.neutral;

    // Rows sit on the panel, not on the page, so tints are mixed over the overlay colour.
    final selected = colors.softOn(tone, colors.overlay);
    final resting = neutral ? colors.foreground : tone.onSoft;

    Color background(Set<WidgetState> st) => st.contains(WidgetState.selected)
        ? MochiColors.stateLayer(selected, tone.onSoft, st)
        // A tinted row hovers in its own colour rather than plain grey.
        : MochiColors.stateLayer(colors.overlay, neutral ? colors.foreground : tone.base, st);

    Color foreground(Set<WidgetState> st) => st.contains(WidgetState.selected) ? tone.onSoft : resting;

    return MochiValueTransition(
      value: _MenuMetrics.of(theme),
      lerp: _MenuMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, metrics, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) {
          final fg = blend.color(foreground);

          return MochiFocusRing(
            visible: blend.contains(WidgetState.focused),
            radius: g.radius.xs,
            // The panel clips its content, so the ring has to be painted inside the row.
            inset: true,
            child: Container(
              decoration: ShapeDecoration(
                color: blend.color(background),
                shape: RoundedSuperellipseBorder(borderRadius: g.radius.xs),
              ),
              padding: EdgeInsets.symmetric(horizontal: g.space.xs, vertical: metrics.padding),
              constraints: BoxConstraints(minHeight: metrics.minHeight),
              child: Opacity(
                opacity: blend.contains(WidgetState.disabled) ? 0.4 : 1,
                child: IconTheme.merge(
                  data: IconThemeData(color: fg, size: metrics.iconSize),
                  child: DefaultTextStyle(
                    style: theme.typography.body.sm.copyWith(color: fg),
                    child: Row(
                      spacing: g.space.xs,
                      children: [
                        ?prefix,
                        Expanded(child: title),
                        if (suffix case final suffix?)
                          DefaultTextStyle.merge(
                            style: TextStyle(
                              color: blend.color(
                                (st) =>
                                    st.contains(WidgetState.selected) ? tone.onSoft : colors.mutedForeground,
                              ),
                            ),
                            child: suffix,
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
  }
}

/// Separates groups of rows in a [MochiMenu].
class MochiMenuDivider extends StatelessWidget {
  const MochiMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.theme.geometry.space.xs2;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: space / 2),
      child: const MochiDivider(),
    );
  }
}

/// A heading above a group of rows in a [MochiMenu].
class MochiMenuLabel extends StatelessWidget {
  const MochiMenuLabel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: g.space.xs, vertical: g.space.xs2),
      child: DefaultTextStyle(
        style: theme.typography.body.xs
            .withWeight(FontWeight.w600)
            .copyWith(color: theme.colors.mutedForeground),
        child: child,
      ),
    );
  }
}

/// A [MochiPopover] holding a [MochiMenu]: the usual "⋮" or dropdown menu.
///
/// ```dart
/// MochiPopoverMenu(
///   menuBuilder: (context) => [MochiMenuItem(title: const Text("Rename"), onPress: rename)],
///   builder: (context, anchor, _) => MochiButton.icon(
///     focusNode: anchor.focusNode,
///     onPress: anchor.toggle,
///     child: const Icon(TablerIcons.dots),
///   ),
/// )
/// ```
class MochiPopoverMenu extends StatelessWidget {
  const MochiPopoverMenu({
    super.key,
    required this.menuBuilder,
    required this.builder,
    this.controller,
    this.child,
    this.side = MochiPopoverSide.bottom,
    this.align = MochiPopoverAlign.end,
    this.gap,
    this.minWidth = 160,
    this.constraints,
    this.onOpen,
    this.onClose,
  });

  /// Builds the rows. Called each time the menu opens, so the rows can reflect current state.
  final List<Widget> Function(BuildContext context) menuBuilder;

  final MochiPopoverBuilder builder;
  final Widget? child;
  final MenuController? controller;
  final MochiPopoverSide side;
  final MochiPopoverAlign align;

  /// Distance between the anchor and the panel. Defaults to `geometry.space.xs2`.
  final double? gap;

  final double minWidth;
  final BoxConstraints? constraints;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return MochiPopover(
      controller: controller,
      side: side,
      align: align,
      gap: gap,
      constraints: constraints,
      // Rows carry their own padding, so the panel only insets them from its corners.
      padding: EdgeInsets.all(context.theme.geometry.space.xs2),
      onOpen: onOpen,
      onClose: onClose,
      popoverBuilder: (context) => _MenuPanel(minWidth: minWidth, children: menuBuilder(context)),
      builder: builder,
      child: child,
    );
  }
}

/// Opens a [MochiMenu] where the pointer is, on a right click or a long press.
///
/// The menu's own gestures are registered above [child], so a child with its own long press (a
/// row that selects on long press, say) wins the arena and the menu doesn't open there.
class MochiContextMenu extends StatelessWidget {
  const MochiContextMenu({
    super.key,
    required this.menuBuilder,
    required this.child,
    this.controller,
    this.longPress = true,
    this.secondaryTap = true,
    this.minWidth = 160,
    this.constraints,
    this.onOpen,
    this.onClose,
  });

  /// Builds the rows. Called each time the menu opens, so the rows can reflect current state.
  final List<Widget> Function(BuildContext context) menuBuilder;

  final Widget child;
  final MenuController? controller;

  /// Opens on a long press. The usual way in on touch.
  final bool longPress;

  /// Opens on a right click. The usual way in with a mouse.
  final bool secondaryTap;

  final double minWidth;
  final BoxConstraints? constraints;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return MochiPopoverMenu(
      controller: controller,
      align: MochiPopoverAlign.start,
      // The panel's corner goes exactly where the pointer was; there is no anchor to clear.
      gap: 0,
      minWidth: minWidth,
      constraints: constraints,
      menuBuilder: menuBuilder,
      onOpen: onOpen,
      onClose: onClose,
      child: child,
      builder: (context, anchor, child) => GestureDetector(
        // Opaque would swallow taps meant for the child.
        behavior: HitTestBehavior.translucent,
        onSecondaryTapUp: secondaryTap ? (details) => anchor.open(position: details.localPosition) : null,
        onLongPressStart: longPress
            ? (details) {
                HapticFeedback.selectionClick();
                anchor.open(position: details.localPosition);
              }
            : null,
        child: child,
      ),
    );
  }
}

/// Hosts the rows and marks this menu as the one an item closes.
class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.minWidth, required this.children});

  final double minWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final controller = MenuController.maybeOf(context);
    final menu = MochiMenu(minWidth: minWidth, children: children);

    return controller == null ? menu : _MenuHost(controller: controller, child: menu);
  }
}
