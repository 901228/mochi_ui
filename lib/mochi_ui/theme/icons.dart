import "package:flutter/widgets.dart";
import "package:tabler_icons_plus/tabler_icons_plus.dart";

/// The handful of icons components draw themselves, so an app can swap icon sets without
/// touching the components. Icons passed in by the app are its own business.
@immutable
class MochiIcons {
  const MochiIcons({
    this.back = TablerIcons.arrowLeft,
    this.close = TablerIcons.x,
    this.check = TablerIcons.check,
    this.chevronUp = TablerIcons.chevronUp,
    this.chevronDown = TablerIcons.chevronDown,
    this.chevronLeft = TablerIcons.chevronLeft,
    this.chevronRight = TablerIcons.chevronRight,
    this.more = TablerIcons.dots,
  });

  final IconData back;
  final IconData close;
  final IconData check;
  final IconData chevronUp;
  final IconData chevronDown;
  final IconData chevronLeft;
  final IconData chevronRight;
  final IconData more;

  static const standard = MochiIcons();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MochiIcons &&
          back == other.back &&
          close == other.close &&
          check == other.check &&
          chevronUp == other.chevronUp &&
          chevronDown == other.chevronDown &&
          chevronLeft == other.chevronLeft &&
          chevronRight == other.chevronRight &&
          more == other.more;

  @override
  int get hashCode =>
      Object.hash(back, close, check, chevronUp, chevronDown, chevronLeft, chevronRight, more);
}
