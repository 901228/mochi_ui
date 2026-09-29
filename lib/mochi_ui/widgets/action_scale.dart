import "package:flutter/widgets.dart";

import "../theme/size.dart";

/// The size controls take in a slot that has already decided how much room they get.
///
/// A card's title row is one: it is an `xs` button tall, so a bar of actions put there should be
/// an `xs` bar without the app having to say so — and a bar cannot see where it has been put.
/// Anything passed explicitly still wins; this is only the default.
///
/// Not exported: it is a conversation between a slot and what an app drops into it.
class ActionScale extends InheritedWidget {
  const ActionScale({required this.size, required super.child, super.key});

  final MochiSize size;

  static MochiSize? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActionScale>()?.size;

  @override
  bool updateShouldNotify(ActionScale old) => old.size != size;
}
