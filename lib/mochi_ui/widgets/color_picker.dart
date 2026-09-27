import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

import "../theme/contrast.dart";
import "../theme/geometry.dart";
import "../theme/size.dart";
import "../theme/strings.dart";
import "../theme/styles/button_style.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "button.dart";
import "dialog.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "tappable.dart";
import "text_field.dart";

/// Picks a colour: the shade square, a hue bar, an optional opacity bar, a hex field and a row of
/// swatches.
///
/// The value is a [Color], but what the picker keeps while it is open is an [HSVColor]: a colour
/// dragged down to black is every hue at once, so a picker that stored only the [Color] would
/// forget which hue it was on the moment you reached the bottom of the square, and the thumb would
/// jump back to red.
///
/// It fills the width it is given and needs that width to be bounded, like a divider — in a row,
/// give it a [SizedBox]. [showMochiColorPicker] is this in a modal, which is where a colour is
/// usually asked for.
///
/// ```dart
/// MochiColorPicker(
///   value: brand,
///   alpha: false,
///   onChanged: (next) => setState(() => brand = next),
/// )
/// ```
class MochiColorPicker extends StatefulWidget {
  const MochiColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.alpha = false,
    this.swatches,
    this.hex = true,
    this.areaHeight = 160,
    this.enabled = true,
  });

  final Color value;

  /// Null disables the picker.
  final ValueChanged<Color>? onChanged;

  /// Whether the colour can be made see-through: adds the opacity bar, and the hex field then
  /// reads and writes eight digits instead of six.
  final bool alpha;

  /// The colours offered as one press each. Defaults to the theme's own six intents, which are
  /// the colours an app built on this kit is most likely to be reaching for; pass an empty list
  /// for none.
  final List<Color>? swatches;

  /// Whether the hex field is shown. The colour can still be read off the picker without it.
  final bool hex;

  /// How tall the shade square is. Its width is whatever the picker is given.
  final double areaHeight;

  final bool enabled;

  @override
  State<MochiColorPicker> createState() => _MochiColorPickerState();
}

class _MochiColorPickerState extends State<MochiColorPicker> {
  /// The colour as the picker holds it. See the class doc: a [Color] alone cannot say which hue a
  /// black is.
  late HSVColor _hsv = HSVColor.fromColor(widget.value);

  final _hexController = TextEditingController();
  final _hexFocus = FocusNode();

  bool get _enabled => widget.enabled && widget.onChanged != null;

  @override
  void initState() {
    super.initState();

    _hexFocus.addListener(_handleHexFocus);
    _hexController.text = _hexText;
  }

  @override
  void didUpdateWidget(MochiColorPicker old) {
    super.didUpdateWidget(old);

    // Only when the colour really came from outside: the parent rebuilding with the colour this
    // picker just sent is the same colour, and taking the hue back out of it would reset a grey's
    // hue to red mid-drag.
    if (widget.value != old.value && widget.value.toARGB32() != _hsv.toColor().toARGB32()) {
      _hsv = HSVColor.fromColor(widget.value);
    }
    if (!widget.alpha && _hsv.alpha != 1) _hsv = _hsv.withAlpha(1);
    _syncHex();
  }

  @override
  void dispose() {
    _hexFocus.removeListener(_handleHexFocus);
    _hexController.dispose();
    _hexFocus.dispose();

    super.dispose();
  }

  void _handleHexFocus() {
    // Leaving the field puts the colour back in it, which is what tidies away half a hex nobody
    // finished typing.
    if (!_hexFocus.hasFocus) _syncHex();
  }

  /// The hex as the field writes it: `AARRGGBB` with opacity on, `RRGGBB` without — the order
  /// `Color(0xFF7C3AED)` is written in, since that is where a colour in a Flutter app comes from.
  String get _hexText {
    final argb = _hsv.toColor().toARGB32().toRadixString(16).padLeft(8, "0").toUpperCase();
    return widget.alpha ? argb : argb.substring(2);
  }

  /// Puts the colour back in the field, unless the field is the one changing it.
  void _syncHex() {
    if (_hexFocus.hasFocus) return;
    final text = _hexText;
    if (_hexController.text != text) _hexController.text = text;
  }

