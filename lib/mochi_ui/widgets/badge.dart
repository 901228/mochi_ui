import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/size.dart";
import "../theme/theme.dart";
import "overlap.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "close_button.dart";
import "value_transition.dart";

/// How loudly a badge carries its intent.
enum MochiBadgeAppearance { solid, soft, outlined }

/// The corners a badge wears.
enum MochiBadgeShape {
  /// Fully round ends.
  pill,

  /// Slightly rounded corners, like Bulma's tag: reads as a label on a thing rather than a
  /// count or a status.
  rounded,
}

/// A small label: status, counts, penalties, tags.
///
/// Give it [onDelete] and it grows a small × at its end that removes it (Bulma's `is-delete`);
/// put several in a [MochiBadgeGroup] and they join into one ("npm | 1.0").
class MochiBadge extends StatelessWidget {
  const MochiBadge({
    super.key,
    required this.child,
    this.prefix,
    this.suffix,
    this.intent = MochiIntent.neutral,
    this.appearance = MochiBadgeAppearance.soft,
    this.size = MochiSize.sm,
    this.shape = MochiBadgeShape.pill,
    this.metrics,
    this.onDelete,
    this.deleteLabel,
  });

  final Widget child;
  final Widget? prefix;
  final Widget? suffix;
  final MochiIntent intent;
  final MochiBadgeAppearance appearance;

  /// Defaults to `sm`: a badge sits beside text, so it runs a step smaller than a control.
  final MochiSize size;

  final MochiBadgeShape shape;

  /// Overrides the metrics [size] would pick.
  final MochiBadgeMetrics? metrics;

  /// Adds a × after [suffix] that calls this.
  final VoidCallback? onDelete;

  /// What a screen reader calls the ×. Defaults to [MochiStrings.remove].
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = metrics ?? MochiBadgeMetrics.of(size, touch: theme.touch, density: theme.density);

    return MochiValueTransition(
      value: target,
      lerp: MochiBadgeMetrics.lerp,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, m, _) => _surface(context, theme, m),
    );
  }

  Widget _surface(BuildContext context, MochiTheme theme, MochiBadgeMetrics m) {
    final g = theme.geometry;
    final tone = theme.colors.of(intent);
    final place = _BadgeGroupScope.placeOf(context);

    final (background, foreground, border) = switch (appearance) {
      .solid => (tone.base, tone.onBase, tone.base.withValues(alpha: 0)),
      .soft => (tone.soft, tone.onSoft, tone.base.withValues(alpha: 0)),
      .outlined => (tone.soft.withValues(alpha: 0), tone.onSoft, tone.base),
    };

    final corner = switch (shape) {
      .pill => g.radius.full,
      .rounded => m.radius(g.radius),
    };
    // Inside a group only the two outer ends keep their corners.
    final radius = switch (place) {
      null || _Place.only => corner,
      _Place.start => BorderRadiusDirectional.only(topStart: corner.topLeft, bottomStart: corner.bottomLeft),
      _Place.middle => BorderRadius.zero,
      _Place.end => BorderRadiusDirectional.only(topEnd: corner.topRight, bottomEnd: corner.bottomRight),
    };

    final onDelete = this.onDelete;
    // The × sits concentric with the badge's end, so the end padding is whatever centres it. The
    // border already insets the content by its width.
    final endPadding = onDelete == null
        ? m.horizontalPadding
        : (m.height - m.close.diameter) / 2 - g.borderWidth;

    final badge = Container(
      constraints: BoxConstraints(minHeight: m.height),
      padding: EdgeInsetsDirectional.only(start: m.horizontalPadding, end: endPadding),
      decoration: ShapeDecoration(
        color: background,
        shape: g.shape(
          borderRadius: radius,
          side: BorderSide(color: border, width: g.borderWidth),
        ),
      ),
      child: DefaultTextStyle(
        style: m.textStyle(theme.typography).withWeight(FontWeight.w600).copyWith(color: foreground),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: m.iconSize),
          // Sizes to its child but no smaller than the badge's min height, with the row centred
          // in it. `Container.alignment` would instead stretch the badge to fill its parent.
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: m.gap,
              children: [
                ?prefix,
                child,
                ?suffix,
                if (onDelete != null)
                  MochiCloseButton(
                    shape: MochiCloseButtonShape.circle,
                    metrics: m.close,
                    onPress: onDelete,
                    semanticLabel: deleteLabel ?? theme.strings.remove,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Neighbours in a group share one border rather than drawing two side by side.
    return switch (place) {
      _Place.middle || _Place.end => Overlap(by: g.borderWidth, child: badge),
      _ => badge,
    };
  }
}

/// Badges joined into one: the corners between them are squared off and neighbouring borders
/// shared (Bulma's `has-addons`). Each keeps its own intent and appearance.
///
/// ```dart
/// MochiBadgeGroup(children: [
///   MochiBadge(appearance: .solid, child: Text("ao5")),
///   MochiBadge(intent: .success, child: Text("12.34")),
/// ])
/// ```
class MochiBadgeGroup extends StatelessWidget {
  const MochiBadgeGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, child) in children.indexed)
        _BadgeGroupScope(
          place: switch ((i, children.length)) {
            (_, 1) => _Place.only,
            (0, _) => _Place.start,
            (final i, final n) when i == n - 1 => _Place.end,
            _ => _Place.middle,
          },
          child: child,
        ),
    ],
  );
}

