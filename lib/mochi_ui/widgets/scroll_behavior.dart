import "package:flutter/widgets.dart";

import "../theme/theme.dart";

class MochiScrollBehavior extends ScrollBehavior {
  const MochiScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return switch (getPlatform(context)) {
      TargetPlatform.linux || TargetPlatform.macOS || TargetPlatform.windows => RawScrollbar(
        controller: details.controller,
        thumbColor: context.colors.border,
        child: child,
      ),
      _ => child,
    };
  }
}
