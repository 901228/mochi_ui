import "dart:ui" show lerpDouble;

import "package:flutter/widgets.dart";

import "../theme/size.dart";
import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";
import "clip.dart";
import "overlap.dart";
import "value_transition.dart";

/// Whether an avatar is a circle or a rounded square.
enum MochiAvatarShape {
  /// A person.
  circle,

  /// A thing: a session, a puzzle, a file.
  rounded,
}

/// The little picture that stands for someone or something: a photo, their initials, or an icon
/// when there is neither.
///
/// It falls back on its own: an [image] that fails to load leaves the [initials], and no initials
/// leave the [icon]. The tint comes from [intent], so a wall of them can be told apart without
/// pictures.
///
/// ```dart
/// MochiAvatar(initials: "HS", image: NetworkImage(url))
/// ```
class MochiAvatar extends StatefulWidget {
  const MochiAvatar({
    super.key,
    this.image,
    this.initials,
    this.icon,
    this.size = MochiSize.md,
    this.diameter,
    this.shape = MochiAvatarShape.circle,
    this.intent = MochiIntent.neutral,
    this.semanticLabel,
  });

  /// The picture. Falls back to [initials] if it fails to load.
  final ImageProvider? image;

  /// One or two letters, usually. Longer text is cut down to the first two.
  final String? initials;

  /// Shown when there is no picture and no initials. Defaults to `icons.user`.
  final Widget? icon;

  /// 24 / 32 / 40 / 56 across on the desktop scale, four more on touch.
  final MochiSize size;

  /// Overrides the size entirely.
  final double? diameter;

  final MochiAvatarShape shape;

  /// Colours the fallback: the tinted ground its initials or icon sit on.
  final MochiIntent intent;

  /// What a screen reader says. Defaults to the initials.
  final String? semanticLabel;

  @override
  State<MochiAvatar> createState() => _MochiAvatarState();
}

class _MochiAvatarState extends State<MochiAvatar> {
  /// Set once the image has said it cannot be shown, so the fallback isn't waiting behind a
  /// picture that is never coming.
  bool _failed = false;

  @override
  void didUpdateWidget(MochiAvatar old) {
    super.didUpdateWidget(old);

    if (widget.image != old.image) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final target = widget.diameter ?? _diameterOf(widget.size, touch: theme.touch);

    return MochiValueTransition(
      value: target,
      lerp: (a, b, t) => lerpDouble(a, b, t)!,
      duration: theme.motion.sizeDuration,
      curve: theme.motion.sizeCurve,
      builder: (context, diameter, _) => _build(context, theme, diameter),
    );
  }

  Widget _build(BuildContext context, MochiTheme theme, double diameter) {
    final colors = theme.colors;
    final g = theme.geometry;
    final tone = colors.of(widget.intent);
    final initials = _initials;
    final image = widget.image;

    final radius = switch (widget.shape) {
      MochiAvatarShape.circle => g.radius.full,
      // A quarter of the box, so the corner keeps its shape at every size.
      MochiAvatarShape.rounded => BorderRadius.all(Radius.circular(diameter / 4)),
    };

    Widget fallback() {
      if (initials != null) {
        return Center(
          child: Text(
            initials,
            style: theme.typography.title
                .scale(diameter / 40)
                .lg
                .withWeight(FontWeight.w600)
                .copyWith(color: tone.onSoft),
          ),
        );
      }

      return Center(
        child: IconTheme.merge(
          data: IconThemeData(color: tone.onSoft, size: diameter * 0.55),
          child: widget.icon ?? Icon(theme.icons.user),
        ),
      );
    }

    return Semantics(
      label: widget.semanticLabel ?? initials,
      image: image != null,
      // The initials are the label already; without this a screen reader reads them twice.
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: diameter,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.softOn(tone, colors.surface),
            shape: g.shape(borderRadius: radius),
          ),
          child: MochiClip(
            borderRadius: radius,
            child: image == null || _failed
                ? fallback()
                : Image(
                    image: image,
                    fit: BoxFit.cover,
                    width: diameter,
                    height: diameter,
                    // The fallback is what shows while the picture is on its way, rather than a
                    // hole where it will be.
                    frameBuilder: (context, child, frame, wasSynchronous) =>
                        frame == null ? fallback() : child,
                    errorBuilder: (context, error, stack) {
                      // Nothing is coming: stop asking for it on every rebuild.
                      if (!_failed) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _failed = true);
                        });
                      }
                      return fallback();
                    },
                  ),
          ),
        ),
      ),
    );
  }

  /// At most two letters: more than that is unreadable in a circle this size.
  String? get _initials {
    final initials = widget.initials?.trim();
    if (initials == null || initials.isEmpty) return null;

    final letters = initials.split(RegExp(r"\s+"));
    final taken = letters.length > 1
        ? "${letters.first.characters.first}${letters.last.characters.first}"
        : initials.characters.take(2).toString();

    return taken.toUpperCase();
  }
}

/// 24 / 32 / 40 / 56 on the desktop scale.
double _diameterOf(MochiSize size, {required bool touch}) {
  final extra = touch ? 4.0 : 0.0;

  return switch (size) {
    MochiSize.xs => 24 + extra,
    MochiSize.sm => 32 + extra,
    MochiSize.md => 40 + extra,
    MochiSize.lg => 56 + extra,
  };
}

/// A row of avatars that overlap, with a +n at the end for the ones left out: who is in a
/// session, who reacted.
class MochiAvatarGroup extends StatelessWidget {
  const MochiAvatarGroup({
    super.key,
    required this.children,
    this.max,
    this.size = MochiSize.md,
    this.shape = MochiAvatarShape.circle,
    this.overlap = 0.3,
  });

  /// Usually [MochiAvatar]s of the same size as the group's.
  final List<Widget> children;

  /// How many to show before the rest become a +n. Null shows them all.
  final int? max;

  final MochiSize size;
  final MochiAvatarShape shape;

  /// How much of each avatar the next one covers, 0 to 1.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final diameter = _diameterOf(size, touch: theme.touch);
    final max = this.max;
    final shown = max != null && children.length > max ? children.take(max).toList() : children;
    final hidden = children.length - shown.length;

    Widget ringed(Widget child) => Container(
      padding: EdgeInsets.all(theme.geometry.borderWidth * 2),
      decoration: ShapeDecoration(
        color: theme.colors.surface,
        shape: theme.geometry.shape(
          borderRadius: shape == MochiAvatarShape.circle
              ? theme.geometry.radius.full
              : BorderRadius.all(Radius.circular(diameter / 4)),
        ),
      ),
      child: child,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, child) in shown.indexed)
          // Each one pulled back over the one before it, so the row reads as a stack rather than
          // a list; the ring is the surface behind showing through.
          index == 0 ? ringed(child) : Overlap(by: diameter * overlap, child: ringed(child)),
        if (hidden > 0)
          Overlap(
            by: diameter * overlap,
            child: ringed(MochiAvatar(size: size, shape: shape, initials: "+$hidden")),
          ),
      ],
    );
  }
}
