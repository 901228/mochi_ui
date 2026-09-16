import "package:flutter/widgets.dart";

import "../theme/responsive.dart";

class Responsive extends StatelessWidget {
  const Responsive({super.key, this.mobile, this.tablet, this.desktop, this.widescreen, this.fullhd});

  final WidgetBuilder? mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;
  final WidgetBuilder? widescreen;
  final WidgetBuilder? fullhd;

  @override
  Widget build(BuildContext context) {
    assert(mobile != null);
    final fallback = mobile!;

    return switch (ResponsiveScope.of(context)) {
      .fullhd => fullhd ?? widescreen ?? desktop ?? tablet ?? mobile ?? fallback,
      .widescreen => widescreen ?? fullhd ?? desktop ?? tablet ?? mobile ?? fallback,
      .desktop => desktop ?? tablet ?? mobile ?? fallback,
      .tablet => tablet ?? mobile ?? fallback,
      .mobile => mobile ?? fallback,
    }(context);
  }
}
