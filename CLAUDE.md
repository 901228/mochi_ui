# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Mochi UI: a custom Flutter UI kit built on `package:flutter/widgets.dart` only — **no Material or Cupertino** (`uses-material-design: false`). Every widget, theme, and interaction state is implemented from primitives. Dependencies: `tabler_icons_plus` (icons).

Status: early WIP. Public API is exported from `lib/mochi_ui.dart`. `lib/main.dart` is a preview gallery (every button intent × appearance × state, with a light/dark/system toggle), not a real app.

Design references: Bulma for component API (intents, appearances, breakpoint names), Catppuccin Latte/Mocha for colors, forui for typography scale and button/tappable API naming. Icons: Tabler (`tabler_icons_plus`). Corners are always superellipses (`RoundedSuperellipseBorder` via `ShapeDecoration`), never `BoxDecoration.borderRadius`. Press feedback grows (iOS style), never shrinks.

## Commands

Flutter is pinned via FVM (`.fvmrc` → `master`; see the channel note under Architecture). Prefix commands with `fvm`:

```bash
fvm flutter pub get
fvm flutter analyze
fvm dart format lib
fvm flutter run -d linux
fvm flutter run -d chrome
fvm flutter test
fvm flutter test test/widgets/tappable_test.dart
```

Platforms present: `linux/`, `web/`. Evaluate performance with `--profile`; debug mode is several times slower.

## Code style

- Double quotes and relative imports within `lib/` (`prefer_double_quotes`, `prefer_relative_imports` lint rules).
- Formatter page width is 110.
- Dart 3.13+ features are used, e.g. dot-shorthand enum values in `switch` (`.mobile => ...`).

## Architecture

Split into `lib/mochi_ui/theme/` (data) and `lib/mochi_ui/widgets/` (UI).

Component roadmap and priorities: `ROADMAP.md` (tick items off as they land).

**Theme access.** `MochiThemeScope` (InheritedWidget) holds a `MochiTheme` (`colors`, `typography`, `touch`, extensions; value equality); read it via the `BuildContext` extensions `context.theme` / `context.colors` (`theme/theme.dart`). `MochiApp` / `MochiApp.router` take a `MochiThemeMode`, optional `lightTheme`/`darkTheme`, and `touch` (defaults to `MochiTheme.defaultTouch` by platform), and wrap content in `AnimatedMochiTheme` → `ColoredBox(background)` → `DefaultTextStyle` → `IconTheme` → `ScrollConfiguration`, so descendants get theme-derived text, icon, and scrollbar defaults.

**Colors (three layers).**
1. `theme/palette.dart`: raw hex values (`LattePalette`, `MochaPalette`). Not exported; only `colors.dart` may use it. Some Latte accents are darkened so text reaches WCAG AA 4.5:1 — re-check contrast when changing them.
2. `theme/colors.dart` `MochiColors`: semantic tokens. Neutrals (`background`, `surface`, `overlay`, `border`, `foreground`, `mutedForeground`) plus one `MochiTone` per `MochiIntent` (`neutral, primary, info, success, warning, danger`), looked up via `colors.of(intent)`. `MochiColors.light` / `.dark`.
3. Component styles derive everything from tokens. A `MochiTone` (`theme/tone.dart`) has `base` (fills/borders), `onBase` (text on base), `soft` (tinted bg), `onSoft` (intent text on soft or page bg). Hover/pressed colors are never stored; use `MochiColors.stateLayer(base, on, states)`.

**Typography.** `MochiTypography` has two `MochiTypeface`s, `title` (w700) and `body` (w400), each with a Tailwind-based scale `xs3, xs2, xs, sm, md, lg, xl, xl2 … xl8` (`md` = 16px) and `scale(factor)`. Styles carry no color. Family is Comfortaa (variable font, wght 300–700) with FakePearl (假粉圓) as CJK fallback; both are bundled in `assets/fonts/` (OFL) and declared in `pubspec.yaml`. Change weight with `style.withWeight(FontWeight.wX)`, which sets `fontWeight` and the `wght` variation together.

**Geometry.** `MochiTheme.geometry` (`MochiGeometry`): `radius` (xs 6 / sm 8 / md 10 / lg 14 / xl 20 / full), `space` (xs3 2 … xl3 64), `shadows` (sm/md/lg layers, colored by `colors.shadow` via `shadows.of(elevation, color)`), `borderWidth`, `focusRingWidth`/`focusRingGap`, `pagePadding`. Components take sizes, radii and shadows from here rather than literals. Size-dependent metrics reference tokens through functions (e.g. `MochiButtonMetrics.radius` is `BorderRadius Function(MochiRadius)`).

**Flutter channel: master (pinned in `.fvmrc`).** Stable 3.47.x renders strokes and paths on Linux without antialiasing: Impeller's SDF renderer has no `drawPath` antialiasing (flutter/flutter#185117, still open) and relies on MSAA, which the Linux embedder did not enable until PR #191379 (flutter/flutter#191171), merged to master 2026-08-23 and **not in stable**. On master everything renders smoothly, so the project follows master and the workarounds that existed for this (a custom fill+clear superellipse border, a sweep-gradient spinner) were removed. If the project ever moves back to a stable without that fix, expect stair steps on any stroked or path-based shape.

**Antialiasing.** Never stroke a shape with the same color as its fill: the antialiased edge is painted twice and hardens into stair steps. Filled button appearances therefore keep a fully transparent `BorderSide` (which also keeps the 1px layout).

**Focus ring.** Use `MochiFocusRing(visible:, radius:, child:)` for every focusable component. It paints outside the child (no layout change) and always builds a `Stack`, so toggling never resets the child's state. Because it paints outside, any clipping ancestor (scroll view, clipped card) cuts it off: reserve `MochiFocusRing.outsetOf(context)` of padding around focusable content inside clipped areas.

