import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "menu.dart";
import "popover.dart";

/// One menu in a [MochiMenubar].
class MochiMenubarMenu {
  const MochiMenubarMenu({
    required this.title,
    required this.menuBuilder,
    this.enabled = true,
    this.minWidth = 180,
  });

  /// The word in the bar: File, Session, Help.
  final Widget title;

  /// Builds the rows. Called each time the menu opens, so they can reflect current state.
  final List<Widget> Function(BuildContext context) menuBuilder;

  final bool enabled;
  final double minWidth;
}

/// The row of menus along the top of a desktop window: File, Session, View, Help.
///
/// Built from the pieces that already exist — a [MochiPopoverMenu] per menu, whose rows are
/// [MochiMenuItem]s and [MochiSubmenu]s. What it adds is the one behaviour a bar of menus has
/// that a single dropdown doesn't: once one is open, moving the pointer onto its neighbour opens
/// that one instead, with no press and no wait, and the arrows walk along the bar.
///
/// ```dart
/// MochiMenubar(
///   menus: [
///     MochiMenubarMenu(
///       title: const Text("Session"),
///       menuBuilder: (context) => [MochiMenuItem(title: const Text("New"), onPress: newSession)],
///     ),
///   ],
/// )
/// ```
class MochiMenubar extends StatefulWidget {
  const MochiMenubar({super.key, required this.menus, this.size = MochiSize.sm});

  final List<MochiMenubarMenu> menus;

  /// Of the words in the bar.
  final MochiSize size;

  @override
  State<MochiMenubar> createState() => _MochiMenubarState();
}

class _MochiMenubarState extends State<MochiMenubar> {
  final _controllers = <int, MenuController>{};

  /// Which menu is open, if any. A bar only ever has one.
  int? _open;

  MenuController _controllerFor(int index) => _controllers.putIfAbsent(index, MenuController.new);

  void _openAt(int index) {
    if (index < 0 || index >= widget.menus.length) return;
    if (!widget.menus[index].enabled) return;
    if (_open == index) return;

    // The one standing goes away first: two open menus at once is not a menubar.
    if (_open case final open?) _controllerFor(open).close();
    _controllerFor(index).open();
  }

  /// Along the bar, stepping over anything disabled and wrapping round the ends.
  void _move(int direction) {
    final open = _open;
    if (open == null) return;

    final count = widget.menus.length;
    for (var step = 1; step <= count; step++) {
      final next = (open + direction * step) % count;
      if (widget.menus[next].enabled) return _openAt(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.geometry.space.xs3,
      children: [
        for (final (index, menu) in widget.menus.indexed)
          MochiPopoverMenu(
            controller: _controllerFor(index),
            align: MochiPopoverAlign.start,
            minWidth: menu.minWidth,
            onOpen: () => setState(() => _open = index),
            onClose: () => setState(() {
              // Another menu may already have opened by now; only clear what is still ours.
              if (_open == index) _open = null;
            }),
            menuBuilder: menu.menuBuilder,
            builder: (context, anchor, _) => CallbackShortcuts(
              // Bound inside the anchor, under the traversal RawMenuAnchor installs: out there
              // the arrows would only move the focus along.
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowRight): () => _move(1),
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(-1),
              },
              child: MochiButton(
                size: widget.size,
                appearance: MochiButtonAppearance.ghost,
                intent: MochiIntent.neutral,
                // A word in a bar, not a button: pressing it drops a panel rather than doing
                // something, so it tints instead of growing.
                scaleOnPress: false,
                // The open one stays lit while its panel is down.
                selected: _open == index,
                enabled: menu.enabled,
                focusNode: anchor.focusNode,
                onPress: () => anchor.isOpen ? anchor.close() : _openAt(index),
                onHoverChange: (hovered) {
                  // Only while the bar is already open: pointing at a menubar shouldn't open
                  // anything by itself.
                  if (hovered && _open != null) _openAt(index);
                },
                child: menu.title,
              ),
            ),
          ),
      ],
    );
  }
}