  void _emit(HSVColor next) {
    final hsv = widget.alpha ? next : next.withAlpha(1);
    if (hsv == _hsv) return;

    setState(() => _hsv = hsv);
    _syncHex();
    widget.onChanged?.call(hsv.toColor());
  }

  void _typeHex(String text) {
    if (text.length != 6 && text.length != 8) return;
    final digits = int.tryParse(text, radix: 16);
    if (digits == null) return;

    // Six digits are a colour without an opinion about opacity, so they keep the one the picker
    // already has rather than snapping it back to opaque.
    final alpha = (_hsv.alpha * 255).round() << 24;
    _emit(HSVColor.fromColor(Color(text.length == 8 ? digits : alpha | digits)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final strings = theme.strings;
    final color = _hsv.toColor();
    final swatches = widget.swatches ?? [for (final intent in MochiIntent.values) colors.of(intent).base];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: g.space.sm,
      children: [
        _ShadeArea(
          hsv: _hsv,
          height: widget.areaHeight,
          enabled: _enabled,
          onChanged: (saturation, value) => _emit(_hsv.withSaturation(saturation).withValue(value)),
        ),
        _ChannelBar(
          fraction: _hsv.hue / 360,
          // The hue wheel itself, worked out rather than written down as six literals.
          track: [for (var stop = 0; stop <= 6; stop++) HSVColor.fromAHSV(1, stop * 60, 1, 1).toColor()],
          thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
          // Two degrees a press: a hue is 360 wide and one degree is not a colour anybody can see.
          step: 2 / 360,
          label: strings.hue,
          format: (fraction) => "${(fraction * 360).round()}°",
          enabled: _enabled,
          onChanged: (fraction) => _emit(_hsv.withHue(fraction * 360)),
        ),
        if (widget.alpha)
          _ChannelBar(
            fraction: _hsv.alpha,
            track: [color.withValues(alpha: 0), color.withValues(alpha: 1)],
            thumbColor: color,
            // Behind the bar, so what "half way" means is something you can see through.
            checkered: true,
            step: 0.02,
            label: strings.opacity,
            format: (fraction) => "${(fraction * 100).round()}%",
            enabled: _enabled,
            onChanged: (fraction) => _emit(_hsv.withAlpha(fraction)),
          ),
        if (widget.hex)
          MochiTextField(
            controller: _hexController,
            focusNode: _hexFocus,
            size: MochiSize.sm,
            enabled: _enabled,
            label: Text(strings.hex),
            textCapitalization: TextCapitalization.characters,
            // The colour as it stands, in the box, before the digits that say what it is.
            prefix: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: g.space.xs2,
              children: [
                _Sample(color: color, size: 16),
                Text("#", style: TextStyle(color: colors.mutedForeground)),
              ],
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp("[0-9a-fA-F]")),
              LengthLimitingTextInputFormatter(widget.alpha ? 8 : 6),
              TextInputFormatter.withFunction((_, next) => next.copyWith(text: next.text.toUpperCase())),
            ],
            onChanged: _typeHex,
            onSubmitted: (_) => _syncHex(),
          ),
        if (swatches.isNotEmpty)
          Wrap(
            spacing: g.space.xs2,
            runSpacing: g.space.xs2,
            children: [
              for (final swatch in swatches)
                _Swatch(
                  color: swatch,
                  selected: swatch.toARGB32() == color.toARGB32(),
                  enabled: _enabled,
                  // A swatch is a choice of colour, not of opacity: whatever the opacity bar was
                  // set to stays where it was put.
                  onPress: () => _emit(HSVColor.fromColor(swatch).withAlpha(_hsv.alpha)),
                ),
            ],
          ),
      ],
    );
  }
}

/// Saturation across, brightness down: the square the colour itself is picked out of.
class _ShadeArea extends StatefulWidget {
  const _ShadeArea({required this.hsv, required this.height, required this.enabled, required this.onChanged});

  final HSVColor hsv;
  final double height;
  final bool enabled;
  final void Function(double saturation, double value) onChanged;

