import "package:flutter/widgets.dart";
import "package:tabler_icons_plus/tabler_icons_plus.dart";

import "tone.dart";

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
    this.info = TablerIcons.infoCircle,
    this.success = TablerIcons.circleCheck,
    this.warning = TablerIcons.alertTriangle,
    this.danger = TablerIcons.alertCircle,
  });

  final IconData back;
  final IconData close;
  final IconData check;
  final IconData chevronUp;
  final IconData chevronDown;
  final IconData chevronLeft;
  final IconData chevronRight;
  final IconData more;

  /// One per [MochiIntent] that has something to say. A toast raised with an intent and no icon
  /// of its own takes the matching one from here.
  final IconData info;
  final IconData success;
  final IconData warning;
  final IconData danger;

  /// The icon for [intent], or null for [MochiIntent.neutral] and [MochiIntent.primary], which
  /// carry no fixed meaning.
  IconData? of(MochiIntent intent) => switch (intent) {
    MochiIntent.info => info,
    MochiIntent.success => success,
    MochiIntent.warning => warning,
    MochiIntent.danger => danger,
    MochiIntent.neutral || MochiIntent.primary => null,
  };

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
          more == other.more &&
          info == other.info &&
          success == other.success &&
          warning == other.warning &&
          danger == other.danger;

  @override
  int get hashCode => Object.hash(
    back,
    close,
    check,
    chevronUp,
    chevronDown,
    chevronLeft,
    chevronRight,
    more,
    info,
    success,
    warning,
    danger,
  );
}
