import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

import "colors.dart";

/// Corner radii. Use them with [RoundedSuperellipseBorder]; superellipse corners look
/// tighter than circular ones at the same radius, so these run a little larger.
@immutable
class MochiRadius {
  const MochiRadius({
    this.xs = const BorderRadius.all(Radius.circular(6)),
    this.sm = const BorderRadius.all(Radius.circular(8)),
    this.md = const BorderRadius.all(Radius.circular(10)),
    this.lg = const BorderRadius.all(Radius.circular(14)),
    this.xl = const BorderRadius.all(Radius.circular(20)),
    this.full = const BorderRadius.all(Radius.circular(9999)),
  });

  /// Every step times [factor]; [full] stays fully round.
  MochiRadius.scaled(double factor)
    : this(
        xs: BorderRadius.all(Radius.circular(6 * factor)),
        sm: BorderRadius.all(Radius.circular(8 * factor)),
        md: BorderRadius.all(Radius.circular(10 * factor)),
        lg: BorderRadius.all(Radius.circular(14 * factor)),
        xl: BorderRadius.all(Radius.circular(20 * factor)),
      );

  /// Every step fully round: buttons and badges become pills, a card a stadium.
  const MochiRadius.allFull()
    : this(
        xs: const BorderRadius.all(Radius.circular(9999)),
        sm: const BorderRadius.all(Radius.circular(9999)),
        md: const BorderRadius.all(Radius.circular(9999)),
        lg: const BorderRadius.all(Radius.circular(9999)),
        xl: const BorderRadius.all(Radius.circular(9999)),
      );

  /// Presets for the whole app's corners, from square to round. Pass one to `MochiApp(radius:)`.
  static final sharp = MochiRadius.scaled(0);
  static final subtle = MochiRadius.scaled(0.5);
  static const standard = MochiRadius();
  static final rounded = MochiRadius.scaled(1.5);
  static const pill = MochiRadius.allFull();

  final BorderRadius xs;
  final BorderRadius sm;
  final BorderRadius md;
  final BorderRadius lg;
  final BorderRadius xl;

  /// Pill / circle.
  final BorderRadius full;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiRadius &&
          xs == other.xs &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg &&
          xl == other.xl &&
          full == other.full;

  @override
  int get hashCode => Object.hash(xs, sm, md, lg, xl, full);
}

/// Spacing scale, named like the type scale.
@immutable
class MochiSpace {
  const MochiSpace({
    this.xs3 = 2,
    this.xs2 = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xl2 = 48,
    this.xl3 = 64,
  });

  final double xs3;
  final double xs2;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xl2;
  final double xl3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiSpace &&
          xs3 == other.xs3 &&
          xs2 == other.xs2 &&
          xs == other.xs &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg &&
          xl == other.xl &&
          xl2 == other.xl2 &&
          xl3 == other.xl3;

  @override
  int get hashCode => Object.hash(xs3, xs2, xs, sm, md, lg, xl, xl2, xl3);

  /// Every step times [factor]. See [MochiTheme.density].
  MochiSpace scaled(double factor) => factor == 1
      ? this
      : MochiSpace(
          xs3: xs3 * factor,
          xs2: xs2 * factor,
          xs: xs * factor,
          sm: sm * factor,
          md: md * factor,
          lg: lg * factor,
          xl: xl * factor,
          xl2: xl2 * factor,
          xl3: xl3 * factor,
        );
}

/// How far off the page something is lifted, which is what its shadow is picked from.
enum MochiElevation { sm, md, lg }

/// One layer of a shadow, colorless; the color comes from [MochiColors.shadow].
@immutable
class MochiShadowLayer {
  const MochiShadowLayer({required this.offset, required this.blur, this.spread = 0, required this.opacity});

  final Offset offset;
  final double blur;
  final double spread;

  /// Multiplied with the shadow color's alpha.
  final double opacity;

  BoxShadow resolve(Color color) => BoxShadow(
    color: color.withValues(alpha: color.a * opacity),
    offset: offset,
    blurRadius: blur,
    spreadRadius: spread,
  );

  @override
  bool operator ==(Object other) =>
      other is MochiShadowLayer &&
      offset == other.offset &&
      blur == other.blur &&
      spread == other.spread &&
      opacity == other.opacity;

  @override
  int get hashCode => Object.hash(offset, blur, spread, opacity);
}

@immutable
class MochiShadows {
  const MochiShadows({
    this.sm = const [
      MochiShadowLayer(offset: Offset(0, 1), blur: 3, opacity: 0.16),
      MochiShadowLayer(offset: Offset(0, 1), blur: 2, spread: -1, opacity: 0.12),
    ],
    this.md = const [
      MochiShadowLayer(offset: Offset(0, 4), blur: 10, spread: -2, opacity: 0.22),
      MochiShadowLayer(offset: Offset(0, 2), blur: 4, spread: -2, opacity: 0.14),
    ],
    this.lg = const [
      MochiShadowLayer(offset: Offset(0, 12), blur: 28, spread: -6, opacity: 0.30),
      MochiShadowLayer(offset: Offset(0, 4), blur: 10, spread: -4, opacity: 0.18),
    ],
  });

  /// Resting surfaces: cards.
  final List<MochiShadowLayer> sm;

  /// Raised surfaces: popovers, menus, tooltips.
  final List<MochiShadowLayer> md;

  /// Floating surfaces: dialogs, sheets, toasts.
  final List<MochiShadowLayer> lg;

