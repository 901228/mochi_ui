import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "animated_theme.dart";
import "scroll_behavior.dart";

class MochiApp extends StatelessWidget {
  const MochiApp({
    super.key,
    this.title,
    this.themeMode = MochiThemeMode.system,
    this.lightTheme,
    this.darkTheme,
    this.touch,
    required Widget this.home,
  }) : routerConfig = null;

  const MochiApp.router({
    super.key,
    this.title,
    this.themeMode = MochiThemeMode.system,
    this.lightTheme,
    this.darkTheme,
    this.touch,
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

  final Widget? home;
  final RouterConfig<Object>? routerConfig;

  static const _color = Color(0xFF000000);

  Widget _builder(BuildContext context, Widget? child) {
    final brightness = themeMode.brightness(MediaQuery.platformBrightnessOf(context));
    final theme = switch (brightness) {
      .light => lightTheme ?? MochiTheme.light,
      .dark => darkTheme ?? MochiTheme.dark,
    };
    return AnimatedMochiTheme(
      duration: theme.motion.themeDuration,
      theme: theme.copyWith(touch: touch ?? MochiTheme.defaultTouch),
      child: Builder(
        builder: (context) => ColoredBox(
          color: context.colors.background,
          child: DefaultTextStyle(
            style: context.theme.typography.body.sm.copyWith(color: context.colors.foreground),
            child: IconTheme(
              data: IconThemeData(color: context.colors.foreground, size: 20),
              child: ScrollConfiguration(behavior: const MochiScrollBehavior(), child: child!),
            ),
          ),
        ),
      ),
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
      pageRouteBuilder: <T>(settings, builder) =>
          PageRouteBuilder<T>(settings: settings, pageBuilder: (context, _, _) => builder(context)),
      builder: _builder,
    );
  }
}
