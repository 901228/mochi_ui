import "dart:math" as math;

import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/geometry.dart";
import "../theme/size.dart";
import "action_scale.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "collapsible.dart";
import "state_transition.dart";
import "tappable.dart";

/// How a [MochiCard] stands off the page.
///
/// Not [MochiButtonAppearance]: a card holds other controls, whose own colours are tuned for the
/// page and the surface, so a solid fill would leave them unreadable, and one with neither fill
/// nor border is not a card at all.
enum MochiCardAppearance {
  /// [MochiColors.surface], a border and a shadow.
  elevated,

  /// A border and nothing else: the ground shows through, and there is no shadow, which would
  /// show through with it.
  outlined,

  /// [intent]'s soft fill with no shadow, for a note or a callout rather than a container.
  soft,
}

/// A surface for grouped content: [MochiColors.surface] with a border and an elevation shadow,
/// or one of the other [MochiCardAppearance]s.
///
/// Pass [onPress] to make the whole card tappable; it then reacts to hover, press and focus. Or
/// use [MochiCard.collapsible] for a card whose body opens and closes under a title.
///
/// [selected] is a card that has been picked — one of several in a multi-select — and it is drawn
/// the way every other chosen thing in the kit is: [intent]'s colour on the border, and the tone's
/// soft fill mixed over the card's own ground rather than the page's.
class MochiCard extends StatelessWidget {
  const MochiCard({
    super.key,
    required this.child,
    this.title,
    this.titlePrefix,
    this.titleSuffix,
    this.titleGap,
    this.padding,
    this.appearance = MochiCardAppearance.elevated,
    this.elevation = MochiElevation.sm,
    this.color,
    this.selected = false,
    this.intent = MochiIntent.primary,
    this.onPress,
    this.onLongPress,
    this.onSecondaryPress,
    this.semanticLabel,
  }) : _collapsible = false,
       expanded = null,
       initiallyExpanded = false,
       onExpandedChanged = null;

  /// A card that shows only [title] until it is opened. The whole title row is the toggle; see
  /// [MochiCollapsible] for [expanded] (controlled) versus [initiallyExpanded].
  const MochiCard.collapsible({
    super.key,
    required Widget this.title,
    required this.child,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.padding,
    this.appearance = MochiCardAppearance.elevated,
    this.elevation = MochiElevation.sm,
    this.color,
    this.intent = MochiIntent.primary,
  }) : _collapsible = true,
       titlePrefix = null,
       titleSuffix = null,
       titleGap = null,
       selected = false,
       onPress = null,
       onLongPress = null,
       onSecondaryPress = null,
       semanticLabel = null;

  /// A heading over the card's content, in the `title` typeface — a heading, not body text at a
  /// heavier weight, which is the rule the whole kit follows. [MochiCard.collapsible] makes the
  /// same row the toggle that folds the body away.
  final Widget? title;

  /// Either end of the title's own line: an icon before it, a `MochiActionBar` or a count after.
  final Widget? titlePrefix;
  final Widget? titleSuffix;

  /// The room between the title's line and the content under it. Defaults to `geometry.space.sm`.
  /// Taken as given, not scaled by density: pass a value read from `context.theme.geometry` to
  /// keep in step with the theme.
  final double? titleGap;

  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final MochiCardAppearance appearance;

  /// Only an [MochiCardAppearance.elevated] card casts a shadow.
  final MochiElevation elevation;

  /// The fill, in place of what [appearance] would use.
  final Color? color;

  /// Whether this card is one of the chosen ones.
  final bool selected;

  /// Colours a [selected] card, and a [MochiCardAppearance.soft] one throughout.
  final MochiIntent intent;

  final bool _collapsible;

  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryPress;
  final String? semanticLabel;

  bool get _interactive => onPress != null || onLongPress != null || onSecondaryPress != null;

  @override
  Widget build(BuildContext context) {
    if (_collapsible) {
      return _CardSurface(
        appearance: appearance,
        elevation: elevation,
        color: color,
        intent: intent,
        // The padding moves inside, so the title row's hover fill reaches the card's edges.
        padding: EdgeInsets.zero,
        child: _CollapsibleBody(
          padding: padding,
          title: title!,
          expanded: expanded,
          initiallyExpanded: initiallyExpanded,
          onExpandedChanged: onExpandedChanged,
          child: child,
        ),
      );
    }

    final body = title == null
        ? child
        : _TitledBody(title: title!, prefix: titlePrefix, suffix: titleSuffix, gap: titleGap, child: child);

    if (!_interactive && !selected) {
      return _CardSurface(
        appearance: appearance,
        elevation: elevation,
        color: color,
        intent: intent,
        padding: padding,
        child: body,
      );
    }

    // A card that is only selected still needs the states, so the surface knows to colour it.
    if (!_interactive) {
      return _CardSurface(
        appearance: appearance,
        elevation: elevation,
        color: color,
        intent: intent,
        padding: padding,
        states: const {WidgetState.selected},
        child: body,
      );
    }

    return MochiTappable(
      onPress: onPress,
      onLongPress: onLongPress,
      onSecondaryPress: onSecondaryPress,
      selected: selected,
      semanticLabel: semanticLabel,
      // Cards are large; growing them on press looks wrong. They tint instead.
      scaleOnPress: false,
      builder: (context, states, child) => _CardSurface(
        appearance: appearance,
        elevation: elevation,
        color: color,
        intent: intent,
        padding: padding,
        states: states,
        child: child!,
      ),
      child: body,
    );
  }
}