enum _Place { only, start, middle, end }

class _BadgeGroupScope extends InheritedWidget {
  const _BadgeGroupScope({required this.place, required super.child});

  final _Place place;

  static _Place? placeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BadgeGroupScope>()?.place;

  @override
  bool updateShouldNotify(_BadgeGroupScope old) => old.place != place;
}

/// Size-dependent layout of a badge. Desktop heights 16 / 20 / 24 / 28, touch four more.
@immutable
class MochiBadgeMetrics {
  const MochiBadgeMetrics({
    required this.height,
    required this.horizontalPadding,
    required this.gap,
    required this.iconSize,
    required this.radius,
    required this.textStyle,
    required this.close,
  });

  /// Minimum height.
  final double height;
  final double horizontalPadding;

  /// Space between prefix, child, suffix and the ×.
  final double gap;
  final double iconSize;

  /// The corners of [MochiBadgeShape.rounded]; a pill is always fully round.
  final BorderRadius Function(MochiRadius radius) radius;

  final TextStyle Function(MochiTypography typography) textStyle;

  /// The × added by [MochiBadge.onDelete], two pixels in from the badge's edge all round.
  final MochiCloseButtonMetrics close;

  /// [density] scales the height, padding and gap (and with the height, the ×); see
  /// [MochiTheme.density].
  factory MochiBadgeMetrics.of(MochiSize size, {required bool touch, double density = 1}) {
    final extra = touch ? 4.0 : 0.0;
    final (height, padding, gap, icon, radius, text) = switch (size) {
      .xs => (16.0, 6.0, 2.0, 10.0, _xsRadius, _xs3),
      .sm => (20.0, 8.0, 4.0, 12.0, _xsRadius, _xs),
      .md => (24.0, 10.0, 4.0, 14.0, _smRadius, _sm),
      .lg => (28.0, 12.0, 6.0, 16.0, _smRadius, _md),
    };
    final closeDiameter = (height + extra) * density - 4;

    return MochiBadgeMetrics(
      height: (height + extra) * density,
      horizontalPadding: padding * density,
      gap: gap * density,
      iconSize: icon + extra / 2,
      radius: radius,
      textStyle: text,
      close: MochiCloseButtonMetrics(
        diameter: closeDiameter,
        iconSize: (closeDiameter * 0.6).roundToDouble(),
      ),
    );
  }

  static MochiBadgeMetrics lerp(MochiBadgeMetrics a, MochiBadgeMetrics b, double t) => MochiBadgeMetrics(
    height: lerpDouble(a.height, b.height, t)!,
    horizontalPadding: lerpDouble(a.horizontalPadding, b.horizontalPadding, t)!,
    gap: lerpDouble(a.gap, b.gap, t)!,
    iconSize: lerpDouble(a.iconSize, b.iconSize, t)!,
    radius: (r) => BorderRadius.lerp(a.radius(r), b.radius(r), t)!,
    textStyle: (typography) => TextStyle.lerp(a.textStyle(typography), b.textStyle(typography), t)!,
    close: MochiCloseButtonMetrics.lerp(a.close, b.close, t),
  );

  static BorderRadius _xsRadius(MochiRadius r) => r.xs;
  static BorderRadius _smRadius(MochiRadius r) => r.sm;
  static TextStyle _xs3(MochiTypography t) => t.body.xs3;
  static TextStyle _xs(MochiTypography t) => t.body.xs;
  static TextStyle _sm(MochiTypography t) => t.body.sm;
  static TextStyle _md(MochiTypography t) => t.body.md;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiBadgeMetrics &&
          height == other.height &&
          horizontalPadding == other.horizontalPadding &&
          gap == other.gap &&
          iconSize == other.iconSize &&
          radius == other.radius &&
          textStyle == other.textStyle &&
          close == other.close;

  @override
  int get hashCode => Object.hash(height, horizontalPadding, gap, iconSize, radius, textStyle, close);
}
