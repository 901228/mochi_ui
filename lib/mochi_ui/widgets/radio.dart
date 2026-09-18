import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/colors.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "focus_ring.dart";
import "state_transition.dart";
import "value_transition.dart";

/// How the options of a [MochiRadioGroup] look.
///
/// An appearance rather than a separate "radio card" component: the behaviour — one choice,
/// arrow keys moving it, one tab stop for the group — is the same either way.
enum MochiRadioAppearance {
  /// A dot beside its label, like a form.
  plain,

  /// Each option a bordered card holding its label, description and an optional icon, the
  /// whole card the target. For a few options that each need a line of explanation.
  card,
}

/// One choice out of several [MochiRadio]s.
///
/// Built on the widgets layer's [RadioGroup] and [RawRadio], so the arrow keys move the choice,
/// Tab stops once on the group rather than on every option, and screen readers hear a set of
/// mutually exclusive options; this adds the layout and the look.
///
/// ```dart
/// MochiRadioGroup<Alert>(
///   value: alert,
///   onChanged: (value) => setState(() => alert = value!),
///   children: const [
///     MochiRadio(value: Alert.beep, label: Text("Beep")),
///     MochiRadio(value: Alert.voice, label: Text("Voice")),
///   ],
/// )
/// ```
class MochiRadioGroup<T> extends StatelessWidget {
  const MochiRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.appearance = MochiRadioAppearance.plain,
    this.axis = Axis.vertical,
    this.intent = MochiIntent.primary,
  });

  /// The chosen option's value, or null when none is.
  final T? value;

  /// Null disables the whole group.
  final ValueChanged<T?>? onChanged;

  /// Usually [MochiRadio]s.
  final List<Widget> children;

  final MochiRadioAppearance appearance;

  /// Which way the options run. Cards laid out in a row share its width equally.
  final Axis axis;

  final MochiIntent intent;

  @override
  Widget build(BuildContext context) {
    final g = context.theme.geometry;
    final cards = appearance == MochiRadioAppearance.card;
    final spacing = cards ? g.space.xs : (axis == Axis.vertical ? g.space.xs : g.space.lg);
    final onChanged = this.onChanged;

    return RadioGroup<T>(
      groupValue: value,
      onChanged: onChanged ?? (_) {},
      child: _RadioScope(
        appearance: appearance,
        intent: intent,
        enabled: onChanged != null,
        child: Flex(
          direction: axis,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: axis == Axis.vertical ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
          spacing: spacing,
          children: [
            for (final child in children)
              if (cards && axis == Axis.horizontal) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

class _RadioScope extends InheritedWidget {
  const _RadioScope({
    required this.appearance,
    required this.intent,
    required this.enabled,
    required super.child,
  });

  final MochiRadioAppearance appearance;
  final MochiIntent intent;
  final bool enabled;

  static _RadioScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_RadioScope>();

  @override
  bool updateShouldNotify(_RadioScope old) =>
      old.appearance != appearance || old.intent != intent || old.enabled != enabled;
}

/// An option in a [MochiRadioGroup].
class MochiRadio<T> extends StatefulWidget {
  const MochiRadio({
    super.key,
    required this.value,
    this.label,
    this.description,
    this.icon,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// What the group's `onChanged` is called with when this is chosen.
  final T value;

  final Widget? label;

  /// Under the label, in muted text.
  final Widget? description;

  /// Leads a card; a plain option has its dot there instead, and ignores this.
  final Widget? icon;

  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<MochiRadio<T>> createState() => _MochiRadioState<T>();
}

class _MochiRadioState<T> extends State<MochiRadio<T>> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownFocusNode?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _RadioScope.of(context);
    final registry = RadioGroup.maybeOf<T>(context);
    assert(registry != null, "A MochiRadio goes inside a MochiRadioGroup of the same type.");
    final enabled = widget.enabled && (scope?.enabled ?? true) && registry != null;

    return RawRadio<T>(
      value: widget.value,
      groupRegistry: registry,
      enabled: enabled,
      toggleable: false,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? SystemMouseCursors.basic : SystemMouseCursors.click,
      ),
      builder: (context, state) => _RadioSurface(
        states: state.states,
        appearance: scope?.appearance ?? MochiRadioAppearance.plain,
        intent: scope?.intent ?? MochiIntent.primary,
        label: widget.label,
        description: widget.description,
        icon: widget.icon,
      ),
    );
  }
}

class _RadioSurface extends StatelessWidget {
  const _RadioSurface({
    required this.states,
    required this.appearance,
    required this.intent,
    required this.label,
    required this.description,
    required this.icon,
  });

  final Set<WidgetState> states;
  final MochiRadioAppearance appearance;
  final MochiIntent intent;
  final Widget? label;
  final Widget? description;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // The dot's size comes from the theme, so switching scales would otherwise jump.
    return MochiValueTransition(
      value: theme.touch ? 20.0 : 16.0,
      lerp: (a, b, t) => lerpDouble(a, b, t)!,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, size, _) => MochiStateTransition(
        states: states,
        duration: theme.motion.stateDuration,
        builder: (context, blend) => Opacity(
          opacity: blend.number((st) => st.contains(WidgetState.disabled) ? 0.4 : 1),
          child: switch (appearance) {
            MochiRadioAppearance.plain => _plain(theme, blend, size),
            MochiRadioAppearance.card => _card(theme, blend, size),
          },
        ),
      ),
    );
  }

  Widget _dot(MochiTheme theme, MochiStateBlend blend, double size, {required bool ring}) {
    final colors = theme.colors;
    final tone = colors.of(intent);
    final full = theme.geometry.radius.full;
    final selected = blend.number((st) => st.contains(WidgetState.selected) ? 1 : 0);

    final dot = Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: blend.color(
          (st) => st.contains(WidgetState.selected)
              ? tone.base
              : MochiColors.stateLayer(colors.surface, colors.foreground, st),
        ),
        shape: RoundedSuperellipseBorder(
          borderRadius: full,
          side: BorderSide(
            width: theme.geometry.borderWidth,
            color: blend.color(
              (st) => switch (st) {
                _ when st.contains(WidgetState.selected) => tone.base.withValues(alpha: 0),
                _ when st.contains(WidgetState.hovered) => Color.lerp(
                  colors.border,
                  colors.mutedForeground,
                  0.5,
                )!,
                _ => colors.border,
              },
            ),
          ),
        ),
      ),
      // The centre grows out as the fill arrives.
      child: Center(
        child: SizedBox.square(
          dimension: size * 0.4 * selected,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: tone.onBase,
              shape: RoundedSuperellipseBorder(borderRadius: full),
            ),
          ),
        ),
      ),
    );

    return ring
        ? MochiFocusRing(visible: blend.contains(WidgetState.focused), radius: full, child: dot)
        : dot;
  }

  Widget? _text(MochiTheme theme, {required bool strong}) {
    final colors = theme.colors;
    final label = this.label;
    final description = this.description;
    if (label == null && description == null) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.geometry.space.xs3,
      children: [
        if (label != null)
          DefaultTextStyle.merge(
            style: (strong ? theme.typography.body.sm.withWeight(FontWeight.w600) : theme.typography.body.sm)
                .copyWith(color: colors.foreground),
            child: label,
          ),
        if (description != null)
          DefaultTextStyle.merge(
            style: theme.typography.body.xs.copyWith(color: colors.mutedForeground),
            child: description,
          ),
      ],
    );
  }

  Widget _plain(MochiTheme theme, MochiStateBlend blend, double size) {
    final dot = _dot(theme, blend, size, ring: true);
    final text = _text(theme, strong: false);
    if (text == null) return dot;

    final line = theme.typography.body.sm;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.geometry.space.xs,
      children: [
        // Centred on the label's first line rather than on the whole block.
        SizedBox(
          height: (line.fontSize ?? 14) * (line.height ?? 1.4),
          child: Center(child: dot),
        ),
        Flexible(child: text),
      ],
    );
  }

  Widget _card(MochiTheme theme, MochiStateBlend blend, double size) {
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(intent);
    // A chosen card is tinted, and mixed over the surface it sits on rather than the page.
    final chosen = colors.softOn(tone, colors.surface);

    return MochiFocusRing(
      visible: blend.contains(WidgetState.focused),
      radius: g.radius.md,
      child: Container(
        padding: EdgeInsets.all(g.space.sm),
        decoration: ShapeDecoration(
          color: blend.color(
            (st) => MochiColors.stateLayer(
              st.contains(WidgetState.selected) ? chosen : colors.surface,
              colors.foreground,
              st,
            ),
          ),
          shape: RoundedSuperellipseBorder(
            borderRadius: g.radius.md,
            side: BorderSide(
              width: g.borderWidth,
              color: blend.color(
                (st) => switch (st) {
                  _ when st.contains(WidgetState.selected) => tone.base,
                  _ when st.contains(WidgetState.hovered) => Color.lerp(
                    colors.border,
                    colors.mutedForeground,
                    0.5,
                  )!,
                  _ => colors.border,
                },
              ),
            ),
          ),
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            color: blend.color(
              (st) => st.contains(WidgetState.selected) ? tone.onSoft : colors.mutedForeground,
            ),
            size: 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: g.space.sm,
            children: [
              ?icon,
              Expanded(child: _text(theme, strong: true) ?? const SizedBox.shrink()),
              _dot(theme, blend, size, ring: false),
            ],
          ),
        ),
      ),
    );
  }
}
