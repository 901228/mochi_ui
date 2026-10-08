import "dart:math" as math;

import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/size.dart";
import "../theme/theme.dart";
import "action.dart";
import "scaffold.dart";
import "shape_shadow.dart";

/// Where a header's title sits.
enum MochiHeaderAlignment {
  /// Right after the leading actions, filling the room up to the trailing ones.
  start,

  /// In the middle of the bar, whatever the two groups of actions measure — so a page whose
  /// trailing actions come and go keeps its title where it was. A title too long to be centred
  /// without running into one group moves towards the other, and is cut short only once it
  /// fills the room between them.
  center,
}

/// Whether the header is separated from the content below it.
enum MochiHeaderVariant {
  /// Sits directly on the page background.
  plain,

  /// A surface with a hairline along its bottom edge, for pages that scroll under it.
  bordered,

  /// Clear of the page's edges and rounded: a bar that floats above the content instead of capping
  /// the page. Lifted by a shadow in the raised look, outlined otherwise — the same bar as a
  /// floating `MochiBottomNav`, lined up with it.
  floating,
}

/// The bar at the top of a [MochiScaffold]: a title with actions on either side.
///
/// A pushed page puts [MochiAction.back] in [prefixes]; there is no separate nested variant,
/// since that was the only difference. Each group is a [MochiActionBar], so a group with more
/// actions than the breakpoint has room for folds its last ones into a … rather than squeezing
/// the title out.
class MochiHeader extends StatelessWidget {
  const MochiHeader({
    super.key,
    required this.title,
    this.prefixes = const [],
    this.suffixes = const [],
    this.maxVisibleActions,
    this.actionSize,
    this.alignment = MochiHeaderAlignment.start,
    this.variant,
    this.automaticPrefix = true,
  });

  final Widget title;

  /// Leading actions, usually [MochiAction.back]. Left empty in a [MochiScaffold] with a drawer to
  /// open, the header puts the button that opens it here — see [automaticPrefix].
  final List<MochiAction> prefixes;
  final List<MochiAction> suffixes;

  /// How many slots each group has, the … included. Defaults to the breakpoint's own count.
  final int? maxVisibleActions;

  /// The size of both groups' buttons, one size for the whole bar. Defaults to the action bar's own.
  final MochiSize? actionSize;

  /// Where the title sits.
  final MochiHeaderAlignment alignment;

  /// Null follows the theme's layering: floating when raised, plain when outlined — the phone's
  /// bar stands clear of the edges, as its bottom bar does.
  final MochiHeaderVariant? variant;

  /// Whether a header with no [prefixes] of its own opens the scaffold's drawer from there, when
  /// it has one to open: the button comes and goes as the width crosses the breakpoint, which an
  /// app would otherwise have to follow itself.
  final bool automaticPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    final border = BorderSide(color: theme.colors.border, width: g.borderWidth);
    final scaffold = automaticPrefix && this.prefixes.isEmpty ? MochiScaffold.maybeOf(context) : null;
    final prefixes = [
      ...this.prefixes,
      if (scaffold != null && scaffold.hasDrawer)
        MochiAction(icon: theme.icons.menu, label: theme.strings.openMenu, onPress: scaffold.openDrawer),
    ];
    final leading = prefixes.isEmpty
        ? null
        : MochiActionBar(prefixes, maxVisible: maxVisibleActions, size: actionSize);
    final trailing = suffixes.isEmpty
        ? null
        : MochiActionBar(suffixes, maxVisible: maxVisibleActions, size: actionSize);
    final text = DefaultTextStyle(
      style: theme.typography.title.lg.copyWith(color: theme.colors.foreground),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      child: title,
    );
    // Under a page with a `MochiLargeTitle`, the title waits for that one to scroll under the bar
    // and fades in over the last half of it. Only this box listens: the bar is not rebuilt as the
    // page scrolls.
    final covered = MochiScaffold.maybeOf(context)?.largeTitleCovered;
    final heading = covered == null
        ? text
        : ValueListenableBuilder(
            valueListenable: covered,
            builder: (context, covered, child) =>
                Opacity(opacity: covered == null ? 1 : ((covered - 0.5) * 2).clamp(0.0, 1.0), child: child),
            child: text,
          );

    // The status bar's room, when nothing above has already taken it: a scaffold with its bars
    // over the content leaves it to the header, so the header's own fill reaches the top edge.
    final inset = MediaQuery.paddingOf(context).top;
    final raised = theme.layering == .raised;
    final variant = this.variant ?? (raised ? MochiHeaderVariant.floating : MochiHeaderVariant.plain);
    final floating = variant == .floating;
    final ground = raised ? theme.colors.overlay : theme.colors.surface;

