import "package:flutter/foundation.dart" show listEquals;
import "package:flutter/widgets.dart";

import "../theme/responsive.dart";
import "../theme/size.dart";
import "action_scale.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "menu.dart";

/// One thing a bar of actions can do: an icon, the words for it, and what pressing it does.
///
/// A value rather than a widget, because the same action is drawn two ways — as an icon button
/// while there is room for it, and as a row in a menu once there isn't — and only a value can be
/// drawn twice. That is also why [label] is a `String` and not a `Widget`: it is the menu row's
/// text as well as the button's tooltip and its name to a screen reader, the same bargain
/// `MochiSelectOption` makes.
///
/// ```dart
/// MochiHeader(
///   title: const Text("Session"),
///   prefixes: [MochiAction.back(onPress: () => Navigator.of(context).pop())],
///   suffixes: [
///     MochiAction(icon: TablerIcons.share, label: "Share", onPress: share),
///     MochiAction(icon: TablerIcons.trash, label: "Delete", intent: .danger, onPress: delete),
///   ],
/// )
/// ```
@immutable
class MochiAction {
  const MochiAction({
    this.icon,
    required String this.label,
    required this.onPress,
    this.showLabel = false,
    this.selected = false,
    this.intent = MochiIntent.neutral,
    this.enabled = true,
  }) : _builtin = null,
       children = null,
       assert(icon != null || showLabel, "An action with no icon has to show its label.");

  /// Opens a menu of [children] rather than doing something itself — a sort order, a group of
  /// exports. Its rows are actions too, and not widgets, because this one is drawn two ways like
  /// any other: a button that opens a dropdown while there is room, and a row that opens a
  /// submenu once it has been folded into the …. A menu of widgets could only be the first.
  const MochiAction.menu({
    this.icon,
    required String this.label,
    required List<MochiAction> this.children,
    this.showLabel = false,
    this.intent = MochiIntent.neutral,
    this.enabled = true,
  }) : onPress = null,
       selected = false,
       _builtin = null,
       assert(icon != null || showLabel, "An action with no icon has to show its label.");

  /// Goes back, with [MochiIcons.back] and [MochiStrings.back].
  const MochiAction.back({required this.onPress, this.intent = MochiIntent.neutral, this.enabled = true})
    : icon = null,
      label = null,
      showLabel = false,
      selected = false,
      children = null,
      _builtin = _Builtin.back;

  /// Closes what it is in, with [MochiIcons.close] and [MochiStrings.close].
  const MochiAction.close({required this.onPress, this.intent = MochiIntent.neutral, this.enabled = true})
    : icon = null,
      label = null,
      showLabel = false,
      selected = false,
      children = null,
      _builtin = _Builtin.close;

  /// Null only for the two built-in actions, which take theirs from the theme.
  final IconData? icon;

  /// What it says: the menu row's text, the button's tooltip, and its name in semantics. Null
  /// only for the two built-in actions.
  final String? label;

  /// Null disables the action, the same rule as everywhere else — except on a menu, which has
  /// none and is disabled by having no [children] instead.
  final VoidCallback? onPress;

  /// The rows a [MochiAction.menu] opens. Null for every other action.
  final List<MochiAction>? children;

  /// Whether the label is written out beside the icon rather than kept for the tooltip. An action
  /// with no icon shows it whatever this says, since otherwise there would be nothing to press.
  final bool showLabel;

  /// For an action that is a switch rather than an errand — a view that is on, a mode that is
  /// chosen. It tints the button and ticks the menu row.
  final bool selected;

  final MochiIntent intent;
  final bool enabled;

  final _Builtin? _builtin;

  bool get _enabled => enabled && (onPress != null || (children?.isNotEmpty ?? false));

  /// The built-ins have no `icon` of their own — theirs comes from the theme — so an action is
  /// only words when it is neither.
  bool get _showsLabel => showLabel || (icon == null && _builtin == null);

