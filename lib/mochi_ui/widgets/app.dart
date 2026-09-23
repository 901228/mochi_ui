import "package:flutter/widgets.dart";

import "../theme/geometry.dart";
import "../theme/strings.dart";
import "../theme/theme.dart";
import "animated_theme.dart";
import "scroll_behavior.dart";
import "toast.dart";
import "transitions.dart";

/// The root of an app built on this kit: a [WidgetsApp] with the theme, the toaster and the
/// scroll behaviour already in place.
///
/// Takes the two themes and a [MochiThemeMode] rather than one theme, so the light and dark
/// pair can cross-fade when the system switches; `touch`, `radius`, `density` and `textScale`
/// are the app-wide appearance knobs, and `strings` is the language the components speak.
///
/// ```dart
/// MochiApp(themeMode: MochiThemeMode.system, home: const HomePage())
/// ```
class MochiApp extends StatelessWidget {
  const MochiApp({
    super.key,
    this.title,
    this.themeMode = MochiThemeMode.system,
    this.lightTheme,
    this.darkTheme,
    this.touch,
    this.strings,
    this.radius,
    this.density,
    this.textScale = 1,
    this.toastAlignment,
    this.maxVisibleToasts = 3,
    this.maxQueuedToasts = 2,
    this.toastWidth,
    required Widget this.home,
  }) : routerConfig = null;

  const MochiApp.router({
    super.key,
    this.title,
    this.themeMode = MochiThemeMode.system,
    this.lightTheme,
    this.darkTheme,
    this.touch,
    this.strings,
    this.radius,
    this.density,
    this.textScale = 1,
    this.toastAlignment,
    this.maxVisibleToasts = 3,
    this.maxQueuedToasts = 2,
    this.toastWidth,
    required RouterConfig<Object> this.routerConfig,
  }) : home = null;

  final String? title;
  final MochiThemeMode themeMode;

  /// Defaults to [MochiTheme.light].
  final MochiTheme? lightTheme;

  /// Defaults to [MochiTheme.dark].
  final MochiTheme? darkTheme;

  /// Overrides [MochiTheme.touch] of both themes. Defaults to [MochiTheme.defaultTouch].
  final bool? touch;

  /// Overrides [MochiTheme.strings] of both themes: the words components say themselves, such as
  /// a confirmation's OK and Cancel. Pick the one for the app's locale.
  final MochiStrings? strings;

  /// Overrides `geometry.radius` of both themes: the app's corners, from [MochiRadius.sharp]
  /// through [MochiRadius.standard] to [MochiRadius.pill].
  final MochiRadius? radius;

  /// Overrides [MochiTheme.density] of both themes: how tightly spacing and controls are packed.
  final double? density;

  /// Multiplies the text size on top of the system's own setting, which is still respected: 1.2
  /// here with the system at 1.5 gives 1.8. Scales all text below the app, not only Mochi's.
  final double textScale;

  /// Which corner or edge toasts stack against. See [MochiToaster.alignment], which decides by
  /// screen size when this is null.
  final Alignment? toastAlignment;

  /// How many toasts are up at once; the rest wait their turn. See [MochiToaster.maxVisible].
  final int maxVisibleToasts;

  /// How many of those waiting show their edge past the end of the stack. See
  /// [MochiToaster.maxQueued].
  final int maxQueuedToasts;

  /// Overrides `geometry.toastWidth` for the stack. See [MochiToaster.width].
  final double? toastWidth;

  final Widget? home;
  final RouterConfig<Object>? routerConfig;

  static const _color = Color(0xFF000000);

  Widget _builder(BuildContext context, Widget? child) {
    final brightness = themeMode.brightness(MediaQuery.platformBrightnessOf(context));
    final theme = switch (brightness) {
      .light => lightTheme ?? MochiTheme.light,
      .dark => darkTheme ?? MochiTheme.dark,
    };
    final app = AnimatedMochiTheme(
      duration: theme.motion.themeDuration,
      curve: theme.motion.themeCurve,
      theme: theme.copyWith(
        touch: touch ?? MochiTheme.defaultTouch,
        strings: strings,
        density: density,
        radius: radius,
      ),
      child: Builder(
        builder: (context) => ColoredBox(
          color: context.colors.background,
          child: DefaultTextStyle(
            style: context.theme.typography.body.sm.copyWith(color: context.colors.foreground),
            child: IconTheme(
              data: IconThemeData(color: context.colors.foreground, size: 20),
              child: ScrollConfiguration(
                behavior: const MochiScrollBehavior(),
                // Above the navigator, so a toast outlives the page that raised it and stays
                // visible over a dialog.
                child: MochiToaster(
                  alignment: toastAlignment,
                  maxVisible: maxVisibleToasts,
                  maxQueued: maxQueuedToasts,
                  width: toastWidth,
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (textScale == 1) return app;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: _TimesTextScaler(media.textScaler, textScale)),
      child: app,
    );
  }

  @override
  Widget build(BuildContext context) {
    final routerConfig = this.routerConfig;
    if (routerConfig != null) {
      return WidgetsApp.router(color: _color, title: title, routerConfig: routerConfig, builder: _builder);
    }
    return WidgetsApp(
      color: _color,
      title: title,
      home: home,
      pageRouteBuilder: <T>(settings, builder) => MochiPageRoute<T>(settings: settings, builder: builder),
      builder: _builder,
    );
  }
}

/// The system's text scaling, then [factor] on top.
class _TimesTextScaler extends TextScaler {
  const _TimesTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) => other is _TimesTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
