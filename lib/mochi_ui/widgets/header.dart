import "package:flutter/widgets.dart";

import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";

enum MochiHeaderAlignment { start, center }

/// Whether the header is separated from the content below it.
enum MochiHeaderVariant {
  /// Sits directly on the page background.
  plain,

  /// A surface with a hairline along its bottom edge, for pages that scroll under it.
  bordered,

  /// Inset from the page edges with a border all the way around: a bar that floats above the
  /// content instead of capping the page.
  floating,
}

/// The bar at the top of a [MochiScaffold]: a title with actions on either side.
///
/// A pushed page puts [MochiHeaderAction.back] in [prefixes]; there is no separate nested
/// variant, since that was the only difference.
class MochiHeader extends StatelessWidget {
  const MochiHeader({
    super.key,
    required this.title,
    this.prefixes = const [],
    this.suffixes = const [],
    this.alignment = MochiHeaderAlignment.start,
    this.variant = MochiHeaderVariant.plain,
  });

  final Widget title;

  /// Leading actions, usually [MochiHeaderAction.back].
  final List<Widget> prefixes;
  final List<Widget> suffixes;

  /// Where the title sits between the two action groups.
  final MochiHeaderAlignment alignment;

  final MochiHeaderVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    final border = BorderSide(color: theme.colors.border, width: g.borderWidth);

    return Container(
      margin: switch (variant) {
        .plain || .bordered => EdgeInsets.zero,
        .floating => EdgeInsets.all(g.space.xs),
      },
      padding: EdgeInsets.symmetric(horizontal: g.space.md, vertical: g.space.sm),
      decoration: switch (variant) {
        .plain => null,
        .bordered => BoxDecoration(
          color: theme.colors.surface,
          border: Border(bottom: border),
        ),
        .floating => ShapeDecoration(
          color: theme.colors.surface,
          shape: RoundedSuperellipseBorder(borderRadius: g.radius.md, side: border),
        ),
      },
      child: Row(
        spacing: g.space.xs,
        children: [
          ...prefixes,
          Expanded(
            child: Align(
              alignment: switch (alignment) {
                .start => AlignmentDirectional.centerStart,
                .center => Alignment.center,
              },
              child: DefaultTextStyle(
                style: theme.typography.title.lg.copyWith(color: theme.colors.foreground),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                child: title,
              ),
            ),
          ),
          ...suffixes,
        ],
      ),
    );
  }
}

/// An icon button sized for [MochiHeader].
class MochiHeaderAction extends StatelessWidget {
  const MochiHeaderAction({
    super.key,
    required this.icon,
    required this.onPress,
    this.intent = MochiIntent.neutral,
    this.tooltip,
    this.enabled = true,
  }) : _icon = null;

  /// Navigates back, using [MochiIcons.back].
  const MochiHeaderAction.back({
    super.key,
    required this.onPress,
    this.intent = MochiIntent.neutral,
    this.tooltip = "Back",
    this.enabled = true,
  }) : icon = null,
       _icon = _Builtin.back;

  /// Dismisses the page, using [MochiIcons.close].
  const MochiHeaderAction.close({
    super.key,
    required this.onPress,
    this.intent = MochiIntent.neutral,
    this.tooltip = "Close",
    this.enabled = true,
  }) : icon = null,
       _icon = _Builtin.close;

  final Widget? icon;
  final VoidCallback? onPress;
  final MochiIntent intent;
  final String? tooltip;
  final bool enabled;

  final _Builtin? _icon;

  @override
  Widget build(BuildContext context) {
    final icons = context.theme.icons;

    return MochiButton.icon(
      intent: intent,
      appearance: MochiButtonAppearance.ghost,
      size: MochiButtonSize.sm,
      enabled: enabled,
      tooltip: tooltip,
      onPress: onPress,
      icon:
          icon ??
          Icon(switch (_icon!) {
            .back => icons.back,
            .close => icons.close,
          }),
    );
  }
}

enum _Builtin { back, close }
