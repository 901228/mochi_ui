import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// The title line a dialog and a sheet share: the title in the `title` typeface, and whatever
/// belongs to the panel rather than to the answer at the end of it. One widget, so the two can't
/// drift apart in size or spacing. Not exported.
class ModalHeading extends StatelessWidget {
  const ModalHeading({super.key, required this.title, required this.suffix});

  final Widget? title;
  final Widget? suffix;

  /// The gap under the heading, which belongs to it rather than to what follows: without a
  /// heading, the content starts at the padding like any other panel's.
  static double gapOf(BuildContext context) => context.theme.geometry.space.xs;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      spacing: theme.geometry.space.sm,
      children: [
        Expanded(
          child: DefaultTextStyle(
            style: theme.typography.title.md.copyWith(color: theme.colors.foreground),
            child: title ?? const SizedBox.shrink(),
          ),
        ),
        ?suffix,
      ],
    );
  }
}