    final bar = Container(
      padding: EdgeInsets.symmetric(
        horizontal: g.space.md,
        vertical: g.space.sm,
      ).add(EdgeInsets.only(top: floating ? 0 : inset)),
      decoration: switch (variant) {
        .plain => null,
        .bordered => BoxDecoration(
          color: theme.colors.surface,
          border: Border(bottom: border),
        ),
        // Transparent, not absent, when raised: the line's width stays in the layout.
        .floating => ShapeDecoration(
          color: ground,
          shape: g.shape(
            borderRadius: g.radius.xl,
            side: raised ? BorderSide(color: ground.withValues(alpha: 0), width: g.borderWidth) : border,
          ),
        ),
      },
      child: switch (alignment) {
        .start => Row(
          spacing: g.space.xs,
          children: [
            ?leading,
            Expanded(
              child: Align(alignment: AlignmentDirectional.centerStart, child: heading),
            ),
            ?trailing,
          ],
        ),
        .center => _CenteredTitle(
          gap: g.space.xs,
          children: [leading ?? const SizedBox.shrink(), heading, trailing ?? const SizedBox.shrink()],
        ),
      },
    );

    if (!floating) return bar;

    // Clear of the edges by what a floating bottom bar keeps, so the two line up; under the status
    // bar rather than behind it.
    return Padding(
      padding: EdgeInsets.fromLTRB(g.space.md, inset + g.space.xs, g.space.md, g.space.xs),
      child: ShapeShadow(
        radius: g.radius.xl,
        shadows: raised ? g.shadows.raised(MochiElevation.lg, theme.colors) : null,
        child: bar,
      ),
    );
  }
}

/// Lays out the leading actions, the title and the trailing actions with the title centred on
/// the whole bar rather than on the room between the two groups. A `Row` can only centre it in
/// what is left, which moves it whenever one group changes width.
class _CenteredTitle extends MultiChildRenderObjectWidget {
  const _CenteredTitle({required this.gap, required super.children}) : assert(children.length == 3);

  final double gap;

  @override
  _RenderCenteredTitle createRenderObject(BuildContext context) =>
      _RenderCenteredTitle(gap: gap, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderCenteredTitle renderObject) {
    renderObject
      ..gap = gap
      ..textDirection = Directionality.of(context);
  }
}

class _RenderCenteredTitle extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SlotParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SlotParentData> {
  _RenderCenteredTitle({required this._gap, required this._textDirection});

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SlotParentData) child.parentData = _SlotParentData();
  }

  (RenderBox, RenderBox, RenderBox) get _slots {
    final leading = firstChild!;
    final title = childAfter(leading)!;
    return (leading, title, childAfter(title)!);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _tallest((child) => child.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) => _tallest((child) => child.getMaxIntrinsicHeight(width));

  double _tallest(double Function(RenderBox child) measure) {
    final (leading, title, trailing) = _slots;
    return math.max(measure(title), math.max(measure(leading), measure(trailing)));
  }

  @override
  void performLayout() {
    final (leading, title, trailing) = _slots;
    final loose = constraints.loosen();
    leading.layout(loose.copyWith(maxWidth: constraints.maxWidth), parentUsesSize: true);
    trailing.layout(loose.copyWith(maxWidth: constraints.maxWidth), parentUsesSize: true);

    // The room between the groups, keeping a gap from each one that is there at all.
    final start = leading.size.width > 0 ? leading.size.width + _gap : 0.0;
    final end = constraints.maxWidth - (trailing.size.width > 0 ? trailing.size.width + _gap : 0.0);
    title.layout(loose.copyWith(maxWidth: math.max(0.0, end - start)), parentUsesSize: true);

    final height = constraints.constrainHeight(
      math.max(title.size.height, math.max(leading.size.height, trailing.size.height)),
    );
    size = constraints.constrain(Size(constraints.maxWidth, height));

    // Centred on the bar, then slid just far enough to clear whichever group it would run into.
    final centred = (size.width - title.size.width) / 2;
    final x = math.min(math.max(centred, start), math.max(start, end - title.size.width));

    final ltr = _textDirection == TextDirection.ltr;
    double y(RenderBox child) => (size.height - child.size.height) / 2;
    double place(double x, RenderBox child) => ltr ? x : size.width - x - child.size.width;

    (leading.parentData! as _SlotParentData).offset = Offset(place(0, leading), y(leading));
    (title.parentData! as _SlotParentData).offset = Offset(place(x, title), y(title));
    (trailing.parentData! as _SlotParentData).offset = Offset(
      place(size.width - trailing.size.width, trailing),
      y(trailing),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

class _SlotParentData extends ContainerBoxParentData<RenderBox> {}