  /// The icon to draw, which for the two built-ins comes from the theme. Null for an action that
  /// is only words.
  IconData? iconOf(MochiTheme theme) =>
      icon ??
      switch (_builtin) {
        _Builtin.back => theme.icons.back,
        _Builtin.close => theme.icons.close,
        null => null,
      };

  String labelOf(MochiTheme theme) =>
      label ??
      switch (_builtin!) {
        _Builtin.back => theme.strings.back,
        _Builtin.close => theme.strings.close,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiAction &&
          icon == other.icon &&
          label == other.label &&
          onPress == other.onPress &&
          showLabel == other.showLabel &&
          selected == other.selected &&
          intent == other.intent &&
          enabled == other.enabled &&
          listEquals(children, other.children) &&
          _builtin == other._builtin;

  @override
  int get hashCode => Object.hash(
    icon,
    label,
    onPress,
    showLabel,
    selected,
    intent,
    enabled,
    Object.hashAll(children ?? const []),
    _builtin,
  );
}

/// One action as a menu row: a submenu when it is a menu itself, which is what keeps a folded
/// menu action working — and, since its rows go through here too, a menu inside it as well.
Widget _menuRow(MochiAction action, MochiTheme theme) {
  final prefix = switch (action.iconOf(theme)) {
    final icon? => Icon(icon),
    null => null,
  };
  final children = action.children;
  if (children != null) {
    return MochiSubmenu(
      title: Text(action.labelOf(theme)),
      prefix: prefix,
      enabled: action._enabled,
      menuBuilder: (context) => [for (final child in children) _menuRow(child, theme)],
    );
  }

  return MochiMenuItem(
    title: Text(action.labelOf(theme)),
    prefix: prefix,
    intent: action.intent,
    enabled: action._enabled,
    selected: action.selected,
    onPress: action.onPress,
  );
}

enum _Builtin { back, close }

/// A row of [MochiAction]s that folds into a … once there are more of them than [maxVisible].
///
/// The last slot is the …, so a row of four with a cap of three shows two buttons and a menu
/// holding the other two — the row is [maxVisible] slots wide whatever it is given, which is the
/// same bargain [MochiPagination] makes.
///
/// The cap is a count rather than a measurement on purpose. The bar usually sits at one end of a
/// row whose middle is the flexible part (a header's title), so it is offered an unbounded width
/// and has nothing to measure against; and a count is what an app can reason about while it is
/// deciding which actions matter. It defaults by breakpoint — two on a phone, four from tablet
/// width up — since that is what the rest of the kit uses to decide how much fits.
class MochiActionBar extends StatelessWidget {
  const MochiActionBar(
    this.actions, {
    super.key,
    this.maxVisible,
    this.size,
    this.appearance = MochiButtonAppearance.ghost,
    this.dense = false,
    this.scaleOnPress = true,
    this.menuLabel,
  }) : assert(maxVisible == null || maxVisible > 0);

  final List<MochiAction> actions;

  /// How many slots the row has, the … included. Defaults to two on a phone and four above it.
  final int? maxVisible;

  /// Defaults to what the slot the bar sits in asks for — a card's title row wants `xs` — and to
  /// `sm` where nothing has an opinion.
  final MochiSize? size;

  final MochiButtonAppearance appearance;

  /// Squares the buttons down to their icons, so a bar sits inside a line of text without making
  /// it taller — a card's title row, a tile's trailing end. Even the smallest button is taller
  /// than a line of text, since it is built to be aimed at; this trades that target for a row
  /// that does not grow, which is only worth it where the bar is beside words rather than
  /// standing on its own.
  final bool dense;

  /// Whether a press grows the button. A bar at the top of a page wants it; one tucked inside
  /// something with a border of its own — a field's suffix, a row in a list — does not, since the
  /// growth reads as the box itself moving. The bar cannot tell where it has been put, so this is
  /// the caller's to say.
  final bool scaleOnPress;

  /// Names the … for a screen reader. Defaults to `strings.more`.
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;
    final slots = maxVisible ?? context.responsive<int>(mobile: 2, tablet: 4);
    final size = this.size ?? ActionScale.of(context) ?? MochiSize.sm;
    final metrics = dense ? _dense(theme) : null;
    final folded = actions.length > slots;
    // The … takes the last slot, so what is written out is one fewer.
    final shown = folded ? actions.take(slots - 1).toList() : actions;
    final hidden = folded ? actions.skip(slots - 1).toList() : const <MochiAction>[];

