import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

import "colors.dart";
import "defaults.dart";
import "geometry.dart";
import "icons.dart";
import "motion.dart";
import "strings.dart";
import "typography.dart";

enum MochiThemeMode {
  system,
  light,
  dark;

  Brightness brightness(Brightness platformBrightness) => switch (this) {
    .system => platformBrightness,
    .light => Brightness.light,
    .dark => Brightness.dark,
  };
}

/// App-defined theme data carried by [MochiTheme], looked up by type.
///
/// Extensions are interpolated during theme animations, so colors inside them fade
/// together with [MochiColors]. Subclass with the extension's own type:
///
/// ```dart
/// class CubeColors extends MochiThemeExtension<CubeColors> {
///   const CubeColors({required this.white});
///   final Color white;
///
///   @override
///   CubeColors lerp(CubeColors other, double t) => CubeColors(white: Color.lerp(white, other.white, t)!);
/// }
///
/// final cube = context.theme.extension<CubeColors>();
/// ```
@immutable
abstract class MochiThemeExtension<T extends MochiThemeExtension<T>> {
  const MochiThemeExtension();

  Object get type => T;

  T lerp(covariant T other, double t);
}

@immutable
class MochiTheme {
  MochiTheme({
    required this.colors,
    required this.typography,
    this.geometry = MochiGeometry.standard,
    this.icons = MochiIcons.standard,
    this.strings = MochiStrings.standard,
    this.defaults = MochiDefaults.standard,
    MochiMotion? motion,
    this.touch = false,
    Iterable<MochiThemeExtension<dynamic>> extensions = const [],
  }) : motion = motion ?? MochiMotion.standard,
       _extensions = {for (final e in extensions) e.type: e};

  const MochiTheme._raw({
    required this.colors,
    required this.typography,
    required this.geometry,
    required this.icons,
    required this.strings,
    required this.defaults,
    required this.motion,
    required this.touch,
    required this._extensions,
  });

  final MochiColors colors;
  final MochiTypography typography;
  final MochiGeometry geometry;
  final MochiIcons icons;

  /// The words components say themselves. See [MochiStrings].
  final MochiStrings strings;

  final MochiDefaults defaults;
  final MochiMotion motion;

  /// Touch-first sizing: larger hit targets and controls. See [MochiTheme.defaultTouch].
  final bool touch;

  final Map<Object, MochiThemeExtension<dynamic>> _extensions;

  static final light = MochiTheme(colors: MochiColors.light, typography: .standard);
  static final dark = MochiTheme(colors: MochiColors.dark, typography: .standard);

  /// Whether the current platform is touch-first.
  static bool get defaultTouch => switch (defaultTargetPlatform) {
    .android || .iOS || .fuchsia => true,
    .linux || .macOS || .windows => false,
  };

  /// The nearest theme without depending on it, or null outside one: for code that runs once
  /// rather than builds, such as a `show…` helper or a route.
  static MochiTheme? maybeRead(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MochiThemeScope>()?.theme;

  Iterable<MochiThemeExtension<dynamic>> get extensions => _extensions.values;

  T extension<T extends MochiThemeExtension<T>>() {
    final value = _extensions[T];
    assert(value != null, "No $T extension in MochiTheme. Pass it via MochiTheme(extensions: [...]).");
    return value! as T;
  }

  T? maybeExtension<T extends MochiThemeExtension<T>>() => _extensions[T] as T?;

  /// Replaces the given fields. [extensions] are merged by type: entries replace existing
  /// extensions of the same type, others are kept.
  MochiTheme copyWith({
    MochiColors? colors,
    MochiTypography? typography,
    MochiGeometry? geometry,
    MochiIcons? icons,
    MochiStrings? strings,
    MochiDefaults? defaults,
    MochiMotion? motion,
    bool? touch,
    Iterable<MochiThemeExtension<dynamic>>? extensions,
  }) => MochiTheme._raw(
    colors: colors ?? this.colors,
    typography: typography ?? this.typography,
    geometry: geometry ?? this.geometry,
    icons: icons ?? this.icons,
    strings: strings ?? this.strings,
    defaults: defaults ?? this.defaults,
    motion: motion ?? this.motion,
    touch: touch ?? this.touch,
    extensions: {
      ..._extensions,
      for (final e in extensions ?? const <MochiThemeExtension<dynamic>>[]) e.type: e,
    },
  );

  // Value equality: MochiApp derives a new instance on every build (copyWith(touch:)),
  // and AnimatedMochiTheme/MochiThemeScope must not treat that as a theme change.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiTheme &&
          colors == other.colors &&
          typography == other.typography &&
          geometry == other.geometry &&
          icons == other.icons &&
          strings == other.strings &&
          defaults == other.defaults &&
          motion == other.motion &&
          touch == other.touch &&
          mapEquals(_extensions, other._extensions);

  @override
  int get hashCode => Object.hash(
    colors,
    typography,
    geometry,
    icons,
    strings,
    defaults,
    motion,
    touch,
    Object.hashAllUnordered(_extensions.values),
  );

  /// Interpolates colors and extensions; [typography], [geometry], [icons], [strings], [defaults], [motion] and [touch] switch to [b] immediately.
  static MochiTheme lerp(MochiTheme a, MochiTheme b, double t) => MochiTheme._raw(
    colors: MochiColors.lerp(a.colors, b.colors, t),
    typography: b.typography,
    geometry: b.geometry,
    icons: b.icons,
    strings: b.strings,
    defaults: b.defaults,
    motion: b.motion,
    touch: b.touch,
    extensions: {
      for (final MapEntry(:key, :value) in b._extensions.entries)
        key: switch (a._extensions[key]) {
          // Both sides have the same runtime type: extensions are keyed by it.
          final MochiThemeExtension<dynamic> from => from.lerp(value, t) as MochiThemeExtension<dynamic>,
          null => value,
        },
    },
  );
}

class MochiThemeScope extends InheritedWidget {
  const MochiThemeScope({super.key, required this.theme, required super.child});
  final MochiTheme theme;

  @override
  bool updateShouldNotify(MochiThemeScope old) => old.theme != theme;
}

extension MochiThemeX on BuildContext {
  MochiTheme get theme => dependOnInheritedWidgetOfExactType<MochiThemeScope>()!.theme;
  MochiColors get colors => theme.colors;
}