  @override
  State<_ShadeArea> createState() => _ShadeAreaState();
}

class _ShadeAreaState extends State<_ShadeArea> {
  final _focusNode = FocusNode();
  bool _focusVisible = false;

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  void _nudge(double saturation, double value) => widget.onChanged(
    (widget.hsv.saturation + saturation).clamp(0.0, 1.0),
    (widget.hsv.value + value).clamp(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final radius = g.radius.sm;
    final hue = HSVColor.fromAHSV(1, widget.hsv.hue, 1, 1).toColor();
    final thumb = theme.touch ? 24.0 : 20.0;

    final area = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        void at(Offset local) {
          if (!widget.enabled) return;
          widget.onChanged(
            (local.dx / width).clamp(0.0, 1.0),
            1 - (local.dy / widget.height).clamp(0.0, 1.0),
          );
        }

        void start(Offset local) {
          if (!widget.enabled) return;
          _focusNode.requestFocus();
          at(local);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => start(details.localPosition),
          // Two drags rather than one pan: a modal's body scrolls, and a pan loses the arena to
          // the scroll view's vertical drag — the square would scroll the dialog instead of
          // picking a colour. A drag of the same kind is resolved in favour of the inner one, and
          // whichever of the two wins hands over the whole position anyway.
          onHorizontalDragStart: (details) => start(details.localPosition),
          onHorizontalDragUpdate: (details) => at(details.localPosition),
          onVerticalDragStart: (details) => start(details.localPosition),
          onVerticalDragUpdate: (details) => at(details.localPosition),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                // Both gradients in one painter, inside one clip, under one border. Two stacked
                // boxes of the same shape antialias the same edge twice, which hardens into a
                // line around the square and a seam where the two corners disagree.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ShapePainter(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: radius,
                        // A hairline, or a white square on a light page has no edge at all.
                        side: BorderSide(color: colors.border, width: g.borderWidth),
                      ),
                      gradients: [
                        // White at the left, the hue at the right: saturation.
                        LinearGradient(colors: [const Color(0xFFFFFFFF), hue]),
                        // Transparent black down to black: brightness. Transparent *black* on
                        // purpose — the gradient is meant to arrive at black, which is the one
                        // case where a fully transparent black is the right end of a lerp.
                        const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xFF000000)],
                        ),
                      ],
                    ),
                  ),
                ),
                // The colour axes run left to right whatever the text does: a gradient is a
                // picture, and mirroring it would only move the colours about.
                Positioned(
                  left: widget.hsv.saturation * width - thumb / 2,
                  top: (1 - widget.hsv.value) * widget.height - thumb / 2,
                  child: _Knob(diameter: thumb, color: widget.hsv.withAlpha(1).toColor()),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      label: theme.strings.shade,
      value: "${(widget.hsv.saturation * 100).round()}% · ${(widget.hsv.value * 100).round()}%",
      child: FocusableActionDetector(
        enabled: widget.enabled,
        focusNode: _focusNode,
        onShowFocusHighlight: (visible) => setState(() => _focusVisible = visible),
        // A square that can only be dragged is a colour a keyboard cannot pick.
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowLeft): _NudgeIntent(-0.02, 0),
          SingleActivator(LogicalKeyboardKey.arrowRight): _NudgeIntent(0.02, 0),
          SingleActivator(LogicalKeyboardKey.arrowUp): _NudgeIntent(0, 0.02),
          SingleActivator(LogicalKeyboardKey.arrowDown): _NudgeIntent(0, -0.02),
        },
        actions: {
          _NudgeIntent: CallbackAction<_NudgeIntent>(
            onInvoke: (intent) => _nudge(intent.saturation, intent.value),
          ),
        },
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.4,
          child: MochiFocusRing(visible: _focusVisible, radius: radius, child: area),
        ),
      ),
    );
  }
}

class _NudgeIntent extends Intent {
  const _NudgeIntent(this.saturation, this.value);

  final double saturation;
  final double value;
}

