import "package:flutter/widgets.dart";

abstract final class MochiBreakpoint {
  static const _gutter = 24.0;

  static const _contentTablet = 720.0;
  static const _contentDesktop = 960.0;
  static const _contentWide = 1200.0;

  static const tablet = _contentTablet + _gutter * 2; // 768
  static const desktop = _contentDesktop + _gutter * 2; // 1008
  static const wide = _contentWide + _gutter * 2; // 1248
}

/// The tier the screen falls into, from the content widths in [MochiBreakpoint].
enum MochiScreenSize {
  mobile(0),
  tablet(MochiBreakpoint.tablet),
  desktop(MochiBreakpoint.desktop),
  widescreen(MochiBreakpoint.wide),
  fullhd(1600);

  const MochiScreenSize(this.minWidth);
  final double minWidth;

  static MochiScreenSize fromWidth(double w) => values.lastWhere((s) => w >= s.minWidth);

  bool operator >=(MochiScreenSize other) => index >= other.index;
  bool operator <(MochiScreenSize other) => index < other.index;

  bool get isTouch => this < MochiScreenSize.desktop;
}

class ResponsiveScope extends InheritedWidget {
  const ResponsiveScope({super.key, required this.size, required super.child});
  final MochiScreenSize size;

  static MochiScreenSize of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ResponsiveScope>()?.size ??
      MochiScreenSize.fromWidth(MediaQuery.sizeOf(context).width);

  @override
  bool updateShouldNotify(ResponsiveScope old) => old.size != size;
}

extension ResponsiveX on BuildContext {
  MochiScreenSize get screenSize => ResponsiveScope.of(this);

  T responsive<T>({required T mobile, T? tablet, T? desktop, T? widescreen, T? fullhd}) {
    final tiers = <T?>[mobile, tablet, desktop, widescreen, fullhd];
    for (var i = screenSize.index; i >= 0; i--) {
      final value = tiers[i];
      if (value != null) return value;
    }
    return mobile;
  }
}
