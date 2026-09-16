import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// A page: an optional header, the content, and an optional footer, on the theme background.
///
/// The content is padded with [MochiGeometry.pagePadding] unless [padding] says otherwise, and
/// fills the space left between header and footer.
class MochiScaffold extends StatelessWidget {
  const MochiScaffold({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
    this.background,
    this.safeArea = true,
  });

  final Widget child;
  final Widget? header;
  final Widget? footer;

  /// Defaults to [MochiGeometry.pagePadding]; pass [EdgeInsets.zero] for edge-to-edge content.
  final EdgeInsetsGeometry? padding;

  /// Defaults to [MochiColors.background].
  final Color? background;

  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final body = Column(
      children: [
        ?header,
        Expanded(
          child: Padding(padding: padding ?? theme.geometry.pagePadding, child: child),
        ),
        ?footer,
      ],
    );

    return ColoredBox(
      color: background ?? theme.colors.background,
      child: safeArea ? SafeArea(child: body) : body,
    );
  }
}
