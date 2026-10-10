import "package:flutter/widgets.dart";

/// Tells a `MochiSidebar` under it that it cannot narrow to a rail, whatever its `collapsed` says:
/// a scaffold's drawer is one, where a rail would only be a thinner drawer and its button one more
/// thing to press on the way to closing it.
///
/// Not exported: it is a conversation between the scaffold and the sidebar.
class FixedSidebar extends InheritedWidget {
  const FixedSidebar({required super.child, super.key});

  static bool of(BuildContext context) => context.getInheritedWidgetOfExactType<FixedSidebar>() != null;

  @override
  bool updateShouldNotify(FixedSidebar old) => false;
}
