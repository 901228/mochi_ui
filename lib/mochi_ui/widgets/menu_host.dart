import "package:flutter/widgets.dart";

/// What a `MochiMenuItem` with `closeOnPress` puts away once it has been chosen.
///
/// A popover menu installs one that closes the outermost panel, so choosing something in a
/// submenu puts the whole thing away; a select shown in a sheet installs one that pops the sheet.
/// The rows only need to know there is something to close, not what it is.
///
/// Not exported: it is a conversation between a list of rows and whatever is showing them.
class MenuHost extends InheritedWidget {
  const MenuHost({required this.close, required super.child, super.key});

  final VoidCallback close;

  static VoidCallback? of(BuildContext context) => context.getInheritedWidgetOfExactType<MenuHost>()?.close;

  @override
  bool updateShouldNotify(MenuHost old) => old.close != close;
}