**Motion.** `MochiTheme.motion` (`MochiMotion`) holds `stateDuration`, `themeDuration`, and press springs. `MochiTappable(scaleOnPress: true)` wraps content in `MochiPressScale`, a render object that scales around the center while pressed (capped at `pressScale` and `pressMaxGrowth` px per side), springs back with overshoot, keeps quick taps visible for ≥90ms, snaps exactly to rest, and honors `MediaQuery.disableAnimations`. It repaints per tick without rebuilding; turn it off for list rows. It reads the theme with a fallback, so tappables work outside `MochiApp`.

**Theme extensions.** App-specific theme data subclasses `MochiThemeExtension<T>` (implement `lerp`; add `==` if the extension is rebuilt per build) and is read with `context.theme.extension<T>()`. `copyWith(extensions:)` merges by type.

**Theme animation.** `AnimatedMochiTheme` tweens the whole `MochiTheme` via `MochiTheme.lerp` (colors and extensions interpolate; typography and `touch` switch immediately). Any new field added to `MochiColors` or `MochiTone` must also be added to its `lerp`. `MochiTheme` must keep value equality, otherwise every `MochiApp` rebuild restarts the animation.

**Interaction states.** `MochiTappable` is the base for all pressable widgets. It owns a `WidgetStatesController` (hovered / focused / pressed / selected / disabled), wires gestures, keyboard activation (Enter/Space → `onPress` only), focus, cursor, and semantics, and exposes states through a `ValueWidgetBuilder<Set<WidgetState>>`. Disabled = `enabled: false`, or all of `onPress`, `onLongPress`, `onDoublePress`, `onSecondaryPress`, `onSecondaryLongPress` are null. Gesture callbacks are passed to `GestureDetector` only when non-null — in particular a registered `onDoublePress` delays `onPress` by the double-tap timeout. `selected` is owned by the widget: a `statesController` passed in gets `selected`/`disabled` overwritten from widget params. Visual widgets (e.g. `MochiButton`) build on it and resolve colors from the state set.

**Button styles.** Color intent and visual appearance are separate axes: `MochiButton(intent:, appearance:)`, where `MochiButtonAppearance` is `solid, soft, outlined, ghost, text, inverted`. `MochiButtonStyle.of(intent, appearance)` (`theme/styles/button_style.dart`) returns state-resolving color functions `(MochiColors, Set<WidgetState>) → Color`. Selected steps the appearance up one level (text/ghost/outlined → soft, soft/inverted → solid, solid → deepened); outlined keeps its border. `prefix`/`child`/`suffix` are laid out in a `Row`. Layout comes from `MochiButtonMetrics.of(size, touch:)` (heights desktop 28/32/36/40, touch 32/40/44/48); `MochiButton.icon` is square with width = height. Don't set `Container.alignment` on the surface — it makes the button fill its parent. Disabled is rendered as 40% opacity on the whole button; the focus ring is painted outside the box via a `Stack` so it never shifts layout. The border is always present (transparent when unused) for the same reason.

**State animation vs theme animation.** Inside components, don't use implicit `Animated*` widgets (`AnimatedContainer`, `AnimatedDefaultTextStyle`, …) for theme-derived values: every frame of `AnimatedMochiTheme` changes their target and restarts them. Use `MochiStateTransition` (`widgets/state_transition.dart`), which animates only when the `WidgetState` set changes and resolves colors against the current theme each build. Keep theme reads in the innermost widget (see `_ButtonSurface`) so interaction wrappers aren't rebuilt. When a color should fade in from transparent, use `color.withValues(alpha: 0)`, not `Color(0x00000000)` — lerping from transparent black flashes gray.

**Tooltip.** `MochiTooltip` (`widgets/tooltip.dart`) wraps Flutter's widgets-layer `RawTooltip`, adding a theme-styled bubble (inverse `neutral` tone), a `positionDelegate` that places it above/below the child instead of over its center, and keyboard-focus support (RawTooltip has none). `MochiButton(tooltip:)` is a shorthand. On touch, a descendant `onLongPress` wins the gesture arena over the tooltip's long-press trigger.

**Bounded constraints.** `MochiDivider` and `MochiLinearProgress` expand along their axis and need a bounded parent. Watch for widgets that silently shrink instead: a `FractionallySizedBox` under loose constraints sizes to its child, which once pinned the indeterminate progress bar in place. When something "doesn't animate", check the on-screen geometry (log `RenderBox.localToGlobal`) before trusting a screenshot — X11 captures of the GL window and the browser pane can both be stale.

**Components so far.** `MochiTappable`, `MochiButton` (+`.icon`), `MochiTooltip`, `MochiFocusRing`, `MochiDivider`, `MochiCard`, `MochiBadge`, `MochiSwitch`, `MochiCircularProgress`, `MochiLinearProgress`. Each one: theme reads in the innermost widget, colors via `MochiStateTransition`, shapes via `MochiSuperellipseBorder`, sizes from `theme.touch`, and `MediaQuery.disableAnimations` honored by anything that animates on its own. Verify new components in the real app in **debug** mode (`fvm flutter run -d linux`): profile builds have assertions off, so unbounded-constraint mistakes render as silently missing widgets instead of errors.

**Responsive.** `theme/responsive.dart` defines `MochiBreakpoint` (content width + 24px gutters: 768 / 1008 / 1248, plus 1600 for fullhd) and `MochiScreenSize`. `ResponsiveScope` can override the size; otherwise it's derived from `MediaQuery` width. Use `context.responsive(mobile: ..., desktop: ...)` for values or the `Responsive` widget for builders — both fall back to the nearest smaller tier.