/// One channel as a bar with a knob on it: the hue, or the opacity.
class _ChannelBar extends StatefulWidget {
  const _ChannelBar({
    required this.fraction,
    required this.track,
    required this.thumbColor,
    required this.step,
    required this.label,
    required this.format,
    required this.enabled,
    required this.onChanged,
    this.checkered = false,
  });

  /// Where the knob sits, 0 to 1.
  final double fraction;

  /// The gradient painted along the bar.
  final List<Color> track;

  final Color thumbColor;

  /// What one arrow press moves, as a fraction of the bar.
  final double step;

  final String label;

  /// The channel written out, for a screen reader. A function rather than a string because a
  /// screen reader is also told where a step would land, and the framework asserts on one of the
  /// pair without the other.
  final String Function(double fraction) format;

  final bool enabled;
  final ValueChanged<double> onChanged;

  /// Draws the chequerboard behind the gradient, which is what makes "see-through" visible.
  final bool checkered;

  @override
  State<_ChannelBar> createState() => _ChannelBarState();
}

class _ChannelBarState extends State<_ChannelBar> {
  final _focusNode = FocusNode();
  bool _focusVisible = false;

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  void _set(double fraction) => widget.onChanged(fraction.clamp(0.0, 1.0));

  double _stepped(double direction) => (widget.fraction + widget.step * direction).clamp(0.0, 1.0);

  void _stepBy(double direction) => _set(_stepped(direction));

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final thumb = theme.touch ? 24.0 : 20.0;
    final height = theme.touch ? 14.0 : 12.0;
    final shape = RoundedSuperellipseBorder(borderRadius: g.radius.full);

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        // The knob's centre runs from one end of the bar to the other, so it never hangs off.
        final travel = (constraints.maxWidth - thumb).clamp(0.0, double.infinity);

        void at(double dx) {
          if (!widget.enabled) return;
          _set((dx - thumb / 2) / travel);
        }

        void start(double dx) {
          if (!widget.enabled) return;
          _focusNode.requestFocus();
          at(dx);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => start(details.localPosition.dx),
          onHorizontalDragStart: (details) => start(details.localPosition.dx),
          onHorizontalDragUpdate: (details) => at(details.localPosition.dx),
          child: SizedBox(
            // A band deep enough to aim at, with the bar centred in it: a press that misses
            // inside a scrolling page scrolls the page instead.
            height: theme.touch ? 44 : 28,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: SizedBox(
                    height: height,
                    // The whole width, spelled out: a CustomPaint with no child of its own asks
                    // for Size.zero, and under a loose width that is exactly what it gets —
                    // leaving the knob standing on a bar nobody could see.
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ShapePainter(
                        shape: shape,
                        gradients: [LinearGradient(colors: widget.track)],
                        chequer: widget.checkered ? (colors.surface, colors.border) : null,
                      ),
                    ),
                  ),
                ),
                // Left to right whatever the text direction: the gradient is not mirrored either.
                Positioned(
                  left: widget.fraction.clamp(0.0, 1.0) * travel,
                  child: MochiFocusRing(
                    visible: _focusVisible,
                    radius: g.radius.full,
                    child: _Knob(diameter: thumb, color: widget.thumbColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      slider: true,
      label: widget.label,
      value: widget.format(widget.fraction),
      increasedValue: widget.enabled ? widget.format(_stepped(1)) : null,
      decreasedValue: widget.enabled ? widget.format(_stepped(-1)) : null,
      onIncrease: widget.enabled ? () => _stepBy(1) : null,
      onDecrease: widget.enabled ? () => _stepBy(-1) : null,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        focusNode: _focusNode,
        onShowFocusHighlight: (visible) => setState(() => _focusVisible = visible),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _SlideIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _SlideIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _SlideIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _SlideIntent(-1),
          SingleActivator(LogicalKeyboardKey.home): _EndIntent(toMax: false),
          SingleActivator(LogicalKeyboardKey.end): _EndIntent(toMax: true),
        },
        actions: {
          _SlideIntent: CallbackAction<_SlideIntent>(onInvoke: (intent) => _stepBy(intent.direction)),
          _EndIntent: CallbackAction<_EndIntent>(onInvoke: (intent) => _set(intent.toMax ? 1 : 0)),
        },
        child: Opacity(opacity: widget.enabled ? 1 : 0.4, child: bar),
      ),
    );
  }
}

