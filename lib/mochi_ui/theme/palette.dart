import "package:flutter/widgets.dart";

// Raw colors, referenced from Catppuccin Latte / Mocha.
// Some Latte accents are darkened to reach WCAG AA (4.5:1) for button text.
// Components must not use these directly; go through MochiColors instead.

abstract final class LattePalette {
  static const text = Color(0xFF4C4F69);
  static const subtext0 = Color(0xFF6C6F85);
  static const surface1 = Color(0xFFBCC0CC);
  static const base = Color(0xFFEFF1F5);
  static const mantle = Color(0xFFE6E9EF);
  static const crust = Color(0xFFDCE0E8);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1E1E2E);

  static const blue = Color(0xFF1E66F5);
  static const blueDark = Color(0xFF1A55C9);
  static const teal = Color(0xFF127A80);
  static const tealDark = Color(0xFF0F6A70);
  static const green = Color(0xFF327F22);
  static const greenDark = Color(0xFF2B6E1D);
  static const yellow = Color(0xFFDF8E1D);
  static const yellowDark = Color(0xFF8A560E);
  static const red = Color(0xFFD20F39);
  static const redDark = Color(0xFFB30D31);
}

abstract final class MochaPalette {
  static const text = Color(0xFFCDD6F4);
  static const subtext0 = Color(0xFFA6ADC8);
  static const surface0 = Color(0xFF313244);
  static const surface1 = Color(0xFF45475A);
  static const base = Color(0xFF1E1E2E);
  static const crust = Color(0xFF11111B);
  // Shadows on dark surfaces need to be much darker than any surface to show.
  static const shadow = Color(0xFF000000);

  static const blue = Color(0xFF89B4FA);
  static const teal = Color(0xFF94E2D5);
  static const green = Color(0xFFA6E3A1);
  static const yellow = Color(0xFFF9E2AF);
  static const red = Color(0xFFF38BA8);
}