  /// The shadow of a surface in the raised look (see `MochiLayering`): [of], and in the dark theme
  /// a pale halo over it, since black on a dark page is invisible. [up] casts it towards the top
  /// of the screen, for a bar standing along the bottom edge.
  List<BoxShadow> raised(MochiElevation elevation, MochiColors colors, {bool up = false}) => [
    for (final layer in switch (elevation) {
      .sm => sm,
      .md => md,
      .lg => lg,
    })
      up
          ? MochiShadowLayer(
              offset: Offset(layer.offset.dx, -layer.offset.dy),
              blur: layer.blur,
              spread: layer.spread,
              opacity: layer.opacity,
            ).resolve(colors.shadow)
          : layer.resolve(colors.shadow),
    if (colors.brightness == Brightness.dark) _darkGlow,
  ];

  /// 50% white, tight enough that cards set side by side do not run together.
  static const _darkGlow = BoxShadow(color: Color(0x80FFFFFF), blurRadius: 12, spreadRadius: 1);

  List<BoxShadow> of(MochiElevation elevation, Color color) => [
    for (final layer in switch (elevation) {
      .sm => sm,
      .md => md,
      .lg => lg,
    })
      layer.resolve(color),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiShadows &&
          listEquals(sm, other.sm) &&
          listEquals(md, other.md) &&
          listEquals(lg, other.lg);

  @override
  int get hashCode => Object.hash(Object.hashAll(sm), Object.hashAll(md), Object.hashAll(lg));
}

/// The curve every corner in the kit is drawn with.
enum MochiCorners {
  /// A superellipse: the curve eases into the straight edge rather than meeting it at a point,
  /// which is what makes a corner look soft rather than cut. Native Impeller draws it as cheaply
  /// as a rounded rectangle.
  superellipse,

  /// A circular arc. The web's renderers have no superellipse of their own and draw one as an
  /// arbitrary path, a clip along one most of all, which on an iPhone held every frame at 60ms
  /// (a page with nothing raised on it as much as one full of shadows); the same page drawn with
  /// this ran at 6.
  rounded;

  /// What a platform gets unless told otherwise: [rounded] on the web, [superellipse] elsewhere.
  static const platform = kIsWeb ? rounded : superellipse;
}

/// Size and shape tokens shared by components. Colors live in [MochiColors].
@immutable
class MochiGeometry {
  const MochiGeometry({
    this.radius = const MochiRadius(),
    this.space = const MochiSpace(),
    this.shadows = const MochiShadows(),
    this.borderWidth = 1,
    this.focusRingWidth = 2,
    this.focusRingGap = 2,
    this.pagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.toastWidth = 400,
    this.corners = MochiCorners.platform,
  });

  final MochiRadius radius;
  final MochiSpace space;
  final MochiShadows shadows;
  final double borderWidth;

  /// Stroke width of [MochiFocusRing].
  final double focusRingWidth;

  /// Space between a component's edge and its focus ring.
  final double focusRingGap;

  /// Default padding around page content.
  final EdgeInsets pagePadding;

  /// How wide a stack of toasts is, or as much of it as the screen allows.
  ///
  /// One width for the whole stack rather than one per toast: a stack that sized itself around
  /// whatever had just arrived would jump every time a longer message came up and again when it
  /// left, and the queue's deck would have nothing steady to line up with.
  final double toastWidth;

  /// The curve of every corner. Components never name a border shape themselves: they ask [shape]
  /// for one and wrap their clips in `MochiClip`, so this is the one place it is decided.
  final MochiCorners corners;

  /// The border for a box with [borderRadius] and [side], drawn with [corners].
  OutlinedBorder shape({
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
    BorderSide side = BorderSide.none,
  }) => switch (corners) {
    .superellipse => RoundedSuperellipseBorder(borderRadius: borderRadius, side: side),
    .rounded => RoundedRectangleBorder(borderRadius: borderRadius, side: side),
  };

  static const standard = MochiGeometry();

  MochiGeometry copyWith({
    MochiRadius? radius,
    MochiSpace? space,
    MochiShadows? shadows,
    double? borderWidth,
    double? focusRingWidth,
    double? focusRingGap,
    EdgeInsets? pagePadding,
    double? toastWidth,
    MochiCorners? corners,
  }) => MochiGeometry(
    radius: radius ?? this.radius,
    space: space ?? this.space,
    shadows: shadows ?? this.shadows,
    borderWidth: borderWidth ?? this.borderWidth,
    focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    focusRingGap: focusRingGap ?? this.focusRingGap,
    pagePadding: pagePadding ?? this.pagePadding,
    toastWidth: toastWidth ?? this.toastWidth,
    corners: corners ?? this.corners,
  );

  /// The spacing and the page padding times [factor]; lines, corners and shadows stay put. See
  /// [MochiTheme.density].
  MochiGeometry withDensity(double factor) =>
      factor == 1 ? this : copyWith(space: space.scaled(factor), pagePadding: pagePadding * factor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiGeometry &&
          radius == other.radius &&
          space == other.space &&
          shadows == other.shadows &&
          borderWidth == other.borderWidth &&
          focusRingWidth == other.focusRingWidth &&
          focusRingGap == other.focusRingGap &&
          pagePadding == other.pagePadding &&
          toastWidth == other.toastWidth &&
          corners == other.corners;

  @override
  int get hashCode => Object.hash(
    radius,
    space,
    shadows,
    borderWidth,
    focusRingWidth,
    focusRingGap,
    pagePadding,
    toastWidth,
    corners,
  );
}