class _SlideIntent extends Intent {
  const _SlideIntent(this.direction);

  final double direction;
}

class _EndIntent extends Intent {
  const _EndIntent({required this.toMax});

  final bool toMax;
}

/// The knob on a bar, and the ring on the shade square: the colour it is standing on, in a white
/// collar so it reads on top of any of them.
class _Knob extends StatelessWidget {
  const _Knob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final g = theme.geometry;

    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shadows: g.shadows.of(MochiElevation.sm, theme.colors.shadow),
          shape: RoundedSuperellipseBorder(
            borderRadius: g.radius.full,
            // Plain white rather than a theme colour: the knob sits on the colours themselves,
            // where the page's own ground says nothing about what will read.
            side: const BorderSide(color: Color(0xFFFFFFFF), width: 3),
          ),
        ),
      ),
    );
  }
}

/// The colour as it stands, over a chequerboard when it can be seen through.
class _Sample extends StatelessWidget {
  const _Sample({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ShapePainter(
          shape: RoundedSuperellipseBorder(
            borderRadius: theme.geometry.radius.xs,
            side: BorderSide(color: colors.border, width: theme.geometry.borderWidth),
          ),
          gradients: [
            LinearGradient(colors: [color, color]),
          ],
          chequer: color.a < 1 ? (colors.surface, colors.border) : null,
        ),
      ),
    );
  }
}