    // The bar's own box is the bar's, gaps included: a press that lands between two buttons goes
    // to whatever is holding the bar otherwise — inside a search field's suffix that is the
    // field, which takes the focus and lights its ring for a press that was aimed at a button.
    // The layer sits *behind* the buttons, so a press on one hits the button and never reaches
    // it, and the nearest recognizer is the one that wins the arena's sweep.
    return Stack(
      children: [
        Positioned.fill(
          // Opaque, so it is hit where no button is — a detector that defers to its child is
          // never hit in a gap at all, which is the whole of the problem. A plain tap rather than
          // an eager claim: a drag that starts here should still scroll whatever is behind.
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: g.space.xs3,
          children: [
            for (final action in shown)
              _ActionButton(
                action: action,
                size: size,
                metrics: metrics,
                appearance: appearance,
                scaleOnPress: scaleOnPress,
              ),
            if (hidden.isNotEmpty)
              MochiPopoverMenu(
                menuBuilder: (context) => [for (final action in hidden) _menuRow(action, theme)],
                builder: (context, anchor, _) => MochiButton.icon(
                  size: size,
                  metrics: metrics,
                  appearance: appearance,
                  scaleOnPress: scaleOnPress,
                  intent: MochiIntent.neutral,
                  focusNode: anchor.focusNode,
                  onPress: anchor.toggle,
                  semanticLabel: menuLabel ?? theme.strings.more,
                  icon: Icon(theme.icons.more),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A button the size of its icon and a hair more, with no padding beside it: the row is then as
/// tall as the words it sits among rather than as tall as a thing to aim at.
MochiButtonMetrics _dense(MochiTheme theme) {
  final m = MochiButtonMetrics.of(MochiSize.xs, touch: theme.touch, density: theme.density);

  return MochiButtonMetrics(
    height: m.iconSize + 6,
    horizontalPadding: 0,
    gap: m.gap,
    iconSize: m.iconSize,
    radius: m.radius,
    textStyle: m.textStyle,
  );
}

/// One action as a button. Its label is the tooltip as well as its name, since an icon on its own
/// says nothing to a screen reader.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.size,
    required this.metrics,
    required this.appearance,
    required this.scaleOnPress,
  });

  final MochiAction action;
  final MochiSize size;
  final MochiButtonMetrics? metrics;
  final MochiButtonAppearance appearance;
  final bool scaleOnPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final children = action.children;
    if (children == null) return _button(theme, action.onPress);

    return MochiPopoverMenu(
      menuBuilder: (context) => [for (final child in children) _menuRow(child, theme)],
      builder: (context, anchor, _) => _button(theme, anchor.toggle, focusNode: anchor.focusNode),
    );
  }

  Widget _button(MochiTheme theme, VoidCallback? onPress, {FocusNode? focusNode}) {
    final icon = action.iconOf(theme);
    final label = action.labelOf(theme);

    // An icon on its own says nothing to a screen reader, so its label becomes the tooltip; one
    // that writes its label out has said it already.
    if (!action._showsLabel) {
      return MochiButton.icon(
        size: size,
        metrics: metrics,
        appearance: appearance,
        scaleOnPress: scaleOnPress,
        intent: action.intent,
        enabled: action._enabled,
        selected: action.selected,
        tooltip: label,
        focusNode: focusNode,
        onPress: onPress,
        icon: Icon(icon),
      );
    }

    return MochiButton(
      size: size,
      metrics: metrics,
      appearance: appearance,
      scaleOnPress: scaleOnPress,
      intent: action.intent,
      enabled: action._enabled,
      selected: action.selected,
      focusNode: focusNode,
      onPress: onPress,
      prefix: switch (icon) {
        final icon? => Icon(icon),
        null => null,
      },
      child: Text(label),
    );
  }
}
