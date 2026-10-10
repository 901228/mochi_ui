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
    this.minus = TablerIcons.minus,
    this.plus = TablerIcons.plus,
    this.chevronUp = TablerIcons.chevronUp,
    this.chevronDown = TablerIcons.chevronDown,
    this.chevronLeft = TablerIcons.chevronLeft,
    this.chevronRight = TablerIcons.chevronRight,
    this.more = TablerIcons.dots,
    this.menu = TablerIcons.menu2,
    this.sidebarCollapse = TablerIcons.layoutSidebarLeftCollapse,
    this.sidebarExpand = TablerIcons.layoutSidebarLeftExpand,
    this.grip = TablerIcons.gripVertical,
    this.search = TablerIcons.search,
    this.user = TablerIcons.user,
    this.calendar = TablerIcons.calendar,
    this.clock = TablerIcons.clock,
    this.info = TablerIcons.infoCircle,
    this.success = TablerIcons.circleCheck,
    this.warning = TablerIcons.alertTriangle,
    this.danger = TablerIcons.alertCircle,
  });

  final IconData back;
  final IconData close;
  final IconData check;

  /// A checkbox that is partly checked.
  final IconData minus;

  /// A stepper's increment; its decrement is [minus].
  final IconData plus;
  final IconData chevronUp;
  final IconData chevronDown;
  final IconData chevronLeft;
  final IconData chevronRight;
  final IconData more;

  /// What opens a scaffold's drawer, put in its header by itself.
  final IconData menu;

  /// The button a sidebar's heading carries to narrow it to a rail, and to widen it again.
  final IconData sidebarCollapse;
  final IconData sidebarExpand;

  /// What a sortable row is dragged by.
  final IconData grip;

  /// A search field's leading icon.
  final IconData search;

  /// What an avatar shows when it has neither a picture nor initials.
  final IconData user;

  /// A date field's leading icon.
  final IconData calendar;

  /// A time field's.
  final IconData clock;

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
          minus == other.minus &&
          plus == other.plus &&
          chevronUp == other.chevronUp &&
          chevronDown == other.chevronDown &&
          chevronLeft == other.chevronLeft &&
          chevronRight == other.chevronRight &&
          more == other.more &&
          menu == other.menu &&
          sidebarCollapse == other.sidebarCollapse &&
          sidebarExpand == other.sidebarExpand &&
          grip == other.grip &&
          search == other.search &&
          user == other.user &&
          calendar == other.calendar &&
          clock == other.clock &&
          info == other.info &&
          success == other.success &&
          warning == other.warning &&
          danger == other.danger;

  @override
  // hashAll, not hash: there are more icons here than Object.hash takes.
  int get hashCode => Object.hashAll([
    back,
    close,
    check,
    minus,
    plus,
    chevronUp,
    chevronDown,
    chevronLeft,
    chevronRight,
    more,
    menu,
    sidebarCollapse,
    sidebarExpand,
    grip,
    search,
    user,
    calendar,
    clock,
    info,
    success,
    warning,
    danger,
  ]);
}
