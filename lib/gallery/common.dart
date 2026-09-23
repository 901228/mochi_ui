part of "../main.dart";

enum _Column {
  normal({}),
  hovered({WidgetState.hovered}),
  pressed({WidgetState.pressed}),
  focused({WidgetState.focused}),
  selected({WidgetState.selected}),
  selectedHovered({WidgetState.selected, WidgetState.hovered}),
  disabled({}),
  live({});

  const _Column(this.states);
  final Set<WidgetState> states;
}

const _labelWidth = 96.0;

const _cellWidth = 156.0;

enum _TextKind { title, section, muted }

class _ThemedText extends StatelessWidget {
  const _ThemedText(this.data, this.kind);

  final String data;
  final _TextKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      data,
      style: switch (kind) {
        .title => theme.typography.title.xl2,
        .section => theme.typography.title.md,
        .muted => theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
      },
    );
  }
}

/// A button frozen in the given states, ignoring real pointer and focus input.
class _StaticButton extends StatefulWidget {
  const _StaticButton({required this.intent, required this.appearance, required this.states});

  final MochiIntent intent;
  final MochiButtonAppearance appearance;
  final Set<WidgetState> states;

  @override
  State<_StaticButton> createState() => _StaticButtonState();
}

class _StaticButtonState extends State<_StaticButton> {
  late final _controller = WidgetStatesController(widget.states);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeFocus(
        child: MochiButton(
          intent: widget.intent,
          appearance: widget.appearance,
          statesController: _controller,
          // MochiTappable owns the selected state, so it must match the frozen states.
          selected: widget.states.contains(WidgetState.selected),
          onPress: () {},
          child: const Text("Button"),
        ),
      ),
    );
  }
}

enum _RadiusPreset {
  sharp,
  subtle,
  standard,
  rounded,
  pill;

  MochiRadius get value => switch (this) {
    .sharp => MochiRadius.sharp,
    .subtle => MochiRadius.subtle,
    .standard => MochiRadius.standard,
    .rounded => MochiRadius.rounded,
    .pill => MochiRadius.pill,
  };
}

@immutable
/// The three app-wide appearance knobs: corners, density and text size.
@immutable
class _Look {
  const _Look({this.radius = _RadiusPreset.standard, this.density = 1, this.textScale = 1, this.brand});

  final _RadiusPreset radius;
  final double density;
  final double textScale;

  /// Null keeps the kit's own primary; anything else goes through `MochiColors.branded`.
  final Color? brand;

  _Look copyWith({
    _RadiusPreset? radius,
    double? density,
    double? textScale,
    Color? brand,
    bool clearBrand = false,
  }) => _Look(
    radius: radius ?? this.radius,
    density: density ?? this.density,
    textScale: textScale ?? this.textScale,
    brand: clearBrand ? null : brand ?? this.brand,
  );
}

const _brands = [
  ("violet", Color(0xFF7C3AED)),
  ("green", Color(0xFF16A34A)),
  ("amber", Color(0xFFF59E0B)),
  ("slate", Color(0xFF64748B)),
];

class _LookBar extends StatelessWidget {
  const _LookBar({required this.look, required this.onChanged});

  final _Look look;
  final ValueChanged<_Look> onChanged;

  Widget _choice(String label, bool selected, VoidCallback onPress) => MochiButton(
    intent: MochiIntent.neutral,
    appearance: MochiButtonAppearance.ghost,
    size: MochiSize.xs,
    selected: selected,
    onPress: onPress,
    child: Text(label),
  );

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const _ThemedText("radius", .muted),
      for (final preset in _RadiusPreset.values)
        _choice(preset.name, look.radius == preset, () => onChanged(look.copyWith(radius: preset))),
      const SizedBox(width: 16),
      const _ThemedText("density", .muted),
      for (final (label, value) in [("compact", 0.85), ("default", 1.0), ("spacious", 1.15)])
        _choice(label, look.density == value, () => onChanged(look.copyWith(density: value))),
      const SizedBox(width: 16),
      const _ThemedText("text", .muted),
      for (final (label, value) in [("0.9×", 0.9), ("1×", 1.0), ("1.2×", 1.2)])
        _choice(label, look.textScale == value, () => onChanged(look.copyWith(textScale: value))),
      const SizedBox(width: 16),
      // One colour in, four out: MochiColors.branded works the rest of a tone out and keeps the
      // neutrals the kit was tuned with.
      const _ThemedText("brand", .muted),
      _choice("mochi", look.brand == null, () => onChanged(look.copyWith(clearBrand: true))),
      for (final (label, value) in _brands)
        _choice(label, look.brand == value, () => onChanged(look.copyWith(brand: value))),
    ],
  );
}

/// Shows its child's live height, so a transition can be read off the number as well as seen.
class _Measured extends StatefulWidget {
  const _Measured({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<_Measured> createState() => _MeasuredState();
}

class _MeasuredState extends State<_Measured> {
  final _height = ValueNotifier<double>(0);

  @override
  void dispose() {
    _height.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: context.theme.geometry.space.xs2,
    children: [
      _MeasureSize(height: _height, child: widget.child),
      ValueListenableBuilder(
        valueListenable: _height,
        builder: (context, height, _) =>
            _ThemedText("${widget.label} · ${height.toStringAsFixed(1)}", .muted),
      ),
    ],
  );
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.height, required super.child});

  final ValueNotifier<double> height;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureSize(height);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureSize renderObject) =>
      renderObject.height = height;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.height);

  ValueNotifier<double> height;

  @override
  void performLayout() {
    super.performLayout();

    // Notifying during layout would rebuild the listener in the same frame it is laid out in.
    if (height.value != size.height) {
      final measured = size.height;
      SchedulerBinding.instance.addPostFrameCallback((_) => height.value = measured);
    }
  }
}

/// A sample too wide for the page, scrolled across instead of squeezed. Scroll views clip, so it
/// reserves room for the focus rings inside it.
class _Wide extends StatelessWidget {
  const _Wide({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.all(MochiFocusRing.outsetOf(context)),
    child: child,
  );
}
