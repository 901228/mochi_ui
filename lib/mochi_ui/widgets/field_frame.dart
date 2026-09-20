import "package:flutter/widgets.dart";

import "../theme/theme.dart";
import "../theme/tone.dart";
import "../theme/typography.dart";

/// What every input wears around its box: a label above it, and a description, an error or a
/// counter below.
///
/// Shared so a text field, a select and an autocomplete line up in one form, and so anything an
/// app builds out of Mochi's parts can wear the same thing.
class MochiFieldFrame extends StatelessWidget {
  const MochiFieldFrame({
    super.key,
    required this.child,
    this.label,
    this.description,
    this.error,
    this.counter,
    this.enabled = true,
  });

  /// The box itself.
  final Widget child;

  /// Above the box.
  final Widget? label;

  /// Below the box, in muted text. Replaced by [error] when there is one.
  final Widget? description;

  /// Below the box, in the danger tone.
  final String? error;

  /// Below the box at its far end, such as a text field's character count.
  final Widget? counter;

  /// Fades the whole thing, box included.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final small = theme.typography.body.xs;
    final error = this.error;
    final description = this.description;
    final below = error != null || description != null || counter != null;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      // A field fills the width it is given, but one with a width of its own (a row of code
      // boxes, a select in a row) has none to fill: stretching there would hand its children a
      // tight infinite width.
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: constraints.hasBoundedWidth
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          spacing: theme.geometry.space.xs2,
          children: [
            if (label case final label?)
              DefaultTextStyle.merge(
                style: theme.typography.body.sm
                    .withWeight(FontWeight.w600)
                    .copyWith(color: colors.foreground),
                child: label,
              ),
            child,
            if (below)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.geometry.space.xs,
                children: [
                  Expanded(
                    child: error != null
                        ? Text(error, style: small.copyWith(color: colors.of(MochiIntent.danger).onSoft))
                        : DefaultTextStyle.merge(
                            style: small.copyWith(color: colors.mutedForeground),
                            child: description ?? const SizedBox.shrink(),
                          ),
                  ),
                  if (counter case final counter?)
                    DefaultTextStyle.merge(
                      style: small.copyWith(color: colors.mutedForeground),
                      child: counter,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