/// The halo a raised card wears in the dark theme, over its black shadow.
const _darkGlow = BoxShadow(color: Color(0x80FFFFFF), blurRadius: 12, spreadRadius: 1);

/// How many times a soft fill's alpha a chosen raised card is tinted.
const _raisedTint = 1.75;

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.appearance,
    required this.elevation,
    required this.color,
    required this.intent,
    required this.padding,
    required this.child,
    this.states = const {},
  });

  final MochiCardAppearance appearance;
  final MochiElevation elevation;
  final Color? color;
  final MochiIntent intent;
  final EdgeInsetsGeometry? padding;
  final Widget child;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    // A raised card has no line and a shadow a step deeper: the shadow is what sets it apart.
    // A soft card is rounder in the same theme and loses its line, but casts no shadow, being
    // a note rather than a container. An outlined card is its line, so it keeps its look.
    final roundTheme = theme.layering == .raised && appearance != .outlined;
    final raised = roundTheme && appearance == .elevated;
    final radius = roundTheme ? g.radius.lg : g.radius.md;
    final shadowStep = raised ? MochiElevation.values[math.min(elevation.index + 1, 2)] : elevation;
    final base =
        color ??
        switch (appearance) {
          // A raised card is lighter than the page, not darker: a shadow around something darker
          // than its ground only grades from one grey into the next with no edge between them.
          .elevated => raised ? colors.overlay : colors.surface,
          // Transparent surface rather than transparent black, which would flash grey on the way.
          // The tints below then land on whatever the card sits on, page or surface alike.
          .outlined => colors.surface.withValues(alpha: 0),
          .soft => tone.soft,
        };
    // A chosen card is tinted, mixed over the card's own ground rather than the page's — the same
    // fill a chosen radio card takes, so the two read as the same kind of "picked".
    // A raised card has no line to say it, so its tint is stronger than a soft fill elsewhere.
    final chosen = raised
        ? Color.alphaBlend(tone.base.withValues(alpha: colors.softAlpha * _raisedTint), base)
        : colors.softOn(tone, base);
    // A soft card's line is its own tint a step deeper; a grey one around a coloured fill reads
    // as a second, unrelated box. In the raised look there is no line at all.
    final rest = switch (appearance) {
      // Transparent, not absent: the line's width stays in the layout.
      _ when roundTheme => base.withValues(alpha: 0),
      .soft => colors.softOn(tone, base),
      _ => colors.border,
    };

    return MochiStateTransition(
      states: states,
      duration: theme.motion.stateDuration,
      builder: (context, blend) {
        final decoration = ShapeDecoration(
          color: blend.color(
            (st) => MochiColors.stateLayer(
              st.contains(WidgetState.selected) ? chosen : base,
              colors.foreground,
              st,
            ),
          ),
          shadows: appearance == .elevated
              ? [
                  ...g.shadows.of(shadowStep, colors.shadow),
                  // Black on a dark page is invisible, and the card's fill alone leaves a soft edge:
                  // a pale halo is what a raised card is lit by there.
                  if (raised && colors.brightness == Brightness.dark) _darkGlow,
                ]
              : null,
          shape: RoundedSuperellipseBorder(
            borderRadius: radius,
            side: BorderSide(
              width: g.borderWidth,
              color: blend.color(
                (st) => switch (st) {
                  // A raised card has no line even when chosen: the tint says it.
                  _ when st.contains(WidgetState.selected) && !roundTheme => tone.base,
                  _ when st.contains(WidgetState.hovered) && !raised => Color.lerp(
                    rest,
                    colors.mutedForeground,
                    0.5,
                  )!,
                  _ => rest,
                },
              ),
            ),
          ),
        );

        return DecoratedBox(
          decoration: decoration,
          // The clip is the card's own outline, with the padding inside it: a row's hover fill and
          // a scrollbar's thumb still stop at the corners, and the padded content is never reached
          // by the clip at all. Inside the padding it would round the *content's* corners by the
          // card's radius instead, which bites a piece out of anything in one of them.
          child: ClipRSuperellipse(
            borderRadius: radius,
            child: Padding(
              // The border's width is added the way a Container adds a decoration's own padding,
              // so the content sits inside the line rather than under it.
              padding: (padding ?? EdgeInsets.all(g.space.md)).add(decoration.padding),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// A heading over the card's content: the same row a collapsible card folds with, without the
/// folding — and in the `title` typeface, which is the thing an app composing its own gets wrong.
class _TitledBody extends StatelessWidget {
  const _TitledBody({
    required this.title,
    required this.prefix,
    required this.suffix,
    required this.gap,
    required this.child,
  });

  final Widget title;
  final Widget? prefix;
  final Widget? suffix;
  final double? gap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    // The row is a small button tall whether or not it has one in it, so putting an action there
    // moves nothing — and the button keeps a target worth aiming at, which a row the height of a
    // line of text cannot give it.
    final line = MochiButtonMetrics.of(MochiSize.xs, touch: theme.touch, density: theme.density).height;

    return _TitledLayout(
      gap: gap ?? g.space.sm,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: line),
          // The row is an xs button tall, so a bar of actions dropped in here is an xs bar unless
          // the app says otherwise: it costs no height, and nobody has to know the number.
          child: ActionScale(
            size: MochiSize.xs,
            child: Row(
              spacing: g.space.xs,
              children: [
                ?prefix,
                Expanded(
                  child: DefaultTextStyle(
                    style: theme.typography.title.sm.copyWith(color: theme.colors.foreground),
                    child: title,
                  ),
                ),
                ?suffix,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The title over the content, like a min-sized [Column] — except that a card given a height (say,
/// stretched in a row under [IntrinsicHeight]) hands the content the height left under the title,
/// so a [Center] in it centres in the card rather than in its own line. Anywhere else, in a list or
/// in a `Center`, the content takes its own height: a [Column] with an [Expanded] would throw in a
/// list, and a [LayoutBuilder] would throw under [IntrinsicHeight].
class _TitledLayout extends MultiChildRenderObjectWidget {
  const _TitledLayout({required this.gap, required super.children}) : assert(children.length == 2);

  final double gap;

  @override
  _RenderTitledLayout createRenderObject(BuildContext context) => _RenderTitledLayout(gap);

  @override
  void updateRenderObject(BuildContext context, _RenderTitledLayout renderObject) => renderObject.gap = gap;
}

class _TitledParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTitledLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TitledParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TitledParentData> {
  _RenderTitledLayout(this._gap);

  double get gap => _gap;
  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  RenderBox get _title => firstChild!;
  RenderBox get _body => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TitledParentData) child.parentData = _TitledParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_title.getMinIntrinsicWidth(double.infinity), _body.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(_title.getMaxIntrinsicWidth(double.infinity), _body.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _title.getMinIntrinsicHeight(width) + gap + _body.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _title.getMaxIntrinsicHeight(width) + gap + _body.getMaxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  /// Lays the two children out with [layoutChild] and returns the size; shared by layout and dry
  /// layout so the two cannot disagree.
  Size _layout(BoxConstraints constraints, ChildLayouter layoutChild, {required bool position}) {
    // Stretched across like the column's children were; loose only where nothing bounds the width.
    final bounded = constraints.hasBoundedWidth;
    BoxConstraints across(double maxHeight) => bounded
        ? BoxConstraints(minWidth: constraints.maxWidth, maxWidth: constraints.maxWidth, maxHeight: maxHeight)
        : BoxConstraints(maxHeight: maxHeight);

    final title = layoutChild(_title, across(double.infinity));
    final top = title.height + gap;
    // Only a card that has been *given* a height hands the rest down: a tight one, or one stretched
    // to a neighbour. A merely bounded one — a card in a `Center` on a page — keeps its content's
    // own height, or a centred child would blow it up to the whole screen. Loose either way, so a
    // Text keeps its own height and only a child that wants the room, a Center, takes it.
    final rest = constraints.minHeight > 0 ? math.max(0.0, constraints.maxHeight - top) : double.infinity;
    final body = layoutChild(_body, across(rest));

    if (position) {
      (_title.parentData! as _TitledParentData).offset = Offset.zero;
      (_body.parentData! as _TitledParentData).offset = Offset(0, top);
    }
    return constraints.constrain(Size(math.max(title.width, body.width), top + body.height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild, position: false);

  @override
  void performLayout() {
    size = _layout(constraints, ChildLayoutHelper.layoutChild, position: true);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);
}

class _CollapsibleBody extends StatelessWidget {
  const _CollapsibleBody({
    required this.padding,
    required this.title,
    required this.expanded,
    required this.initiallyExpanded,
    required this.onExpandedChanged,
    required this.child,
  });

  final EdgeInsetsGeometry? padding;
  final Widget title;
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final padding = (this.padding ?? EdgeInsets.all(g.space.md)).resolve(Directionality.of(context));

    return MochiCollapsible(
      title: title,
      expanded: expanded,
      initiallyExpanded: initiallyExpanded,
      onExpandedChanged: onExpandedChanged,
      headerPadding: padding,
      // A rule under the title row, rather than the row's own bottom padding standing in for the
      // gap: that padding is inside the row, so the row's hover fill would run into the content.
      bodyPadding: padding,
      divider: true,
      radius: g.radius.md,
      child: child,
    );
  }
}
