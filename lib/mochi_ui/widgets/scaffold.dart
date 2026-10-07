import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// A page: an optional header, the content, and an optional footer, on the theme background.
///
/// The content is padded with [MochiGeometry.pagePadding] unless [padding] says otherwise, and
/// fills the space left between header and footer — or, with [extendBody], the whole page, with
/// the bars standing over it.
class MochiScaffold extends StatelessWidget {
  const MochiScaffold({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
    this.background,
    this.safeArea = true,
    this.extendBody = false,
  });

  final Widget child;
  final Widget? header;
  final Widget? footer;

  /// Defaults to [MochiGeometry.pagePadding]; pass [EdgeInsets.zero] for edge-to-edge content.
  final EdgeInsetsGeometry? padding;

  /// Defaults to [MochiColors.background].
  final Color? background;

  final bool safeArea;

  /// Whether the content runs under the header and the footer rather than stopping at them, so a
  /// list scrolls on behind the bars.
  ///
  /// The bars are measured as they are laid out — nothing has to declare a height ahead of time,
  /// which a header that grows with the theme's scale could only get wrong — and their heights
  /// are handed to the content as `MediaQuery.padding`. A `ListView` or a `GridView` reads that
  /// on its own and keeps its first and last rows clear of the bars; a `SingleChildScrollView`
  /// does not, so give it `padding: MediaQuery.paddingOf(context)`. The vertical [padding] goes
  /// into the same inset, inside the scroll view, rather than around it, where it would keep the
  /// content from reaching under the bars at all.
  ///
  /// The bars run to the screen's edges and clear the system's insets themselves (a
  /// `MochiHeader` the top one, a `MochiBottomNav` the bottom), so their own fill reaches under
  /// the status bar and the home indicator. A header with nothing behind it — the `plain`
  /// variant — lets the content show through: pair this with `bordered` or `floating`.
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final padding = this.padding ?? theme.geometry.pagePadding;

    if (extendBody) {
      final page = CustomMultiChildLayout(
        delegate: _ExtendedLayout(),
        children: [
          LayoutId(
            id: _Slot.body,
            child: _ExtendedBody(
              padding: padding,
              header: header != null,
              footer: footer != null,
              child: child,
            ),
          ),
          if (header case final header?) LayoutId(id: _Slot.header, child: header),
          if (footer case final footer?) LayoutId(id: _Slot.footer, child: footer),
        ],
      );

      return ColoredBox(
        color: background ?? theme.colors.background,
        // Only the sides: the top and bottom insets are the bars' to clear, under their own fill.
        child: safeArea ? SafeArea(top: false, bottom: false, child: page) : page,
      );
    }

    final body = Column(
      children: [
        ?header,
        Expanded(
          child: Padding(padding: padding, child: child),
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

enum _Slot { body, header, footer }

/// Constraints that also say how tall the bars standing over the body came out.
///
/// That is how the measurement gets from layout to the body's build without a frame's delay: the
/// body is a `LayoutBuilder`, which builds during layout with whatever constraints it is handed.
class _BodyConstraints extends BoxConstraints {
  _BodyConstraints.tight(super.size, {required this.top, required this.bottom}) : super.tight();

  final double top;
  final double bottom;

  @override
  bool operator ==(Object other) =>
      other is _BodyConstraints && super == other && top == other.top && bottom == other.bottom;

  @override
  int get hashCode => Object.hash(super.hashCode, top, bottom);
}

class _ExtendedLayout extends MultiChildLayoutDelegate {
  _ExtendedLayout();

  @override
  void performLayout(Size size) {
    // As wide as the page, as tall as they need to be — with no bound on the height, as a column
    // would give them: a header centres its title with an `Align`, which fills a bounded height
    // and turned the bar into the whole page.
    final bar = BoxConstraints.tightFor(width: size.width);

    var top = 0.0;
    if (hasChild(_Slot.header)) {
      top = layoutChild(_Slot.header, bar).height;
      positionChild(_Slot.header, Offset.zero);
    }
    var bottom = 0.0;
    if (hasChild(_Slot.footer)) {
      bottom = layoutChild(_Slot.footer, bar).height;
      positionChild(_Slot.footer, Offset(0, size.height - bottom));
    }

    layoutChild(_Slot.body, _BodyConstraints.tight(size, top: top, bottom: bottom));
    positionChild(_Slot.body, Offset.zero);
  }

  @override
  bool shouldRelayout(_ExtendedLayout oldDelegate) => false;
}

class _ExtendedBody extends StatelessWidget {
  const _ExtendedBody({
    required this.padding,
    required this.header,
    required this.footer,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final bool header;
  final bool footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final page = padding.resolve(Directionality.of(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        final bars = constraints as _BodyConstraints;

        // A side with a bar is cleared by the bar's height, which already holds the system's
        // inset; a side without one keeps the system's inset as it was.
        return MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(
              top: (header ? bars.top : media.padding.top) + page.top,
              bottom: (footer ? bars.bottom : media.padding.bottom) + page.bottom,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: page.left, right: page.right),
            child: child,
          ),
        );
      },
    );
  }
}