/// One of the colours offered outright.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.enabled, required this.onPress});

  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final g = theme.geometry;
    final side = theme.touch ? 32.0 : 28.0;

    return MochiTappable(
      enabled: enabled,
      selected: selected,
      onPress: onPress,
      builder: (context, states, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) => SizedBox.square(
          dimension: side,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: color,
              shape: RoundedSuperellipseBorder(
                borderRadius: g.radius.sm,
                side: BorderSide(
                  width: g.borderWidth * (selected ? 2 : 1),
                  color: blend.color(
                    (st) => switch (st) {
                      _ when st.contains(WidgetState.selected) => colors.foreground,
                      _ when st.contains(WidgetState.hovered) => colors.mutedForeground,
                      _ => colors.border,
                    },
                  ),
                ),
              ),
            ),
            child: Center(
              // The tick is drawn in whichever of the page's two inks reads on the swatch: these
              // are the app's colours, and nothing here knows how dark they are.
              child: Opacity(
                opacity: blend.number((st) => st.contains(WidgetState.selected) ? 1 : 0),
                child: Icon(
                  theme.icons.check,
                  size: side / 2,
                  color: mostReadable(color, [colors.background, colors.foreground]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradients inside a shape, with an optional chequerboard under them.
///
/// A painter rather than a stack of clipped boxes: the chequerboard has to stop at the same
/// superellipse the gradient does, the shape itself is the cheapest clip there is, and a second
/// box of the same shape would antialias the same edge a second time — which is what turns a soft
/// corner into a hard line.
class _ShapePainter extends CustomPainter {
  const _ShapePainter({required this.shape, required this.gradients, this.chequer});

  final ShapeBorder shape;

  /// Painted in order, each over the whole shape: the square lays brightness over saturation.
  final List<Gradient> gradients;

  /// The two greys of the chequerboard, or null for a plain bar.
  final (Color, Color)? chequer;

  static const _square = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(shape.getOuterPath(rect));

    if (chequer case (final light, final dark)?) {
      canvas.drawRect(rect, Paint()..color = light);
      final paint = Paint()..color = dark;
      for (var y = 0.0; y < size.height; y += _square) {
        for (var x = 0.0; x < size.width; x += _square) {
          // Every other square, counted in both directions.
          if (((x / _square).floor() + (y / _square).floor()).isEven) continue;
          canvas.drawRect(Rect.fromLTWH(x, y, _square, _square), paint);
        }
      }
    }

    for (final gradient in gradients) {
      canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    }
    canvas.restore();
    // The border last and once, over everything the clip let through.
    shape.paint(canvas, rect);
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.chequer != chequer || !listEquals(old.gradients, gradients);
}

/// Asks for a colour in a modal: a dialog from tablet width up, a sheet on a phone.
///
/// Completes with the colour when it is confirmed, and with null when it is dismissed — the same
/// bargain as the pickers' sheets: a modal is answered, so the draft only leaves it through the
/// button. Pass [alpha] for a colour that can be seen through.
///
/// ```dart
/// final picked = await showMochiColorPicker(context, initial: brand);
/// if (picked != null) setState(() => brand = picked);
/// ```
Future<Color?> showMochiColorPicker(
  BuildContext context, {
  required Color initial,
  String? title,
  bool alpha = false,
  List<Color>? swatches,
  Color? defaultColor,
  String? defaultLabel,
  String? confirmLabel,
  String? cancelLabel,
  MochiModalForm? form,
  bool barrierDismissible = true,
}) {
  // A helper runs once from an event handler rather than building, and may be called from outside
  // a MochiApp: it reads the words without depending on them.
  final strings = MochiTheme.maybeRead(context)?.strings ?? MochiStrings.standard;
  final draft = ValueNotifier(initial);

  return showMochiModal<Color>(
    context,
    form: form,
    barrierDismissible: barrierDismissible,
    title: Text(title ?? strings.pickColor),
    body: _ColorPickerBody(
      draft: draft,
      alpha: alpha,
      swatches: swatches,
      defaultColor: defaultColor,
      defaultLabel: defaultLabel ?? strings.reset,
    ),
    actions: [
      MochiModalAction<Color>(
        label: cancelLabel ?? strings.cancel,
        appearance: MochiButtonAppearance.outlined,
      ),
      _ColorConfirm(draft: draft, label: confirmLabel ?? strings.ok),
    ],
  );
}

/// The picker inside the modal, over a draft the confirming button reads.
class _ColorPickerBody extends StatefulWidget {
  const _ColorPickerBody({
    required this.draft,
    required this.alpha,
    required this.swatches,
    required this.defaultColor,
    required this.defaultLabel,
  });

  final ValueNotifier<Color> draft;
  final bool alpha;
  final List<Color>? swatches;

  /// The colour the app would have used anyway, offered as one press. Null offers nothing.
  final Color? defaultColor;
  final String defaultLabel;

  @override
  State<_ColorPickerBody> createState() => _ColorPickerBodyState();
}

class _ColorPickerBodyState extends State<_ColorPickerBody> {
  @override
  void dispose() {
    // The draft belongs to the route rather than to the future the helper returned: that future
    // completes when the modal is popped, while the modal is still being drawn on its way out.
    widget.draft.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    // The modal's body scrolls, and a scroll view clips: leave the rings room.
    padding: EdgeInsets.all(MochiFocusRing.outsetOf(context)),
    child: ValueListenableBuilder(
      valueListenable: widget.draft,
      builder: (context, color, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MochiColorPicker(
            value: color,
            alpha: widget.alpha,
            swatches: widget.swatches,
            onChanged: (next) => widget.draft.value = next,
          ),
          // Under the picker rather than beside the answers: going back to the default is not one
          // of them — it changes the draft and leaves the modal standing, and on a phone the
          // actions are a stack of full-width buttons, where it would read as a third way out.
          if (widget.defaultColor case final fallback?)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MochiButton(
                size: MochiSize.sm,
                appearance: MochiButtonAppearance.text,
                intent: MochiIntent.neutral,
                // Nothing to go back to once you are there.
                enabled: fallback.toARGB32() != color.toARGB32(),
                onPress: () => widget.draft.value = fallback,
                child: Text(widget.defaultLabel),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Not a [MochiModalAction]: its value is fixed when it is built, and a draft is exactly the
/// thing that isn't.
class _ColorConfirm extends StatelessWidget {
  const _ColorConfirm({required this.draft, required this.label});

  final ValueNotifier<Color> draft;
  final String label;

  @override
  Widget build(BuildContext context) =>
      MochiButton(onPress: () => Navigator.of(context).pop(draft.value), child: Text(label));
}
