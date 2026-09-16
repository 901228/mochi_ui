import "package:flutter/widgets.dart";

import "../theme/theme.dart";

/// Fades from one [MochiTheme] to the next.
///
/// Only colors and extensions interpolate; everything else switches over at once. A theme change
/// that touches none of the interpolating parts (flipping `touch`, say) therefore has nothing to
/// animate, and is applied in a single frame instead of rebuilding the whole app for the duration
/// of an animation that would paint the same pixels every frame.
class AnimatedMochiTheme extends StatefulWidget {
  const AnimatedMochiTheme({
    super.key,
    required this.theme,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });

  final MochiTheme theme;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<AnimatedMochiTheme> createState() => _State();
}

class _State extends State<AnimatedMochiTheme> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration, value: 1);

  late MochiTheme _from = widget.theme;
  late MochiTheme _to = widget.theme;

  @override
  void didUpdateWidget(AnimatedMochiTheme old) {
    super.didUpdateWidget(old);

    _controller.duration = widget.duration;
    if (widget.theme == _to) return;

    // Start from the current blend, so a change mid-fade does not snap back.
    _from = _blend;
    _to = widget.theme;

    // Nothing left to interpolate once the immediate fields are applied: show the target at once.
    if (MochiTheme.lerp(_from, _to, 0) == _to) {
      _controller.value = 1;
      return;
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  MochiTheme get _blend {
    final t = widget.curve.transform(_controller.value);
    return t >= 1 ? _to : MochiTheme.lerp(_from, _to, t);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return MochiThemeScope(theme: widget.theme, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => MochiThemeScope(theme: _blend, child: child!),
      child: widget.child,
    );
  }
}
