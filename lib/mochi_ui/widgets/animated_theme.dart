import "package:flutter/widgets.dart";

import "../theme/theme.dart";

class AnimatedMochiTheme extends ImplicitlyAnimatedWidget {
  const AnimatedMochiTheme({
    super.key,
    required this.theme,
    required this.child,
    super.duration = const Duration(milliseconds: 200),
    super.curve = Curves.easeInOut,
  });

  final MochiTheme theme;
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedMochiTheme> createState() => _State();
}

class _State extends AnimatedWidgetBaseState<AnimatedMochiTheme> {
  _ThemeTween? _theme;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _theme =
        visitor(_theme, widget.theme, (v) => _ThemeTween(begin: v as MochiTheme, end: v)) as _ThemeTween?;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return MochiThemeScope(theme: reduced ? widget.theme : _theme!.evaluate(animation), child: widget.child);
  }
}

class _ThemeTween extends Tween<MochiTheme> {
  _ThemeTween({super.begin, super.end});

  @override
  MochiTheme lerp(double t) => t >= 1 ? end! : MochiTheme.lerp(begin!, end!, t);

  // Tween short-circuits t == 0 to `begin`, which would hold back everything the theme switches
  // over immediately (sizes, typography, touch) for a frame. Only the colors interpolate, so the
  // blend is always worth computing.
  @override
  MochiTheme transform(double t) => lerp(t);
}
